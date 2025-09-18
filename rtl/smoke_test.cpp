#include "Vddr2_controller.h"
#include "verilated.h"
#include <iostream>

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    
    // Create instance of our module under test
    Vddr2_controller* dut = new Vddr2_controller;
    
    std::cout << "Starting DDR2 Controller smoke test..." << std::endl;
    
    // Initialize inputs
    dut->clk = 0;
    dut->rst_n = 0;
    
    // Initialize AXI inputs to safe values
    dut->axi_awaddr = 0;
    dut->axi_awlen = 0;
    dut->axi_awsize = 0;
    dut->axi_awburst = 0;
    dut->axi_awvalid = 0;
    
    dut->axi_wdata = 0;
    dut->axi_wstrb = 0;
    dut->axi_wlast = 0;
    dut->axi_wvalid = 0;
    
    dut->axi_bready = 0;
    
    dut->axi_araddr = 0;
    dut->axi_arlen = 0;
    dut->axi_arsize = 0;
    dut->axi_arburst = 0;
    dut->axi_arvalid = 0;
    
    dut->axi_rready = 0;
    
    // Apply reset
    for (int i = 0; i < 10; i++) {
        dut->clk = 0;
        dut->eval();
        dut->clk = 1;
        dut->eval();
    }
    
    // Release reset
    dut->rst_n = 1;
    std::cout << "Reset released" << std::endl;
    
    // Run for some clock cycles
    for (int i = 0; i < 100; i++) {
        dut->clk = 0;
        dut->eval();
        dut->clk = 1;
        dut->eval();
        
        // Check some basic signals
        if (i == 50) {
            std::cout << "Cycle 50: ddr_cke = " << (int)dut->ddr_cke << std::endl;
            std::cout << "Cycle 50: ddr_cs_n = " << (int)dut->ddr_cs_n << std::endl;
        }
    }
    
    std::cout << "✅ Smoke test completed successfully!" << std::endl;
    std::cout << "Final state:" << std::endl;
    std::cout << "  ddr_cke = " << (int)dut->ddr_cke << std::endl;
    std::cout << "  ddr_cs_n = " << (int)dut->ddr_cs_n << std::endl;
    std::cout << "  axi_awready = " << (int)dut->axi_awready << std::endl;
    std::cout << "  axi_arready = " << (int)dut->axi_arready << std::endl;
    
    // Cleanup
    delete dut;
    return 0;
}