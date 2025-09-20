#include "Vddr2_axi_controller.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

// Required by Verilator
vluint64_t main_time = 0;
double sc_time_stamp() {
    return main_time;
}

#ifdef TIMING_VIOLATION_TEST
int main(int argc, char** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    
    // Create instance of our design
    Vddr2_axi_controller* ddr_controller = new Vddr2_axi_controller;
    
    // Initialize tracing
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = nullptr;
    if (argc > 1 && std::string(argv[1]) == "+dump") {
        tfp = new VerilatedVcdC;
        ddr_controller->trace(tfp, 99);
        tfp->open("ddr2_controller_violation.vcd");
    }
    
    // Initialize inputs
    ddr_controller->axi_aclk = 0;
    ddr_controller->axi_aresetn = 0;
    ddr_controller->ddr_clk = 0;
    ddr_controller->ddr_rst_n = 0;
    ddr_controller->s_axi_awvalid = 0;
    ddr_controller->s_axi_arvalid = 0;
    ddr_controller->s_axi_wvalid = 0;
    ddr_controller->s_axi_bready = 1;
    ddr_controller->s_axi_rready = 1;
    
    // Reset sequence
    for (int i = 0; i < 10; i++) {
        ddr_controller->axi_aclk = 0;
        ddr_controller->ddr_clk = 0;
        ddr_controller->eval();
        if (tfp) tfp->dump(main_time);
        main_time++;
        
        ddr_controller->axi_aclk = 1;
        ddr_controller->ddr_clk = 1;
        ddr_controller->eval();
        if (tfp) tfp->dump(main_time);
        main_time++;
    }
    
    // Release reset
    ddr_controller->axi_aresetn = 1;
    ddr_controller->ddr_rst_n = 1;
    
    printf("========================================\n");
    printf("DDR2 AXI Controller - Timing Violation Test\n");
    printf("========================================\n");
    
#ifdef TFAW_VIOLATION
    printf("TFAW violation test enabled\n");
#endif
#ifdef TRCD_VIOLATION  
    printf("TRCD violation test enabled\n");
#endif
#ifdef TRP_VIOLATION
    printf("TRP violation test enabled\n");
#endif
#ifdef TRAS_VIOLATION
    printf("TRAS violation test enabled\n");
#endif
    
    // Run simulation for a few cycles to trigger violation detection
    for (int cycle = 0; cycle < 100; cycle++) {
        // Generate some AXI transactions to trigger violations
        if (cycle == 20) {
            ddr_controller->s_axi_awvalid = 1;
            ddr_controller->s_axi_awaddr = 0x1000;
            ddr_controller->s_axi_awlen = 0;
            ddr_controller->s_axi_awsize = 3; // 64-bit transfers
            ddr_controller->s_axi_awburst = 1; // INCR
            printf("Starting write transaction at cycle %d\n", cycle);
        }
        
        if (cycle == 25) {
            ddr_controller->s_axi_awvalid = 0;
            ddr_controller->s_axi_wvalid = 1;
            ddr_controller->s_axi_wlast = 1;
            ddr_controller->s_axi_wdata = 0xDEADBEEFCAFEBABE;
        }
        
        if (cycle == 30) {
            ddr_controller->s_axi_wvalid = 0;
        }
        
        if (cycle == 40) {
            ddr_controller->s_axi_arvalid = 1;
            ddr_controller->s_axi_araddr = 0x2000;
            ddr_controller->s_axi_arlen = 0;
            ddr_controller->s_axi_arsize = 3;
            ddr_controller->s_axi_arburst = 1;
            printf("Starting read transaction at cycle %d\n", cycle);
        }
        
        if (cycle == 45) {
            ddr_controller->s_axi_arvalid = 0;
        }
        
        // Clock edges
        ddr_controller->axi_aclk = 0;
        ddr_controller->ddr_clk = 0;
        ddr_controller->eval();
        if (tfp) tfp->dump(main_time);
        main_time++;
        
        ddr_controller->axi_aclk = 1;
        ddr_controller->ddr_clk = 1;
        ddr_controller->eval();
        if (tfp) tfp->dump(main_time);
        main_time++;
    }
    
    printf("Simulation completed after 100 cycles\n");
    printf("Check console output for timing violation messages\n");
    if (tfp) {
        printf("VCD trace saved to: ddr2_controller_violation.vcd\n");
        tfp->close();
        delete tfp;
    }
    
    delete ddr_controller;
    return 0;
}
#else
// Default main for non-violation tests
int main(int argc, char** argv, char** env) {
    printf("This is a timing violation test. Define TIMING_VIOLATION_TEST to enable.\n");
    return 0;
}
#endif