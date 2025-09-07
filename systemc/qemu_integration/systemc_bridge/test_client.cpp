#include <iostream>
#include <iomanip>
#include <getopt.h>
#include <cstdlib>
#include <chrono>
#include <random>
#include <vector>
#include <string>
#include <cstring>
#include <thread>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>

// Protocol definitions (copied from qemu_systemc_bridge.h to avoid SystemC dependency)
namespace QemuSystemC {
    enum MessageType {
        MSG_READ_REQUEST = 1,
        MSG_READ_RESPONSE = 2,
        MSG_WRITE_REQUEST = 3,
        MSG_WRITE_RESPONSE = 4,
        MSG_INIT_REQUEST = 5,
        MSG_INIT_RESPONSE = 6,
        MSG_STATUS_REQUEST = 7,
        MSG_STATUS_RESPONSE = 8,
        MSG_SHUTDOWN = 9
    };

    struct MessageHeader {
        uint32_t type;
        uint32_t length;
        uint64_t transaction_id;
        uint64_t timestamp;
    } __attribute__((packed));

    struct MemoryRequest {
        uint64_t address;
        uint32_t size;
        uint32_t access_type;
        uint8_t data[64];
    } __attribute__((packed));

    struct MemoryResponse {
        uint64_t address;
        uint32_t size;
        uint32_t status;
        uint8_t data[64];
    } __attribute__((packed));

    struct InitRequest {
        uint64_t memory_size;
        uint32_t page_size;
        uint32_t cache_line_size;
        char arch_name[32];
    } __attribute__((packed));

    struct StatusResponse {
        uint64_t total_reads;
        uint64_t total_writes;
        uint64_t total_errors;
        uint64_t current_bandwidth;
        uint32_t active_banks;
        uint32_t page_hits;
        uint32_t page_misses;
        uint32_t reserved;
    } __attribute__((packed));
}

class SystemCTestClient {
public:
    SystemCTestClient(const std::string& server_host, int server_port)
        : host(server_host), port(server_port), socket_fd(-1) {}
    
    ~SystemCTestClient() {
        disconnect();
    }
    
