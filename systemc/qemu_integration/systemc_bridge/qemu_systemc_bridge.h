#ifndef QEMU_SYSTEMC_BRIDGE_H
#define QEMU_SYSTEMC_BRIDGE_H

#include <systemc.h>
#include <iostream>
#include <thread>
#include <mutex>
#include <queue>
#include <condition_variable>
#include <atomic>
#include <memory>
#include <unordered_map>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <cstring>

// Include the enhanced Whitney model
#include "../src/whitney_systemc_model_enhanced.h"

// Protocol definitions for QEMU-SystemC communication
namespace QemuSystemC {

// Message types
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

// Message header
struct MessageHeader {
    uint32_t type;
    uint32_t length;
    uint64_t transaction_id;
    uint64_t timestamp;
} __attribute__((packed));

// Memory access request
struct MemoryRequest {
    uint64_t address;
    uint32_t size;
    uint32_t access_type;  // 0=read, 1=write
    uint8_t data[64];      // Maximum data size
} __attribute__((packed));

// Memory access response
struct MemoryResponse {
    uint64_t address;
    uint32_t size;
    uint32_t status;       // 0=success, 1=error
    uint8_t data[64];      // Response data
} __attribute__((packed));

// System initialization request
struct InitRequest {
    uint64_t memory_size;
    uint32_t page_size;
    uint32_t cache_line_size;
    char arch_name[32];
} __attribute__((packed));

// System status response
struct StatusResponse {
    uint64_t total_reads;
    uint64_t total_writes;
    uint64_t total_errors;
    uint64_t current_bandwidth;
    uint32_t active_banks;
    uint32_t page_hits;
    uint32_t page_misses;
} __attribute__((packed));

} // namespace QemuSystemC

// Main bridge class
class QemuSystemCBridge : public sc_module {
public:
    // Constructor
    SC_HAS_PROCESS(QemuSystemCBridge);
    QemuSystemCBridge(sc_module_name name, int port = 8888);
    
    // Destructor
    ~QemuSystemCBridge();

    // Main interface methods
    void start_server();
    void stop_server();
    bool is_running() const { return server_running.load(); }

    // Memory interface methods
    uint64_t read_memory(uint64_t address, uint32_t size);
    bool write_memory(uint64_t address, uint32_t size, const uint8_t* data);
    
    // Statistics and monitoring
    void print_statistics();
    QemuSystemC::StatusResponse get_status();
    
    // Tracing support
    void setup_tracing(const std::string& trace_filename);
    void close_tracing();

private:
    // SystemC processes
    void server_process();
    void client_handler_process();
    void memory_interface_process();
    void initialization_process();

    // Network handling
    void setup_server_socket();
    void handle_client_connection(int client_socket);
    void process_message(int client_socket, const QemuSystemC::MessageHeader& header, 
                        const std::vector<uint8_t>& data);
    
    // Message handlers
    void handle_read_request(int client_socket, uint64_t transaction_id, 
                           const QemuSystemC::MemoryRequest& request);
    void handle_write_request(int client_socket, uint64_t transaction_id,
                            const QemuSystemC::MemoryRequest& request);
    void handle_init_request(int client_socket, uint64_t transaction_id,
                           const QemuSystemC::InitRequest& request);
    void handle_status_request(int client_socket, uint64_t transaction_id);

    // Utility methods
    bool send_message(int socket, QemuSystemC::MessageType type, 
                     uint64_t transaction_id, const void* data, uint32_t size);
    bool receive_message(int socket, QemuSystemC::MessageHeader& header, 
                        std::vector<uint8_t>& data);

    // SystemC model interface
    WhitneySystemCModelEnhanced* memory_model;
    
    // Clock and reset signals for the memory model
    sc_clock* model_clock;
    sc_signal<bool> model_reset;
    sc_signal<bool> model_porst;
    
    // AXI interface signals
    sc_signal<sc_uint<12>> axi_awid;
    sc_signal<sc_uint<40>> axi_awaddr;
    sc_signal<sc_uint<8>> axi_awlen;
    sc_signal<sc_uint<3>> axi_awsize;
    sc_signal<sc_uint<2>> axi_awburst;
    sc_signal<bool> axi_awlock;
    sc_signal<sc_uint<4>> axi_awcache;
    sc_signal<sc_uint<3>> axi_awprot;
    sc_signal<sc_uint<4>> axi_awqos;
    sc_signal<bool> axi_awvalid;
    sc_signal<bool> axi_awready;
    
