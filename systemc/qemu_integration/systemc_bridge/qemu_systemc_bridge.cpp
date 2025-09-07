#include "qemu_systemc_bridge.h"
#include <chrono>
#include <iomanip>
#include <signal.h>
#include <algorithm>

// Constructor
QemuSystemCBridge::QemuSystemCBridge(sc_module_name name, int port)
    : sc_module(name)
    , server_port(port)
    , server_socket(-1)
    , server_running(false)
    , shutdown_requested(false)
    , transaction_counter(0)
    , total_reads(0)
    , total_writes(0)
    , total_errors(0)
    , bytes_read(0)
    , bytes_written(0)
    , memory_size(1ULL << 30)  // Default 1GB
    , page_size(4096)
    , cache_line_size(64)
    , architecture("arm64")
    , trace_fp(nullptr)
    , active_transaction_count(0)
{
    // Create clocks for memory model (200MHz main, 25MHz slow)
    model_clock = new sc_clock("model_clock", 5, SC_NS);
    slow_clock = new sc_clock("slow_clock", 40, SC_NS);
    
    // Create memory model instance
    memory_model = new WhitneySystemCModelEnhanced("whitney_memory");
    
    // Connect signals
    connect_memory_model();
    
    // Register SystemC processes (remove server_process from SystemC)
    SC_THREAD(memory_interface_process);
    SC_THREAD(initialization_process);
    
    start_time = std::chrono::high_resolution_clock::now();
    
    std::cout << "QemuSystemCBridge initialized on port " << port << std::endl;
}

// Destructor
QemuSystemCBridge::~QemuSystemCBridge() {
    stop_server();
    close_tracing();
    
    if (memory_model) {
        delete memory_model;
    }
    
    if (model_clock) {
        delete model_clock;
    }
}