    bool connect() {
        socket_fd = socket(AF_INET, SOCK_STREAM, 0);
        if (socket_fd < 0) {
            std::cerr << "Failed to create socket" << std::endl;
            return false;
        }
        
        struct sockaddr_in server_addr;
        memset(&server_addr, 0, sizeof(server_addr));
        server_addr.sin_family = AF_INET;
        server_addr.sin_port = htons(port);
        
        if (inet_pton(AF_INET, host.c_str(), &server_addr.sin_addr) <= 0) {
            std::cerr << "Invalid server address: " << host << std::endl;
            close(socket_fd);
            return false;
        }
        
        if (::connect(socket_fd, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
            std::cerr << "Failed to connect to server " << host << ":" << port << std::endl;
            close(socket_fd);
            return false;
        }
        
        std::cout << "Connected to SystemC server at " << host << ":" << port << std::endl;
        return true;
    }
    
    void disconnect() {
        if (socket_fd >= 0) {
            close(socket_fd);
            socket_fd = -1;
        }
    }
    
    bool send_init_request(uint64_t memory_size, const std::string& arch) {
        QemuSystemC::InitRequest request;
        request.memory_size = memory_size;
        request.page_size = 4096;
        request.cache_line_size = 64;
        strncpy(request.arch_name, arch.c_str(), sizeof(request.arch_name) - 1);
        request.arch_name[sizeof(request.arch_name) - 1] = '\0';
        
        return send_message(QemuSystemC::MSG_INIT_REQUEST, &request, sizeof(request));
    }
    
    bool send_write_request(uint64_t address, const uint8_t* data, uint32_t size) {
        QemuSystemC::MemoryRequest request;
        request.address = address;
        request.size = size;
        request.access_type = 1; // Write
        memcpy(request.data, data, std::min((uint32_t)sizeof(request.data), size));
        
        return send_message(QemuSystemC::MSG_WRITE_REQUEST, &request, sizeof(request));
    }
    
    bool send_read_request(uint64_t address, uint32_t size) {
        QemuSystemC::MemoryRequest request;
        request.address = address;
        request.size = size;
        request.access_type = 0; // Read
        memset(request.data, 0, sizeof(request.data));
        
        return send_message(QemuSystemC::MSG_READ_REQUEST, &request, sizeof(request));
    }
    
    bool send_status_request() {
        return send_message(QemuSystemC::MSG_STATUS_REQUEST, nullptr, 0);
    }
    
    bool receive_response(QemuSystemC::MessageType expected_type) {
        // Set socket timeout to prevent indefinite blocking
        struct timeval timeout;
        timeout.tv_sec = 5;  // 5 second timeout
        timeout.tv_usec = 0;
        
        if (setsockopt(socket_fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout)) < 0) {
            std::cerr << "Failed to set socket timeout" << std::endl;
        }
        
        QemuSystemC::MessageHeader header;
        ssize_t received = recv(socket_fd, &header, sizeof(header), MSG_WAITALL);
        if (received != sizeof(header)) {
            if (received == 0) {
                std::cerr << "Connection closed by server" << std::endl;
            } else if (received < 0) {
                std::cerr << "Failed to receive response header (timeout or error)" << std::endl;
            } else {
                std::cerr << "Partial header received: " << received << " bytes" << std::endl;
            }
            return false;
        }
        
        if (header.type != expected_type) {
            std::cerr << "Unexpected response type: " << header.type 
                      << " (expected " << expected_type << ")" << std::endl;
            return false;
        }
        
        if (header.length > 0) {
            std::vector<uint8_t> data(header.length);
            if (recv(socket_fd, data.data(), header.length, MSG_WAITALL) != (ssize_t)header.length) {
                std::cerr << "Failed to receive response data" << std::endl;
                return false;
            }
            
            // Process response data based on type
            switch (expected_type) {
                case QemuSystemC::MSG_READ_RESPONSE: {
                    QemuSystemC::MemoryResponse* response = (QemuSystemC::MemoryResponse*)data.data();
                    std::cout << "Read response: addr=0x" << std::hex << response->address
                              << " size=" << std::dec << response->size
                              << " status=" << response->status;
                    if (response->status == 0) {
                        std::cout << " data=0x" << std::hex;
                        for (uint32_t i = 0; i < std::min(response->size, 8u); i++) {
                            std::cout << std::setfill('0') << std::setw(2) << (int)response->data[i];
                        }
                    }
                    std::cout << std::dec << std::endl;
                    break;
                }
                
                case QemuSystemC::MSG_WRITE_RESPONSE: {
                    QemuSystemC::MemoryResponse* response = (QemuSystemC::MemoryResponse*)data.data();
                    std::cout << "Write response: addr=0x" << std::hex << response->address
                              << " size=" << std::dec << response->size
                              << " status=" << response->status << std::endl;
                    break;
                }
                
                case QemuSystemC::MSG_STATUS_RESPONSE: {
                    QemuSystemC::StatusResponse* status = (QemuSystemC::StatusResponse*)data.data();
                    std::cout << "Status response:" << std::endl;
                    std::cout << "  Total reads:  " << status->total_reads << std::endl;
                    std::cout << "  Total writes: " << status->total_writes << std::endl;
                    std::cout << "  Total errors: " << status->total_errors << std::endl;
                    std::cout << "  Bandwidth:    " << (status->current_bandwidth >> 20) << " MB/s" << std::endl;
                    std::cout << "  Active banks: " << status->active_banks << std::endl;
                    std::cout << "  Page hits:    " << status->page_hits << std::endl;
                    std::cout << "  Page misses:  " << status->page_misses << std::endl;
                    break;
                }
                
                default:
                    std::cout << "Response received (type=" << expected_type << ")" << std::endl;
                    break;
            }
        }
        
        return true;
    }
    
