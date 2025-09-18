#include "Vddr2_axi_controller.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    Vddr2_axi_controller* top = new Vddr2_axi_controller;
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("wave.vcd");

    // Reset
    top->ARESETN = 0;
    top->ACLK = 0;
    for (int i = 0; i < 5; ++i) {
        top->ACLK = !top->ACLK;
        top->eval();
        tfp->dump(i);
    }
    top->ARESETN = 1;

    // Simple clock and run loop
    for (int i = 5; i < 105; ++i) {
        top->ACLK = !top->ACLK;
        top->eval();
        tfp->dump(i);
    }

    tfp->close();
    delete tfp;
    delete top;
    return 0;
}
