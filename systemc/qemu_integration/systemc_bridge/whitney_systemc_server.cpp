#include "qemu_systemc_bridge.h"
#include <iostream>
#include <signal.h>
#include <getopt.h>
#include <cstdlib>
#include <thread>
#include <chrono>

// Global server instance for signal handling
WhitneySystemCServer* g_server = nullptr;

// Signal handler for graceful shutdown
void signal_handler(int signal) {
    std::cout << "\nReceived signal " << signal << ", shutting down..." << std::endl;
    if (g_server) {
        g_server->stop();
        // Give some time for cleanup
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
    }
    // Don't call exit(0) here - let the main loop exit gracefully
}

void print_usage(const char* program_name) {
    std::cout << "Usage: " << program_name << " [OPTIONS]" << std::endl;
    std::cout << std::endl;
    std::cout << "Whitney LPDDR5 SystemC Server for QEMU Integration" << std::endl;
    std::cout << std::endl;
    std::cout << "Options:" << std::endl;
    std::cout << "  -p, --port PORT          Server port (default: 8888)" << std::endl;
    std::cout << "  -m, --memory-size SIZE   Memory size in MB (default: 1024)" << std::endl;
    std::cout << "  -a, --arch ARCH          Target architecture (default: arm64)" << std::endl;
    std::cout << "  -t, --trace-file FILE    VCD trace file (default: none)" << std::endl;
    std::cout << "  -l, --log-file FILE      Log file (default: stdout)" << std::endl;
    std::cout << "  -v, --verbose            Verbose output" << std::endl;
    std::cout << "  -d, --daemon             Run as daemon" << std::endl;
    std::cout << "  -h, --help               Show this help" << std::endl;
    std::cout << std::endl;
    std::cout << "Examples:" << std::endl;
    std::cout << "  " << program_name << " --port 8888 --memory-size 2048 --arch arm64" << std::endl;
    std::cout << "  " << program_name << " -p 8889 -m 4096 -a riscv64 -t memory_trace.vcd" << std::endl;
    std::cout << std::endl;
    std::cout << "Supported architectures: arm64, riscv64, x86_64" << std::endl;
}

int sc_main(int argc, char* argv[]) {
    // Default configuration
    int port = 8888;
    uint64_t memory_size_mb = 1024;
    std::string architecture = "arm64";
    std::string trace_file = "";
    std::string log_file = "";
    bool verbose = false;
    bool daemon = false;
    
    // Command line options
    static struct option long_options[] = {
        {"port",        required_argument, 0, 'p'},
        {"memory-size", required_argument, 0, 'm'},
        {"arch",        required_argument, 0, 'a'},
        {"trace-file",  required_argument, 0, 't'},
        {"log-file",    required_argument, 0, 'l'},
        {"verbose",     no_argument,       0, 'v'},
        {"daemon",      no_argument,       0, 'd'},
        {"help",        no_argument,       0, 'h'},
        {0, 0, 0, 0}
    };
    
    int option_index = 0;
    int c;
    
    while ((c = getopt_long(argc, argv, "p:m:a:t:l:vdh", long_options, &option_index)) != -1) {
        switch (c) {
            case 'p':
                port = std::atoi(optarg);
                if (port <= 0 || port > 65535) {
                    std::cerr << "Error: Invalid port number: " << optarg << std::endl;
                    return 1;
                }
                break;
                
            case 'm':
                memory_size_mb = std::atoll(optarg);
                if (memory_size_mb == 0) {
                    std::cerr << "Error: Invalid memory size: " << optarg << std::endl;
                    return 1;
                }
                break;
                
            case 'a':
                architecture = optarg;
                if (architecture != "arm64" && architecture != "riscv64" && architecture != "x86_64") {
                    std::cerr << "Error: Unsupported architecture: " << optarg << std::endl;
                    std::cerr << "Supported: arm64, riscv64, x86_64" << std::endl;
                    return 1;
                }
                break;
                
            case 't':
                trace_file = optarg;
                break;
                
            case 'l':
                log_file = optarg;
                break;
                
            case 'v':
                verbose = true;
                break;
                
            case 'd':
                daemon = true;
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
    
    // Convert memory size to bytes
    uint64_t memory_size = memory_size_mb * 1024 * 1024;
    
    // Print configuration
    std::cout << "Whitney LPDDR5 SystemC Server Configuration:" << std::endl;
    std::cout << "  Port:         " << port << std::endl;
    std::cout << "  Memory Size:  " << memory_size_mb << " MB" << std::endl;
    std::cout << "  Architecture: " << architecture << std::endl;
    if (!trace_file.empty()) {
        std::cout << "  Trace File:   " << trace_file << std::endl;
    }
    if (!log_file.empty()) {
        std::cout << "  Log File:     " << log_file << std::endl;
    }
    std::cout << "  Verbose:      " << (verbose ? "Yes" : "No") << std::endl;
    std::cout << "  Daemon:       " << (daemon ? "Yes" : "No") << std::endl;
    std::cout << std::endl;
    
    // Setup signal handlers
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    
    try {
        // Create and start server
        WhitneySystemCServer server(port, memory_size, architecture);
        g_server = &server;
        
        // Setup tracing if trace file is specified
        if (!trace_file.empty()) {
            server.setup_tracing(trace_file);
        }
        
        std::cout << "Starting Whitney LPDDR5 SystemC Server..." << std::endl;
        std::cout << "Listening on port " << port << std::endl;
        std::cout << "Press Ctrl+C to stop" << std::endl;
        std::cout << std::endl;
        
        // Run server
        server.run();
        
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
    
    std::cout << "Server shutdown complete." << std::endl;
    return 0;
}