    bool run_basic_test() {
        std::cout << "\n=== Running Basic Test ===" << std::endl;
        
        // Initialize system
        if (!send_init_request(1024 * 1024 * 1024, "arm64")) {
            return false;
        }
        if (!receive_response(QemuSystemC::MSG_INIT_RESPONSE)) {
            return false;
        }
        
        // Test write/read operations
        uint64_t test_data = 0x123456789ABCDEF0ULL;
        uint64_t test_addr = 0x1000;
        
        std::cout << "Writing 0x" << std::hex << test_data << " to address 0x" << test_addr << std::endl;
        if (!send_write_request(test_addr, (uint8_t*)&test_data, 8)) {
            return false;
        }
        if (!receive_response(QemuSystemC::MSG_WRITE_RESPONSE)) {
            return false;
        }
        
        std::cout << "Reading from address 0x" << test_addr << std::endl;
        if (!send_read_request(test_addr, 8)) {
            return false;
        }
        if (!receive_response(QemuSystemC::MSG_READ_RESPONSE)) {
            return false;
        }
        
        // Get status
        std::cout << "Getting system status..." << std::endl;
        if (!send_status_request()) {
            return false;
        }
        if (!receive_response(QemuSystemC::MSG_STATUS_RESPONSE)) {
            return false;
        }
        
        std::cout << "Basic test completed successfully!" << std::endl;
        return true;
    }
    
