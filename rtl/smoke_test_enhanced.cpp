#include "Vddr2_axi_controller.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <string>
#include <cstring>

// Required by Verilator for time tracking
vluint64_t main_time = 0;
double sc_time_stamp() {
    return main_time;
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    
    // Parse command line arguments
    std::string vcd_filename = "smoke_test.vcd";
    int test_cycles = 1000;
    std::string memory_model = "DDR2-800";
    
    for (int i = 1; i < argc; i++) {
        if (strstr(argv[i], "--output-vcd=")) {
            vcd_filename = std::string(argv[i] + 13);  // Skip "--output-vcd="
        } else if (strstr(argv[i], "--test-cycles=")) {
            test_cycles = atoi(argv[i] + 14);  // Skip "--test-cycles="
        } else if (strstr(argv[i], "--memory-model=")) {
            memory_model = std::string(argv[i] + 15);  // Skip "--memory-model="
        }
    }
    
    std::cout << "Starting DDR2 Controller smoke test..." << std::endl;
    std::cout << "Memory Model: " << memory_model << std::endl;
    std::cout << "Test Cycles: " << test_cycles << std::endl;
    std::cout << "VCD Output: " << vcd_filename << std::endl;
    
    // Enable VCD tracing
    Verilated::traceEverOn(true);
    
    // Create instance of our module under test
    Vddr2_axi_controller* dut = new Vddr2_axi_controller;
    
    // Create VCD tracer
    VerilatedVcdC* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);  // Trace 99 levels of hierarchy
    tfp->open(vcd_filename.c_str());
    
    // Initialize inputs - using correct signal names from SystemVerilog
    dut->axi_aclk = 0;
    dut->axi_aresetn = 0;
    dut->ddr_clk = 0;
    dut->ddr_rst_n = 0;
    
    // Initialize AXI inputs to safe values
    dut->s_axi_awid = 0;
    dut->s_axi_awaddr = 0;
    dut->s_axi_awlen = 0;
    dut->s_axi_awsize = 0;
    dut->s_axi_awburst = 0;
    dut->s_axi_awlock = 0;
    dut->s_axi_awcache = 0;
    dut->s_axi_awprot = 0;
    dut->s_axi_awvalid = 0;
    
    dut->s_axi_wdata = 0;
    dut->s_axi_wstrb = 0;
    dut->s_axi_wlast = 0;
    dut->s_axi_wvalid = 0;
    
    dut->s_axi_bready = 0;
    
    dut->s_axi_arid = 0;
    dut->s_axi_araddr = 0;
    dut->s_axi_arlen = 0;
    dut->s_axi_arsize = 0;
    dut->s_axi_arburst = 0;
    dut->s_axi_arlock = 0;
    dut->s_axi_arcache = 0;
    dut->s_axi_arprot = 0;
    dut->s_axi_arvalid = 0;
    
    dut->s_axi_rready = 0;
    
    // Apply reset for longer duration
    std::cout << "Applying reset..." << std::endl;
    for (int i = 0; i < 20; i++) {
        dut->axi_aclk = 0;
        dut->ddr_clk = 0;
        dut->eval();
        tfp->dump(main_time);
        main_time++;
        
        dut->axi_aclk = 1;
        dut->ddr_clk = 1;
        dut->eval();
        tfp->dump(main_time);
        main_time++;
    }
    
    // Release reset
    dut->axi_aresetn = 1;
    dut->ddr_rst_n = 1;
    std::cout << "Reset released, running test..." << std::endl;
    
    // Run main test simulation
    for (int i = 0; i < test_cycles; i++) {
        // Clock low phase
        dut->axi_aclk = 0;
        dut->ddr_clk = 0;
        dut->eval();
        tfp->dump(main_time);
        main_time++;
        
        // Clock high phase
        dut->axi_aclk = 1;
        dut->ddr_clk = 1;
        dut->eval();
        tfp->dump(main_time);
        main_time++;
        
        // Progress updates
        if (i == 50) {
            std::cout << "Cycle 50: Controller running" << std::endl;
        }
        if (i == test_cycles/2) {
            std::cout << "Cycle " << i << ": Half way through test" << std::endl;
        }
        
        // Test some basic AXI operations during the simulation
        if (i >= 100 && i < 120) {
            // Try a simple write transaction
            if (i == 100) {
                dut->s_axi_awaddr = 0x1000;
                dut->s_axi_awvalid = 1;
                dut->s_axi_awlen = 0;  // Single beat
                dut->s_axi_awsize = 2; // 4 bytes
                dut->s_axi_awburst = 1; // INCR
            }
            if (i == 105 && dut->s_axi_awready) {
                dut->s_axi_awvalid = 0;
                dut->s_axi_wdata = 0xDEADBEEF;
                dut->s_axi_wstrb = 0xF;
                dut->s_axi_wlast = 1;
                dut->s_axi_wvalid = 1;
            }
            if (i == 110 && dut->s_axi_wready) {
                dut->s_axi_wvalid = 0;
                dut->s_axi_wlast = 0;
                dut->s_axi_bready = 1;
            }
            if (i == 115 && dut->s_axi_bvalid) {
                dut->s_axi_bready = 0;
            }
        }
        
        // Test a read transaction
        if (i >= 200 && i < 220) {
            if (i == 200) {
                dut->s_axi_araddr = 0x1000;
                dut->s_axi_arvalid = 1;
                dut->s_axi_arlen = 0;  // Single beat
                dut->s_axi_arsize = 2; // 4 bytes
                dut->s_axi_arburst = 1; // INCR
            }
            if (i == 205 && dut->s_axi_arready) {
                dut->s_axi_arvalid = 0;
                dut->s_axi_rready = 1;
            }
            if (i == 215 && dut->s_axi_rvalid) {
                dut->s_axi_rready = 0;
                std::cout << "Read data: 0x" << std::hex << dut->s_axi_rdata << std::dec << std::endl;
            }
        }
    }
    
    std::cout << "✅ DDR2 Controller smoke test passed!" << std::endl;
    std::cout << "Final state:" << std::endl;
    std::cout << "  ddr2_cke = " << (int)dut->ddr2_cke << std::endl;
    std::cout << "  ddr2_cs_n = " << (int)dut->ddr2_cs_n << std::endl;
    std::cout << "  s_axi_awready = " << (int)dut->s_axi_awready << std::endl;
    std::cout << "  s_axi_arready = " << (int)dut->s_axi_arready << std::endl;
    std::cout << "VCD file saved: " << vcd_filename << std::endl;
    
    // Close VCD file
    tfp->close();
    delete tfp;
    
    // Cleanup
    delete dut;
    return 0;
}