    sc_signal<sc_uint<64>> axi_wdata;
    sc_signal<sc_uint<8>> axi_wstrb;
    sc_signal<bool> axi_wlast;
    sc_signal<bool> axi_wvalid;
    sc_signal<bool> axi_wready;
    
    sc_signal<sc_uint<12>> axi_bid;
    sc_signal<sc_uint<2>> axi_bresp;
    sc_signal<bool> axi_bvalid;
    sc_signal<bool> axi_bready;
    
    sc_signal<sc_uint<12>> axi_arid;
    sc_signal<sc_uint<40>> axi_araddr;
    sc_signal<sc_uint<8>> axi_arlen;
    sc_signal<sc_uint<3>> axi_arsize;
    sc_signal<sc_uint<2>> axi_arburst;
    sc_signal<bool> axi_arlock;
    sc_signal<sc_uint<4>> axi_arcache;
    sc_signal<sc_uint<3>> axi_arprot;
    sc_signal<sc_uint<4>> axi_arqos;
    sc_signal<bool> axi_arvalid;
    sc_signal<bool> axi_arready;
    
    sc_signal<sc_uint<12>> axi_rid;
    sc_signal<sc_uint<64>> axi_rdata;
    sc_signal<sc_uint<2>> axi_rresp;
    sc_signal<bool> axi_rlast;
    sc_signal<bool> axi_rvalid;
    sc_signal<bool> axi_rready;

    // Additional signals for enhanced Whitney model
    sc_clock* slow_clock;
    
    // APB interface signals
    sc_signal<bool> mc_penable;
    sc_signal<bool> mc_psel;
    sc_signal<bool> mc_pwr;
    sc_signal<sc_uint<10>> mc_paddr;
    sc_signal<sc_uint<32>> mc_pwdata;
    sc_signal<sc_uint<32>> mc_prdata;
    sc_signal<bool> mc_pready;
    sc_signal<bool> mc_pslverr;
    
    // DFI read data signals (inputs to memory model)
    sc_signal<bool> dfi_rddata_valid;
    sc_signal<sc_uint<32>> dfi_rddata_0;
    sc_signal<sc_uint<32>> dfi_rddata_1;
    sc_signal<sc_uint<32>> dfi_rddata_2;
    sc_signal<sc_uint<32>> dfi_rddata_3;
    sc_signal<sc_uint<32>> dfi_rddata_4;
    sc_signal<sc_uint<32>> dfi_rddata_5;
    sc_signal<sc_uint<32>> dfi_rddata_6;
    sc_signal<sc_uint<32>> dfi_rddata_7;
    sc_signal<sc_uint<32>> dfi_rddata_8;
    sc_signal<sc_uint<32>> dfi_rddata_9;
    sc_signal<sc_uint<32>> dfi_rddata_10;
    sc_signal<sc_uint<32>> dfi_rddata_11;
    sc_signal<sc_uint<32>> dfi_rddata_12;
    sc_signal<sc_uint<32>> dfi_rddata_13;
    sc_signal<sc_uint<32>> dfi_rddata_14;
    sc_signal<sc_uint<32>> dfi_rddata_15;
    
    // DFI output signals (outputs from memory model - need dummy connections)
    sc_signal<sc_uint<2>> dfi_dram_clk_disable_0;
    sc_signal<sc_uint<2>> dfi_dram_clk_disable_1;
    sc_signal<bool> dfi_dram_ca_disable;
    sc_signal<sc_uint<2>> dfi_cs_0_p0;
    sc_signal<sc_uint<2>> dfi_cs_0_p1;
    sc_signal<sc_uint<2>> dfi_cs_1_p2;
    sc_signal<sc_uint<2>> dfi_cs_1_p3;
    sc_signal<sc_uint<7>> dfi_address_0_p0;
    sc_signal<sc_uint<7>> dfi_address_0_p1;
    sc_signal<sc_uint<7>> dfi_address_1_p2;
    sc_signal<sc_uint<7>> dfi_address_1_p3;
    sc_signal<bool> dfi_reset_n;
    sc_signal<sc_uint<4>> dfi_wck_cs;
    sc_signal<sc_uint<4>> dfi_wck_en;
    sc_signal<sc_uint<2>> dfi_wck_toggle;
    