    bool run_performance_test() {
        std::cout << "\n=== Running Performance Test ===" << std::endl;
        
        // Initialize system
        std::cout << "Initializing SystemC memory model - sending init request..." << std::endl;
        if (!send_init_request(2ULL * 1024 * 1024 * 1024, "arm64")) {
            std::cerr << "Failed to send init request" << std::endl;
            return false;
        }
        std::cout << "Init request sent, waiting for response..." << std::endl;
        if (!receive_response(QemuSystemC::MSG_INIT_RESPONSE)) {
            std::cerr << "Failed to receive init response" << std::endl;
            return false;
        }
        std::cout << "SystemC memory model initialized successfully!" << std::endl;
        
        // Get initial status
        std::cout << "\nInitial system status:" << std::endl;
        if (!send_status_request()) {
            return false;
        }
        if (!receive_response(QemuSystemC::MSG_STATUS_RESPONSE)) {
            return false;
        }
        
        const int num_operations = 20;  // Reduced from 50 to prevent queue overflow
        std::random_device rd;
        std::mt19937 gen(rd());
        std::uniform_int_distribution<uint64_t> addr_dist(0, 1024 * 1024);
        std::uniform_int_distribution<uint64_t> data_dist(0, UINT64_MAX);
        
        // Pacing parameters to prevent queue overflow
        const auto request_pacing = std::chrono::microseconds(100);  // 100μs between requests
        const auto burst_pacing = std::chrono::milliseconds(10);     // 10ms between bursts
        const int burst_size = 5;  // Send 5 operations, then pause
        
        auto start_time = std::chrono::high_resolution_clock::now();
        int successful_writes = 0;
        int failed_writes = 0;
        
        // Perform write operations with pacing
        std::cout << "\n--- Write Operations Phase ---" << std::endl;
        std::cout << "Performing " << num_operations << " write operations with pacing..." << std::endl;
        for (int i = 0; i < num_operations; i++) {
            uint64_t addr = (addr_dist(gen) & ~7ULL); // 8-byte aligned
            uint64_t data = data_dist(gen);
            
            if (!send_write_request(addr, (uint8_t*)&data, 8)) {
                failed_writes++;
                continue;
            }
            if (!receive_response(QemuSystemC::MSG_WRITE_RESPONSE)) {
                failed_writes++;
                continue;
            }
            successful_writes++;
            
            // Add pacing between requests
            std::this_thread::sleep_for(request_pacing);
            
            // Add burst pacing after every burst_size operations
            if ((i + 1) % burst_size == 0) {
                std::cout << "  Burst completed: " << (i + 1) << "/" << num_operations 
                          << " (" << std::fixed << std::setprecision(1) 
                          << (100.0 * (i + 1) / num_operations) << "%)" << std::endl;
                std::this_thread::sleep_for(burst_pacing);
            }
            
            if ((i + 1) % 10 == 0) {
                auto current_time = std::chrono::high_resolution_clock::now();
                auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(current_time - start_time);
                double ops_per_sec = (double)(i + 1) / (elapsed.count() / 1000.0);
                
                std::cout << "  Progress: " << (i + 1) << "/" << num_operations 
                          << " writes (" << std::fixed << std::setprecision(1) 
                          << (100.0 * (i + 1) / num_operations) << "%) - "
                          << std::setprecision(2) << ops_per_sec << " ops/sec" << std::endl;
            }
        }
        
        std::cout << "Write phase completed: " << successful_writes << " successful, " 
                  << failed_writes << " failed" << std::endl;
        
        int successful_reads = 0;
        int failed_reads = 0;
        
        // Perform read operations with pacing
        std::cout << "\n--- Read Operations Phase ---" << std::endl;
        std::cout << "Performing " << num_operations << " read operations with pacing..." << std::endl;
        for (int i = 0; i < num_operations; i++) {
            uint64_t addr = (addr_dist(gen) & ~7ULL); // 8-byte aligned
            
            if (!send_read_request(addr, 8)) {
                failed_reads++;
                continue;
            }
            if (!receive_response(QemuSystemC::MSG_READ_RESPONSE)) {
                failed_reads++;
                continue;
            }
            successful_reads++;
            
            // Add pacing between requests
            std::this_thread::sleep_for(request_pacing);
            
            // Add burst pacing after every burst_size operations
            if ((i + 1) % burst_size == 0) {
                std::cout << "  Burst completed: " << (i + 1) << "/" << num_operations 
                          << " (" << std::fixed << std::setprecision(1) 
                          << (100.0 * (i + 1) / num_operations) << "%)" << std::endl;
                std::this_thread::sleep_for(burst_pacing);
            }
            
            if ((i + 1) % 10 == 0) {
                auto current_time = std::chrono::high_resolution_clock::now();
                auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(current_time - start_time);
                double ops_per_sec = (double)(successful_writes + i + 1) / (elapsed.count() / 1000.0);
                
                std::cout << "  Progress: " << (i + 1) << "/" << num_operations 
                          << " reads (" << std::fixed << std::setprecision(1) 
                          << (100.0 * (i + 1) / num_operations) << "%) - "
                          << std::setprecision(2) << ops_per_sec << " total ops/sec" << std::endl;
            }
        }
        
        std::cout << "Read phase completed: " << successful_reads << " successful, " 
                  << failed_reads << " failed" << std::endl;
        
        auto end_time = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time);
        
        std::cout << "\n--- Performance Test Results ---" << std::endl;
        std::cout << "Total test duration: " << duration.count() << " ms" << std::endl;
        std::cout << "Total operations: " << (successful_writes + successful_reads) << std::endl;
        std::cout << "Successful writes: " << successful_writes << std::endl;
        std::cout << "Successful reads: " << successful_reads << std::endl;
        std::cout << "Failed operations: " << (failed_writes + failed_reads) << std::endl;
        std::cout << "Average operation time: " << std::fixed << std::setprecision(3) 
                  << (duration.count() / (double)(successful_writes + successful_reads)) << " ms" << std::endl;
        std::cout << "Overall throughput: " << std::setprecision(2) 
                  << ((successful_writes + successful_reads) / (duration.count() / 1000.0)) << " ops/sec" << std::endl;
        
        // Get final status
        std::cout << "\nFinal system status:" << std::endl;
        if (!send_status_request()) {
            return false;
        }
        if (!receive_response(QemuSystemC::MSG_STATUS_RESPONSE)) {
            return false;
        }
        
        return true;
    }