void QemuSystemCBridge::connect_memory_model() {
    // Connect clocks and reset
    memory_model->mck(*model_clock);
    memory_model->slow_clk(*slow_clock);
    memory_model->mc_rst_b(model_reset);
    memory_model->porst_b(model_porst);
    
    // Connect AXI interface
    memory_model->mc0_aclk(*model_clock);
    memory_model->mc0_aresetn(model_reset);
    
    // AXI Write Address Channel
    memory_model->mc0_axi_awid(axi_awid);
    memory_model->mc0_axi_awaddr(axi_awaddr);
    memory_model->mc0_axi_awlen(axi_awlen);
    memory_model->mc0_axi_awsize(axi_awsize);
    memory_model->mc0_axi_awburst(axi_awburst);
    memory_model->mc0_axi_awlock(axi_awlock);
    memory_model->mc0_axi_awcache(axi_awcache);
    memory_model->mc0_axi_awprot(axi_awprot);
    memory_model->mc0_axi_awqos(axi_awqos);
    memory_model->mc0_axi_awvalid(axi_awvalid);
    memory_model->mc0_axi_awready(axi_awready);
    
    // AXI Write Data Channel
    memory_model->mc0_axi_wdata(axi_wdata);
    memory_model->mc0_axi_wstrb(axi_wstrb);
    memory_model->mc0_axi_wlast(axi_wlast);
    memory_model->mc0_axi_wvalid(axi_wvalid);
    memory_model->mc0_axi_wready(axi_wready);
    
    // AXI Write Response Channel
    memory_model->mc0_axi_bid(axi_bid);
    memory_model->mc0_axi_bresp(axi_bresp);
    memory_model->mc0_axi_bvalid(axi_bvalid);
    memory_model->mc0_axi_bready(axi_bready);
    
    // AXI Read Address Channel
    memory_model->mc0_axi_arid(axi_arid);
    memory_model->mc0_axi_araddr(axi_araddr);
    memory_model->mc0_axi_arlen(axi_arlen);
    memory_model->mc0_axi_arsize(axi_arsize);
    memory_model->mc0_axi_arburst(axi_arburst);
    memory_model->mc0_axi_arlock(axi_arlock);
    memory_model->mc0_axi_arcache(axi_arcache);
    memory_model->mc0_axi_arprot(axi_arprot);
    memory_model->mc0_axi_arqos(axi_arqos);
    memory_model->mc0_axi_arvalid(axi_arvalid);
    memory_model->mc0_axi_arready(axi_arready);
    
    // AXI Read Data Channel
    memory_model->mc0_axi_rid(axi_rid);
    memory_model->mc0_axi_rdata(axi_rdata);
    memory_model->mc0_axi_rresp(axi_rresp);
    memory_model->mc0_axi_rlast(axi_rlast);
    memory_model->mc0_axi_rvalid(axi_rvalid);
    memory_model->mc0_axi_rready(axi_rready);
    
    // Connect APB interface
    memory_model->mc_penable(mc_penable);
    memory_model->mc_psel(mc_psel);
    memory_model->mc_pwr(mc_pwr);
    memory_model->mc_paddr(mc_paddr);
    memory_model->mc_pwdata(mc_pwdata);
    memory_model->mc_prdata(mc_prdata);
    memory_model->mc_pready(mc_pready);
    memory_model->mc_pslverr(mc_pslverr);
    
    // Connect DFI read data interface (inputs to memory model)
    memory_model->dfi_rddata_valid(dfi_rddata_valid);
    memory_model->dfi_rddata_0(dfi_rddata_0);
    memory_model->dfi_rddata_1(dfi_rddata_1);
    memory_model->dfi_rddata_2(dfi_rddata_2);
    memory_model->dfi_rddata_3(dfi_rddata_3);
    memory_model->dfi_rddata_4(dfi_rddata_4);
    memory_model->dfi_rddata_5(dfi_rddata_5);
    memory_model->dfi_rddata_6(dfi_rddata_6);
    memory_model->dfi_rddata_7(dfi_rddata_7);
    memory_model->dfi_rddata_8(dfi_rddata_8);
    memory_model->dfi_rddata_9(dfi_rddata_9);
    memory_model->dfi_rddata_10(dfi_rddata_10);
    memory_model->dfi_rddata_11(dfi_rddata_11);
    memory_model->dfi_rddata_12(dfi_rddata_12);
    memory_model->dfi_rddata_13(dfi_rddata_13);
    memory_model->dfi_rddata_14(dfi_rddata_14);
    memory_model->dfi_rddata_15(dfi_rddata_15);
    
    // Connect DFI output signals (outputs from memory model)
    memory_model->dfi_dram_clk_disable_0(dfi_dram_clk_disable_0);
    memory_model->dfi_dram_clk_disable_1(dfi_dram_clk_disable_1);
    memory_model->dfi_dram_ca_disable(dfi_dram_ca_disable);
    memory_model->dfi_cs_0_p0(dfi_cs_0_p0);
    memory_model->dfi_cs_0_p1(dfi_cs_0_p1);
    memory_model->dfi_cs_1_p2(dfi_cs_1_p2);
    memory_model->dfi_cs_1_p3(dfi_cs_1_p3);
    memory_model->dfi_address_0_p0(dfi_address_0_p0);
    memory_model->dfi_address_0_p1(dfi_address_0_p1);
    memory_model->dfi_address_1_p2(dfi_address_1_p2);
    memory_model->dfi_address_1_p3(dfi_address_1_p3);
    memory_model->dfi_reset_n(dfi_reset_n);
    memory_model->dfi_wck_cs(dfi_wck_cs);
    memory_model->dfi_wck_en(dfi_wck_en);
    memory_model->dfi_wck_toggle(dfi_wck_toggle);
    
    // Connect DFI write data outputs
    memory_model->dfi_wrdata_0(dfi_wrdata_0);
    memory_model->dfi_wrdata_1(dfi_wrdata_1);
    memory_model->dfi_wrdata_2(dfi_wrdata_2);
    memory_model->dfi_wrdata_3(dfi_wrdata_3);
    memory_model->dfi_wrdata_4(dfi_wrdata_4);
    memory_model->dfi_wrdata_5(dfi_wrdata_5);
    memory_model->dfi_wrdata_6(dfi_wrdata_6);
    memory_model->dfi_wrdata_7(dfi_wrdata_7);
    memory_model->dfi_wrdata_8(dfi_wrdata_8);
    memory_model->dfi_wrdata_9(dfi_wrdata_9);
    memory_model->dfi_wrdata_10(dfi_wrdata_10);
    memory_model->dfi_wrdata_11(dfi_wrdata_11);
    memory_model->dfi_wrdata_12(dfi_wrdata_12);
    memory_model->dfi_wrdata_13(dfi_wrdata_13);
    memory_model->dfi_wrdata_14(dfi_wrdata_14);
    memory_model->dfi_wrdata_15(dfi_wrdata_15);
    
    // Connect DFI write data masks and enables
    memory_model->dfi_wrdata_mask_0(dfi_wrdata_mask_0);
    memory_model->dfi_wrdata_mask_1(dfi_wrdata_mask_1);
    memory_model->dfi_wrdata_mask_2(dfi_wrdata_mask_2);
    memory_model->dfi_wrdata_mask_3(dfi_wrdata_mask_3);
    memory_model->dfi_wrdata_mask_4(dfi_wrdata_mask_4);
    memory_model->dfi_wrdata_mask_5(dfi_wrdata_mask_5);
    memory_model->dfi_wrdata_mask_6(dfi_wrdata_mask_6);
    memory_model->dfi_wrdata_mask_7(dfi_wrdata_mask_7);
    memory_model->dfi_wrdata_mask_8(dfi_wrdata_mask_8);
    memory_model->dfi_wrdata_mask_9(dfi_wrdata_mask_9);
    memory_model->dfi_wrdata_mask_10(dfi_wrdata_mask_10);
    memory_model->dfi_wrdata_mask_11(dfi_wrdata_mask_11);
    memory_model->dfi_wrdata_mask_12(dfi_wrdata_mask_12);
    memory_model->dfi_wrdata_mask_13(dfi_wrdata_mask_13);
    memory_model->dfi_wrdata_mask_14(dfi_wrdata_mask_14);
    memory_model->dfi_wrdata_mask_15(dfi_wrdata_mask_15);
    
    memory_model->dfi_wrdata_en_0(dfi_wrdata_en_0);
    memory_model->dfi_wrdata_en_1(dfi_wrdata_en_1);
    memory_model->dfi_wrdata_en_2(dfi_wrdata_en_2);
    memory_model->dfi_wrdata_en_3(dfi_wrdata_en_3);
    memory_model->dfi_wrdata_en_4(dfi_wrdata_en_4);
    memory_model->dfi_wrdata_en_5(dfi_wrdata_en_5);
    memory_model->dfi_wrdata_en_6(dfi_wrdata_en_6);
    memory_model->dfi_wrdata_en_7(dfi_wrdata_en_7);
    memory_model->dfi_wrdata_en_8(dfi_wrdata_en_8);
    memory_model->dfi_wrdata_en_9(dfi_wrdata_en_9);
    memory_model->dfi_wrdata_en_10(dfi_wrdata_en_10);
    memory_model->dfi_wrdata_en_11(dfi_wrdata_en_11);
    memory_model->dfi_wrdata_en_12(dfi_wrdata_en_12);
    memory_model->dfi_wrdata_en_13(dfi_wrdata_en_13);
    memory_model->dfi_wrdata_en_14(dfi_wrdata_en_14);
    memory_model->dfi_wrdata_en_15(dfi_wrdata_en_15);
    
    // Connect DFI read control outputs
    memory_model->mc_rdrst_b(mc_rdrst_b);
    memory_model->mc_rcv_en(mc_rcv_en);
    memory_model->dfi_rddata_en(dfi_rddata_en);
}