    // DFI write data outputs
    sc_signal<sc_uint<32>> dfi_wrdata_0;
    sc_signal<sc_uint<32>> dfi_wrdata_1;
    sc_signal<sc_uint<32>> dfi_wrdata_2;
    sc_signal<sc_uint<32>> dfi_wrdata_3;
    sc_signal<sc_uint<32>> dfi_wrdata_4;
    sc_signal<sc_uint<32>> dfi_wrdata_5;
    sc_signal<sc_uint<32>> dfi_wrdata_6;
    sc_signal<sc_uint<32>> dfi_wrdata_7;
    sc_signal<sc_uint<32>> dfi_wrdata_8;
    sc_signal<sc_uint<32>> dfi_wrdata_9;
    sc_signal<sc_uint<32>> dfi_wrdata_10;
    sc_signal<sc_uint<32>> dfi_wrdata_11;
    sc_signal<sc_uint<32>> dfi_wrdata_12;
    sc_signal<sc_uint<32>> dfi_wrdata_13;
    sc_signal<sc_uint<32>> dfi_wrdata_14;
    sc_signal<sc_uint<32>> dfi_wrdata_15;
    
    // DFI write data masks and enables
    sc_signal<sc_uint<4>> dfi_wrdata_mask_0;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_1;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_2;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_3;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_4;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_5;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_6;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_7;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_8;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_9;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_10;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_11;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_12;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_13;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_14;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_15;
    
    sc_signal<sc_uint<4>> dfi_wrdata_en_0;
    sc_signal<sc_uint<4>> dfi_wrdata_en_1;
    sc_signal<sc_uint<4>> dfi_wrdata_en_2;
    sc_signal<sc_uint<4>> dfi_wrdata_en_3;
    sc_signal<sc_uint<4>> dfi_wrdata_en_4;
    sc_signal<sc_uint<4>> dfi_wrdata_en_5;
    sc_signal<sc_uint<4>> dfi_wrdata_en_6;
    sc_signal<sc_uint<4>> dfi_wrdata_en_7;
    sc_signal<sc_uint<4>> dfi_wrdata_en_8;
    sc_signal<sc_uint<4>> dfi_wrdata_en_9;
    sc_signal<sc_uint<4>> dfi_wrdata_en_10;
    sc_signal<sc_uint<4>> dfi_wrdata_en_11;
    sc_signal<sc_uint<4>> dfi_wrdata_en_12;
    sc_signal<sc_uint<4>> dfi_wrdata_en_13;
    sc_signal<sc_uint<4>> dfi_wrdata_en_14;
    sc_signal<sc_uint<4>> dfi_wrdata_en_15;
    
    // DFI read control outputs
    sc_signal<bool> mc_rdrst_b;
    sc_signal<bool> mc_rcv_en;
    sc_signal<bool> dfi_rddata_en;

    // Server configuration
    int server_port;
    int server_socket;
    std::atomic<bool> server_running;
    std::atomic<bool> shutdown_requested;
    
    // Client management
    std::vector<std::thread> client_threads;
    std::mutex clients_mutex;
    std::thread server_thread;  // Dedicated server thread for accepting connections
    
    // Transaction management
    std::atomic<uint64_t> transaction_counter;
    std::unordered_map<uint64_t, std::chrono::high_resolution_clock::time_point> pending_transactions;
    std::mutex transactions_mutex;
    
    // Statistics
    std::atomic<uint64_t> total_reads;
    std::atomic<uint64_t> total_writes;
    std::atomic<uint64_t> total_errors;
    std::atomic<uint64_t> bytes_read;
    std::atomic<uint64_t> bytes_written;
    std::chrono::high_resolution_clock::time_point start_time;
    
    // Configuration
    uint64_t memory_size;
    uint32_t page_size;
    uint32_t cache_line_size;
    std::string architecture;
    
    // Synchronization and flow control
    std::mutex memory_mutex;
    std::condition_variable memory_cv;
    std::queue<std::function<void()>> memory_operations;
    std::atomic<int> active_transaction_count;
    static constexpr int MAX_PENDING_TRANSACTIONS = 8;  // Limit concurrent transactions
    
    // Helper methods
    void connect_memory_model();
    void initialize_signals();
    void perform_axi_write(uint64_t address, uint32_t size, const uint8_t* data);
    uint64_t perform_axi_read(uint64_t address, uint32_t size);
    void wait_for_axi_transaction();
    
    // Trace file handle
    sc_trace_file* trace_fp;
    std::string trace_filename;
};

// Standalone server class for command-line usage
class WhitneySystemCServer {
public:
    WhitneySystemCServer(int port, uint64_t memory_size, const std::string& arch);
    ~WhitneySystemCServer();
    
    void run();
    void stop();
    void setup_tracing(const std::string& trace_filename);
    
private:
    std::unique_ptr<QemuSystemCBridge> bridge;
    std::thread systemc_thread;
    std::atomic<bool> running;
    
    void systemc_simulation_thread();
};

#endif // QEMU_SYSTEMC_BRIDGE_H