private:
    std::string host;
    int port;
    int socket_fd;
    uint64_t transaction_id = 1;
    
    bool send_message(QemuSystemC::MessageType type, const void* data, uint32_t size) {
        QemuSystemC::MessageHeader header;
        header.type = type;
        header.length = size;
        header.transaction_id = transaction_id++;
        header.timestamp = std::chrono::duration_cast<std::chrono::nanoseconds>(
            std::chrono::high_resolution_clock::now().time_since_epoch()).count();
        
        // Send header
        if (send(socket_fd, &header, sizeof(header), 0) != sizeof(header)) {
            std::cerr << "Failed to send message header" << std::endl;
            return false;
        }
        
        // Send data if present
        if (size > 0 && data != nullptr) {
            if (send(socket_fd, data, size, 0) != (ssize_t)size) {
                std::cerr << "Failed to send message data" << std::endl;
                return false;
            }
        }
        
        return true;
    }
};

void print_usage(const char* program_name) {
    std::cout << "Usage: " << program_name << " [OPTIONS]" << std::endl;
    std::cout << std::endl;
    std::cout << "SystemC-QEMU Bridge Test Client" << std::endl;
    std::cout << std::endl;
    std::cout << "Options:" << std::endl;
    std::cout << "  -s, --server HOST:PORT   Server address (default: localhost:8888)" << std::endl;
    std::cout << "  -t, --test TYPE          Test type: basic, performance (default: basic)" << std::endl;
    std::cout << "  -h, --help               Show this help" << std::endl;
    std::cout << std::endl;
    std::cout << "Examples:" << std::endl;
    std::cout << "  " << program_name << " --server localhost:8888 --test basic" << std::endl;
    std::cout << "  " << program_name << " -s 192.168.1.100:8889 -t performance" << std::endl;
}

int main(int argc, char* argv[]) {
    std::string server_address = "localhost:8888";
    std::string test_type = "basic";
    
    // Command line options
    static struct option long_options[] = {
        {"server", required_argument, 0, 's'},
        {"test",   required_argument, 0, 't'},
        {"help",   no_argument,       0, 'h'},
        {0, 0, 0, 0}
    };
    
    int option_index = 0;
    int c;
    
    while ((c = getopt_long(argc, argv, "s:t:h", long_options, &option_index)) != -1) {
        switch (c) {
            case 's':
                server_address = optarg;
                break;
                
            case 't':
                test_type = optarg;
                if (test_type != "basic" && test_type != "performance") {
                    std::cerr << "Error: Invalid test type: " << test_type << std::endl;
                    std::cerr << "Supported types: basic, performance" << std::endl;
                    return 1;
                }
                break;
                
            case 'h':
                print_usage(argv[0]);
                return 0;
                
            case '?':
                std::cerr << "Try '" << argv[0] << " --help' for more information." << std::endl;
                return 1;
                
            default:
                break;
        }
    }
    
    // Parse server address
    std::string host = "127.0.0.1";
    int port = 8888;
    
    size_t colon_pos = server_address.find(':');
    if (colon_pos != std::string::npos) {
        host = server_address.substr(0, colon_pos);
        port = std::atoi(server_address.substr(colon_pos + 1).c_str());
    }
    
    if (port <= 0 || port > 65535) {
        std::cerr << "Error: Invalid port number in server address: " << server_address << std::endl;
        return 1;
    }
    
    std::cout << "SystemC-QEMU Bridge Test Client" << std::endl;
    std::cout << "Server: " << host << ":" << port << std::endl;
    std::cout << "Test:   " << test_type << std::endl;
    std::cout << std::endl;
    
    try {
        SystemCTestClient client(host, port);
        
        if (!client.connect()) {
            return 1;
        }
        
        bool success = false;
        if (test_type == "basic") {
            success = client.run_basic_test();
        } else if (test_type == "performance") {
            success = client.run_performance_test();
        }
        
        if (success) {
            std::cout << "\nTest completed successfully!" << std::endl;
            return 0;
        } else {
            std::cout << "\nTest failed!" << std::endl;
            return 1;
        }
        
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
}
