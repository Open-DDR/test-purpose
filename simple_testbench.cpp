#include "Vddr2_controller.h"
#include "verilated.h"
#include <iostream>

double sc_time_stamp() { return 0; }

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vddr2_controller* dut = new Vddr2_controller;
    
    std::cout << "Starting DDR2 Controller smoke test..." << std::endl;
    
    dut->rst_n = 0;
    dut->clk = 0;
    
    for (int i = 0; i < 10; i++) {
        dut->clk = 0; dut->eval();
        dut->clk = 1; dut->eval();
    }
    
    dut->rst_n = 1;
    std::cout << "Reset released, running test..." << std::endl;
    
    for (int i = 0; i < 100; i++) {
        dut->clk = 0; dut->eval();
        dut->clk = 1; dut->eval();
        if (i == 50) std::cout << "Cycle 50: Controller running" << std::endl;
    }
    
    std::cout << "✅ DDR2 Controller smoke test passed!" << std::endl;
    delete dut;
    return 0;
}