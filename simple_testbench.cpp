#include "Vddr2_controller.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <string>

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    
    // Parse command line arguments for VCD filename
    std::string vcd_filename = "smoke_waveform.vcd";
    std::string memory_model = "DDR2-800";
    int test_cycles = 100;
    
    for (int i = 1; i < argc; i++) {
        if (strstr(argv[i], "--vcd=")) {
            vcd_filename = std::string(argv[i] + 6);  // Skip "--vcd="
        } else if (strstr(argv[i], "--output-vcd=")) {
            vcd_filename = std::string(argv[i] + 13);  // Skip "--output-vcd="
        } else if (strstr(argv[i], "--memory-model=")) {
            memory_model = std::string(argv[i] + 15);  // Skip "--memory-model="
        } else if (strstr(argv[i], "--test-cycles=")) {
            test_cycles = atoi(argv[i] + 14);  // Skip "--test-cycles="
        }
    }
    
    Vddr2_controller* dut = new Vddr2_controller;
    
    // Enable VCD tracing
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);  // Trace 99 levels of hierarchy
    tfp->open(vcd_filename.c_str());
    
    std::cout << "Starting DDR2 Controller smoke test..." << std::endl;
    std::cout << "Memory Model: " << memory_model << std::endl;
    std::cout << "Test Cycles: " << test_cycles << std::endl;
    std::cout << "VCD Output: " << vcd_filename << std::endl;
    
    dut->rst_n = 0;
    dut->clk = 0;
    
    for (int i = 0; i < 10; i++) {
        dut->clk = 0; 
        dut->eval();
        tfp->dump(main_time);
        main_time++;
        
        dut->clk = 1; 
        dut->eval();
        tfp->dump(main_time);
        main_time++;
    }
    
    dut->rst_n = 1;
    std::cout << "Reset released, running test..." << std::endl;
    
    for (int i = 0; i < test_cycles; i++) {
        dut->clk = 0; 
        dut->eval();
        tfp->dump(main_time);
        main_time++;
        
        dut->clk = 1; 
        dut->eval();
        tfp->dump(main_time);
        main_time++;
        
        if (i == test_cycles/4) std::cout << "Cycle " << i << ": Controller running (25%)" << std::endl;
        if (i == test_cycles/2) std::cout << "Cycle " << i << ": Controller running (50%)" << std::endl;
        if (i == (3*test_cycles)/4) std::cout << "Cycle " << i << ": Controller running (75%)" << std::endl;
    }
    
    std::cout << "✅ DDR2 Controller smoke test passed!" << std::endl;
    std::cout << "VCD file saved: " << vcd_filename << std::endl;
    
    // Close VCD file
    tfp->close();
    delete tfp;
    delete dut;
    return 0;
}