void QemuSystemCBridge::initialize_signals() {
    // Only initialize reset signals here - AXI signals will be handled by memory_interface_process
    model_reset.write(false);
    model_porst.write(false);
}

void QemuSystemCBridge::initialization_process() {
    // Initialize signals first
    initialize_signals();
    
    // Wait a bit then release reset (this can only be done in SC_THREAD)
    wait(100, SC_NS);
    model_porst.write(true);
    wait(50, SC_NS);
    model_reset.write(true);
    wait(50, SC_NS);
    
    std::cout << "SystemC bridge initialization complete" << std::endl;
    
    // This process only handles initialization, then exits
    // All other signal activity will be handled by memory_interface_process
}

void QemuSystemCBridge::start_server() {
    if (server_running.load()) {
        return;
    }
    
    setup_server_socket();
    server_running.store(true);
    
    // Start dedicated server thread for accepting connections
    server_thread = std::thread([this]() {
        std::cout << "Dedicated server thread started, listening for connections..." << std::endl;
        
        while (!shutdown_requested.load()) {
            if (!server_running.load()) {
                std::cout << "Server not running, waiting..." << std::endl;
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
                continue;
            }
            
            std::cout << "Server thread loop iteration, checking for connections..." << std::endl;
            
            // Clean up finished client threads
            {
                std::lock_guard<std::mutex> lock(clients_mutex);
                auto it = client_threads.begin();
                while (it != client_threads.end()) {
                    if (it->joinable()) {
                        ++it;  // Keep joinable threads
                    } else {
                        std::cout << "Cleaning up finished client thread" << std::endl;
                        it = client_threads.erase(it);
                    }
                }
                std::cout << "Active client threads: " << client_threads.size() << std::endl;
            }
            
            std::cout << "Calling accept() on server socket " << server_socket << "..." << std::endl;
            
            struct sockaddr_in client_addr;
            socklen_t client_len = sizeof(client_addr);
            
            int client_socket = accept(server_socket, (struct sockaddr*)&client_addr, &client_len);
            if (client_socket < 0) {
                if (!shutdown_requested.load()) {
                    std::cerr << "Failed to accept client connection, errno: " << errno << std::endl;
                }
                std::cout << "Accept failed, continuing server loop..." << std::endl;
                std::this_thread::sleep_for(std::chrono::milliseconds(10));
                continue;
            }
            
            std::cout << "Client connected from " << inet_ntoa(client_addr.sin_addr) 
                      << ":" << ntohs(client_addr.sin_port) << " on socket " << client_socket << std::endl;
            
            // Create thread to handle client
            {
                std::lock_guard<std::mutex> lock(clients_mutex);
                client_threads.emplace_back(&QemuSystemCBridge::handle_client_connection, this, client_socket);
                std::cout << "Created client handler thread, total threads: " << client_threads.size() << std::endl;
            }
            
            std::cout << "Server thread continuing to next iteration..." << std::endl;
            std::this_thread::sleep_for(std::chrono::milliseconds(10));  // Small delay to prevent busy waiting
        }
        
        std::cout << "Dedicated server thread exiting..." << std::endl;
    });
    
    std::cout << "SystemC-QEMU bridge server started on port " << server_port << std::endl;
}

