#include "Vddr2_axi_controller.h"
#include "verilated.h"
#include <iostream>

// Required by Verilator for time tracking
double sc_time_stamp() {
    return 0;  // Called by $time in Verilog
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    
    // Create instance of our module under test
    Vddr2_axi_controller* dut = new Vddr2_axi_controller;
    
    std::cout << "Starting DDR2 Controller smoke test..." << std::endl;
    
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
    
    // Apply reset
    for (int i = 0; i < 10; i++) {
        dut->axi_aclk = 0;
        dut->ddr_clk = 0;
        dut->eval();
        dut->axi_aclk = 1;
        dut->ddr_clk = 1;
        dut->eval();
    }
    
    // Release reset
    dut->axi_aresetn = 1;
    dut->ddr_rst_n = 1;
    std::cout << "Reset released" << std::endl;
    
    // Run for some clock cycles
    for (int i = 0; i < 100; i++) {
        dut->axi_aclk = 0;
        dut->ddr_clk = 0;
        dut->eval();
        dut->axi_aclk = 1;
        dut->ddr_clk = 1;
        dut->eval();
        
        // Check some basic signals
        if (i == 50) {
            std::cout << "Cycle 50: ddr2_cke = " << (int)dut->ddr2_cke << std::endl;
            std::cout << "Cycle 50: ddr2_cs_n = " << (int)dut->ddr2_cs_n << std::endl;
        }
    }
    
    std::cout << "✅ Smoke test completed successfully!" << std::endl;
    std::cout << "Final state:" << std::endl;
    std::cout << "  ddr2_cke = " << (int)dut->ddr2_cke << std::endl;
    std::cout << "  ddr2_cs_n = " << (int)dut->ddr2_cs_n << std::endl;
    std::cout << "  s_axi_awready = " << (int)dut->s_axi_awready << std::endl;
    std::cout << "  s_axi_arready = " << (int)dut->s_axi_arready << std::endl;
    
    // Cleanup
    delete dut;
    return 0;
}