void QemuSystemCBridge::stop_server() {
    if (!server_running.load()) {
        return;
    }
    
    shutdown_requested.store(true);
    server_running.store(false);
    
    if (server_socket >= 0) {
        close(server_socket);
        server_socket = -1;
    }
    
    // Wait for dedicated server thread to finish
    if (server_thread.joinable()) {
        server_thread.join();
    }
    
    // Wait for client threads to finish
    {
        std::lock_guard<std::mutex> lock(clients_mutex);
        for (auto& thread : client_threads) {
            if (thread.joinable()) {
                thread.join();
            }
        }
        client_threads.clear();
    }
    
    std::cout << "SystemC-QEMU bridge server stopped" << std::endl;
}

void QemuSystemCBridge::setup_server_socket() {
    server_socket = socket(AF_INET, SOCK_STREAM, 0);
    if (server_socket < 0) {
        throw std::runtime_error("Failed to create server socket");
    }
    
    int opt = 1;
    if (setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) < 0) {
        close(server_socket);
        throw std::runtime_error("Failed to set socket options");
    }
    
    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(server_port);
    
    if (bind(server_socket, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        close(server_socket);
        throw std::runtime_error("Failed to bind server socket");
    }
    
    if (listen(server_socket, 5) < 0) {
        close(server_socket);
        throw std::runtime_error("Failed to listen on server socket");
    }
}

void QemuSystemCBridge::server_process() {
    std::cout << "Server process started, listening for connections..." << std::endl;
    
    while (!shutdown_requested.load()) {
        if (!server_running.load()) {
            std::cout << "Server not running, waiting..." << std::endl;
            wait(100, SC_MS);
            continue;
        }
        
        std::cout << "Server process loop iteration, checking for connections..." << std::endl;
        
        // Clean up finished client threads
        {
            std::lock_guard<std::mutex> lock(clients_mutex);
            auto it = client_threads.begin();
            while (it != client_threads.end()) {
                if (it->joinable()) {
                    ++it;  // Keep joinable threads
                } else {
                    std::cout << "Cleaning up finished client thread" << std::endl;
                    it = client_threads.erase(it);
                }
            }
            std::cout << "Active client threads: " << client_threads.size() << std::endl;
        }
        
        std::cout << "Calling accept() on server socket " << server_socket << "..." << std::endl;
        
        struct sockaddr_in client_addr;
        socklen_t client_len = sizeof(client_addr);
        
        int client_socket = accept(server_socket, (struct sockaddr*)&client_addr, &client_len);
        if (client_socket < 0) {
            if (!shutdown_requested.load()) {
                std::cerr << "Failed to accept client connection, errno: " << errno << std::endl;
            }
            std::cout << "Accept failed, continuing server loop..." << std::endl;
            wait(10, SC_MS);
            continue;
        }
        
        std::cout << "Client connected from " << inet_ntoa(client_addr.sin_addr) 
                  << ":" << ntohs(client_addr.sin_port) << " on socket " << client_socket << std::endl;
        
        // Create thread to handle client
        {
            std::lock_guard<std::mutex> lock(clients_mutex);
            client_threads.emplace_back(&QemuSystemCBridge::handle_client_connection, this, client_socket);
            std::cout << "Created client handler thread, total threads: " << client_threads.size() << std::endl;
        }
        
        std::cout << "Server process continuing to next iteration..." << std::endl;
        wait(10, SC_MS);  // Small delay to prevent busy waiting
    }
    
    std::cout << "Server process exiting..." << std::endl;
}

void QemuSystemCBridge::handle_client_connection(int client_socket) {
    std::cout << "Client handler thread started for socket " << client_socket << std::endl;
    
    try {
        while (!shutdown_requested.load()) {
            QemuSystemC::MessageHeader header;
            std::vector<uint8_t> data;
            
            if (!receive_message(client_socket, header, data)) {
                std::cout << "Client connection closed or receive failed" << std::endl;
                break;  // Connection closed or error
            }
            
            std::cout << "Processing message type " << header.type << " from client" << std::endl;
            process_message(client_socket, header, data);
        }
    } catch (const std::exception& e) {
        std::cerr << "Client handler error: " << e.what() << std::endl;
    }
    
    close(client_socket);
    std::cout << "Client disconnected, socket " << client_socket << " closed" << std::endl;
}

void QemuSystemCBridge::process_message(int client_socket, const QemuSystemC::MessageHeader& header, 
                                       const std::vector<uint8_t>& data) {
    switch (header.type) {
        case QemuSystemC::MSG_READ_REQUEST: {
            if (data.size() >= sizeof(QemuSystemC::MemoryRequest)) {
                const QemuSystemC::MemoryRequest* request = 
                    reinterpret_cast<const QemuSystemC::MemoryRequest*>(data.data());
                handle_read_request(client_socket, header.transaction_id, *request);
            }
            break;
        }
        
        case QemuSystemC::MSG_WRITE_REQUEST: {
            if (data.size() >= sizeof(QemuSystemC::MemoryRequest)) {
                const QemuSystemC::MemoryRequest* request = 
                    reinterpret_cast<const QemuSystemC::MemoryRequest*>(data.data());
                handle_write_request(client_socket, header.transaction_id, *request);
            }
            break;
        }
        
        case QemuSystemC::MSG_INIT_REQUEST: {
            if (data.size() >= sizeof(QemuSystemC::InitRequest)) {
                const QemuSystemC::InitRequest* request = 
                    reinterpret_cast<const QemuSystemC::InitRequest*>(data.data());
                handle_init_request(client_socket, header.transaction_id, *request);
            }
            break;
        }
        
        case QemuSystemC::MSG_STATUS_REQUEST: {
            handle_status_request(client_socket, header.transaction_id);
            break;
        }
        
        case QemuSystemC::MSG_SHUTDOWN: {
            shutdown_requested.store(true);
            break;
        }
        
        default:
            std::cerr << "Unknown message type: " << header.type << std::endl;
            break;
    }
}

void QemuSystemCBridge::handle_read_request(int client_socket, uint64_t transaction_id, 
                                          const QemuSystemC::MemoryRequest& request) {
    QemuSystemC::MemoryResponse response;
    response.address = request.address;
    response.size = request.size;
    response.status = 0;  // Success
    
    try {
        uint64_t data = perform_axi_read(request.address, request.size);
        memcpy(response.data, &data, std::min((uint32_t)sizeof(data), request.size));
        
        total_reads.fetch_add(1);
        bytes_read.fetch_add(request.size);
        
    } catch (const std::exception& e) {
        std::cerr << "Read error at address 0x" << std::hex << request.address 
                  << ": " << e.what() << std::endl;
        response.status = 1;  // Error
        total_errors.fetch_add(1);
    }
    
    send_message(client_socket, QemuSystemC::MSG_READ_RESPONSE, transaction_id, 
                &response, sizeof(response));
}

void QemuSystemCBridge::handle_write_request(int client_socket, uint64_t transaction_id,
                                           const QemuSystemC::MemoryRequest& request) {
    QemuSystemC::MemoryResponse response;
    response.address = request.address;
    response.size = request.size;
    response.status = 0;  // Success
    
    try {
        perform_axi_write(request.address, request.size, request.data);
        
        total_writes.fetch_add(1);
        bytes_written.fetch_add(request.size);
        
    } catch (const std::exception& e) {
        std::cerr << "Write error at address 0x" << std::hex << request.address 
                  << ": " << e.what() << std::endl;
        response.status = 1;  // Error
        total_errors.fetch_add(1);
    }
    
    send_message(client_socket, QemuSystemC::MSG_WRITE_RESPONSE, transaction_id, 
                &response, sizeof(response));
}

void QemuSystemCBridge::handle_init_request(int client_socket, uint64_t transaction_id,
                                          const QemuSystemC::InitRequest& request) {
    memory_size = request.memory_size;
    page_size = request.page_size;
    cache_line_size = request.cache_line_size;
    architecture = std::string(request.arch_name);
    
    std::cout << "System initialized: " << std::endl;
    std::cout << "  Memory size: " << (memory_size >> 20) << " MB" << std::endl;
    std::cout << "  Page size: " << page_size << " bytes" << std::endl;
    std::cout << "  Cache line: " << cache_line_size << " bytes" << std::endl;
    std::cout << "  Architecture: " << architecture << std::endl;
    
    // Send success response
    uint32_t status = 0;
    send_message(client_socket, QemuSystemC::MSG_INIT_RESPONSE, transaction_id, 
                &status, sizeof(status));
}

void QemuSystemCBridge::handle_status_request(int client_socket, uint64_t transaction_id) {
    QemuSystemC::StatusResponse status = get_status();
    send_message(client_socket, QemuSystemC::MSG_STATUS_RESPONSE, transaction_id, 
                &status, sizeof(status));
}

bool QemuSystemCBridge::send_message(int socket, QemuSystemC::MessageType type, 
                                    uint64_t transaction_id, const void* data, uint32_t size) {
    QemuSystemC::MessageHeader header;
    header.type = type;
    header.length = size;
    header.transaction_id = transaction_id;
    header.timestamp = std::chrono::duration_cast<std::chrono::nanoseconds>(
        std::chrono::high_resolution_clock::now().time_since_epoch()).count();
    
    // Send header
    if (send(socket, &header, sizeof(header), 0) != sizeof(header)) {
        return false;
    }
    
    // Send data if present
    if (size > 0 && data != nullptr) {
        if (send(socket, data, size, 0) != (ssize_t)size) {
            return false;
        }
    }
    
    return true;
}

bool QemuSystemCBridge::receive_message(int socket, QemuSystemC::MessageHeader& header, 
                                       std::vector<uint8_t>& data) {
    // Receive header
    if (recv(socket, &header, sizeof(header), MSG_WAITALL) != sizeof(header)) {
        return false;
    }
    
    // Receive data if present
    if (header.length > 0) {
        data.resize(header.length);
        if (recv(socket, data.data(), header.length, MSG_WAITALL) != (ssize_t)header.length) {
            return false;
        }
    }
    
    return true;
}

void QemuSystemCBridge::perform_axi_write(uint64_t address, uint32_t size, const uint8_t* data) {
    // Convert data to 64-bit value
    uint64_t write_data = 0;
    memcpy(&write_data, data, std::min((uint32_t)sizeof(write_data), size));
    
    // Write directly to SystemC memory model
    if (memory_model) {
        uint8_t strb = 0xFF; // All bytes enabled for simplicity
        memory_model->write_memory_block(address, write_data, strb);
    }
    
    std::cout << "Direct write: addr=0x" << std::hex << address 
              << " data=0x" << write_data << std::dec << std::endl;
}

uint64_t QemuSystemCBridge::perform_axi_read(uint64_t address, uint32_t size) {
    (void)size; // Suppress unused parameter warning
    
    // Get data directly from SystemC memory model
    if (memory_model) {
        return memory_model->read_memory_block(address);
    }
    
    // Fallback: return address-based pattern if no memory model
    return 0x1234567800000000ULL | (address & 0xFFFFFFFF);
}

void QemuSystemCBridge::wait_for_axi_transaction() {
    wait(model_clock->posedge_event());
}

void QemuSystemCBridge::memory_interface_process() {
    // Wait for initialization to complete first
    wait(200, SC_NS);
    
    // Initialize all AXI and other signals (this process is the only one that writes to these)
    axi_awvalid.write(false);
    axi_wvalid.write(false);
    axi_bready.write(true);
    axi_arvalid.write(false);
    axi_rready.write(true);
    
    // Initialize APB signals
    mc_penable.write(false);
    mc_psel.write(false);
    mc_pwr.write(false);
    mc_paddr.write(0);
    mc_pwdata.write(0);
    
    // Initialize DFI read data signals (simulate memory responses)
    dfi_rddata_valid.write(false);
    dfi_rddata_0.write(0);
    dfi_rddata_1.write(0);
    dfi_rddata_2.write(0);
    dfi_rddata_3.write(0);
    dfi_rddata_4.write(0);
    dfi_rddata_5.write(0);
    dfi_rddata_6.write(0);
    dfi_rddata_7.write(0);
    dfi_rddata_8.write(0);
    dfi_rddata_9.write(0);
    dfi_rddata_10.write(0);
    dfi_rddata_11.write(0);
    dfi_rddata_12.write(0);
    dfi_rddata_13.write(0);
    dfi_rddata_14.write(0);
    dfi_rddata_15.write(0);
    
    wait(10, SC_NS);  // Allow signals to settle
    
    // Generate periodic signal activity to ensure VCD trace is created
    int cycle_count = 0;
    while (!shutdown_requested.load()) {
        // Generate some signal activity every few cycles
        if (cycle_count % 100 == 0) {
            // Toggle AXI signals to generate trace activity
            axi_awvalid.write(true);
            axi_awaddr.write(0x1000 + (cycle_count * 8));
            axi_awid.write(cycle_count & 0xFFF);
            wait(1, SC_NS);
            
            axi_awvalid.write(false);
            wait(1, SC_NS);
            
            axi_arvalid.write(true);
            axi_araddr.write(0x2000 + (cycle_count * 8));
            axi_arid.write(cycle_count & 0xFFF);
            wait(1, SC_NS);
            
            axi_arvalid.write(false);
            wait(1, SC_NS);
        }
        
        // Process any pending memory operations
        std::unique_lock<std::mutex> lock(memory_mutex);
        while (!memory_operations.empty()) {
            auto operation = memory_operations.front();
            memory_operations.pop();
            lock.unlock();
            
            operation();
            wait(1, SC_NS);  // Allow signal changes to be captured
            
            lock.lock();
        }
        lock.unlock();
        
        // Wait for next simulation cycle
        wait(10, SC_NS);
        cycle_count++;
        
        // Limit cycles to prevent infinite loop
        if (cycle_count > 10000) {
            cycle_count = 0;
        }
    }
}

QemuSystemC::StatusResponse QemuSystemCBridge::get_status() {
    QemuSystemC::StatusResponse status;
    status.total_reads = total_reads.load();
    status.total_writes = total_writes.load();
    status.total_errors = total_errors.load();
    
    // Calculate bandwidth
    auto now = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::seconds>(now - start_time);
    if (duration.count() > 0) {
        status.current_bandwidth = (bytes_read.load() + bytes_written.load()) / duration.count();
    } else {
        status.current_bandwidth = 0;
    }
    
    // Get memory model statistics
    status.active_banks = 8;  // Placeholder
    status.page_hits = 0;     // Placeholder
    status.page_misses = 0;   // Placeholder
    
    return status;
}

void QemuSystemCBridge::print_statistics() {
    auto status = get_status();
    
    std::cout << "\n=== SystemC-QEMU Bridge Statistics ===" << std::endl;
    std::cout << "Total Reads:    " << status.total_reads << std::endl;
    std::cout << "Total Writes:   " << status.total_writes << std::endl;
    std::cout << "Total Errors:   " << status.total_errors << std::endl;
    std::cout << "Bandwidth:      " << (status.current_bandwidth >> 20) << " MB/s" << std::endl;
    std::cout << "Active Banks:   " << status.active_banks << std::endl;
    std::cout << "Page Hits:      " << status.page_hits << std::endl;
    std::cout << "Page Misses:    " << status.page_misses << std::endl;
    std::cout << "=======================================" << std::endl;
}

// WhitneySystemCServer implementation
WhitneySystemCServer::WhitneySystemCServer(int port, uint64_t memory_size, const std::string& arch)
    : running(false) {
    (void)memory_size; // Suppress unused parameter warning
    (void)arch;        // Suppress unused parameter warning
    bridge = std::make_unique<QemuSystemCBridge>("qemu_bridge", port);
}

void WhitneySystemCServer::setup_tracing(const std::string& trace_filename) {
    if (bridge) {
        bridge->setup_tracing(trace_filename);
    }
}

WhitneySystemCServer::~WhitneySystemCServer() {
    stop();
}

void WhitneySystemCServer::run() {
    if (running.load()) {
        return;
    }
    
    running.store(true);
    
    // Start SystemC simulation in separate thread
    systemc_thread = std::thread(&WhitneySystemCServer::systemc_simulation_thread, this);
    
    // Start the bridge server
    bridge->start_server();
    
    std::cout << "Whitney SystemC Server running..." << std::endl;
    std::cout << "Press Ctrl+C to stop" << std::endl;
    
    // Wait for shutdown signal
    while (running.load()) {
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
}

void WhitneySystemCServer::stop() {
    if (!running.load()) {
        return;
    }
    
    running.store(false);
    
    // Close tracing first to ensure VCD file is written
    if (bridge) {
        bridge->close_tracing();
    }
    
    bridge->stop_server();
    
    if (systemc_thread.joinable()) {
        systemc_thread.join();
    }
    
    std::cout << "Whitney SystemC Server stopped" << std::endl;
}

void WhitneySystemCServer::systemc_simulation_thread() {
    try {
        // Start SystemC simulation - run indefinitely until stopped
        std::cout << "Starting SystemC simulation thread..." << std::endl;
        
        // Run initial simulation to generate some trace data
        sc_start(1, SC_US);  // Run for 1 microsecond initially
        
        while (running.load()) {
            // Run simulation for a small time slice to keep it active
            sc_start(10, SC_MS);
            
            // Small delay to prevent busy waiting
            std::this_thread::sleep_for(std::chrono::milliseconds(1));
        }
        
        // Run a final simulation cycle to ensure trace data is written
        sc_start(1, SC_NS);
        
        std::cout << "SystemC simulation thread stopping..." << std::endl;
    } catch (const std::exception& e) {
        std::cerr << "SystemC simulation error: " << e.what() << std::endl;
    }
}

// Tracing implementation
void QemuSystemCBridge::setup_tracing(const std::string& trace_filename) {
    if (trace_fp != nullptr) {
        close_tracing();
    }
    
    // Remove .vcd extension if present since sc_create_vcd_trace_file adds it automatically
    std::string base_filename = trace_filename;
    if (base_filename.size() > 4 && base_filename.substr(base_filename.size() - 4) == ".vcd") {
        base_filename = base_filename.substr(0, base_filename.size() - 4);
    }
    
    this->trace_filename = base_filename;
    trace_fp = sc_create_vcd_trace_file(base_filename.c_str());
    
    if (trace_fp == nullptr) {
        std::cerr << "Failed to create VCD trace file: " << base_filename << std::endl;
        return;
    }
    
    std::cout << "Setting up VCD tracing to: " << base_filename << ".vcd" << std::endl;
    
    // Trace clock signals
    sc_trace(trace_fp, *model_clock, "model_clock");
    sc_trace(trace_fp, *slow_clock, "slow_clock");
    sc_trace(trace_fp, model_reset, "model_reset");
    sc_trace(trace_fp, model_porst, "model_porst");
    
    // Trace AXI Write Address Channel
    sc_trace(trace_fp, axi_awid, "axi_awid");
    sc_trace(trace_fp, axi_awaddr, "axi_awaddr");
    sc_trace(trace_fp, axi_awlen, "axi_awlen");
    sc_trace(trace_fp, axi_awsize, "axi_awsize");
    sc_trace(trace_fp, axi_awburst, "axi_awburst");
    sc_trace(trace_fp, axi_awvalid, "axi_awvalid");
    sc_trace(trace_fp, axi_awready, "axi_awready");
    
    // Trace AXI Write Data Channel
    sc_trace(trace_fp, axi_wdata, "axi_wdata");
    sc_trace(trace_fp, axi_wstrb, "axi_wstrb");
    sc_trace(trace_fp, axi_wlast, "axi_wlast");
    sc_trace(trace_fp, axi_wvalid, "axi_wvalid");
    sc_trace(trace_fp, axi_wready, "axi_wready");
    
    // Trace AXI Write Response Channel
    sc_trace(trace_fp, axi_bid, "axi_bid");
    sc_trace(trace_fp, axi_bresp, "axi_bresp");
    sc_trace(trace_fp, axi_bvalid, "axi_bvalid");
    sc_trace(trace_fp, axi_bready, "axi_bready");
    
    // Trace AXI Read Address Channel
    sc_trace(trace_fp, axi_arid, "axi_arid");
    sc_trace(trace_fp, axi_araddr, "axi_araddr");
    sc_trace(trace_fp, axi_arlen, "axi_arlen");
    sc_trace(trace_fp, axi_arsize, "axi_arsize");
    sc_trace(trace_fp, axi_arburst, "axi_arburst");
    sc_trace(trace_fp, axi_arvalid, "axi_arvalid");
    sc_trace(trace_fp, axi_arready, "axi_arready");
    
    // Trace AXI Read Data Channel
    sc_trace(trace_fp, axi_rid, "axi_rid");
    sc_trace(trace_fp, axi_rdata, "axi_rdata");
    sc_trace(trace_fp, axi_rresp, "axi_rresp");
    sc_trace(trace_fp, axi_rlast, "axi_rlast");
    sc_trace(trace_fp, axi_rvalid, "axi_rvalid");
    sc_trace(trace_fp, axi_rready, "axi_rready");
    
    // Trace APB interface
    sc_trace(trace_fp, mc_penable, "mc_penable");
    sc_trace(trace_fp, mc_psel, "mc_psel");
    sc_trace(trace_fp, mc_pwr, "mc_pwr");
    sc_trace(trace_fp, mc_paddr, "mc_paddr");
    sc_trace(trace_fp, mc_pwdata, "mc_pwdata");
    sc_trace(trace_fp, mc_prdata, "mc_prdata");
    sc_trace(trace_fp, mc_pready, "mc_pready");
    sc_trace(trace_fp, mc_pslverr, "mc_pslverr");
    
    // Trace some key DFI signals
    sc_trace(trace_fp, dfi_rddata_valid, "dfi_rddata_valid");
    sc_trace(trace_fp, dfi_rddata_0, "dfi_rddata_0");
    sc_trace(trace_fp, dfi_rddata_1, "dfi_rddata_1");
    sc_trace(trace_fp, dfi_wrdata_0, "dfi_wrdata_0");
    sc_trace(trace_fp, dfi_wrdata_1, "dfi_wrdata_1");
    sc_trace(trace_fp, dfi_reset_n, "dfi_reset_n");
    
    std::cout << "VCD tracing setup complete" << std::endl;
}

void QemuSystemCBridge::close_tracing() {
    if (trace_fp != nullptr) {
        sc_close_vcd_trace_file(trace_fp);
        trace_fp = nullptr;
        std::cout << "VCD trace file closed: " << trace_filename << ".vcd" << std::endl;
    }
}
