//==============================================================================
// DDR2 Controller Testbench
// 
// Description: Unit test for DDR2 memory controller
// Author: Open DDR Project
// Date: 2025
//==============================================================================

`timescale 1ns/1ps

module tb_ddr2_controller;

    // Parameters
    parameter DATA_WIDTH = 64;
    parameter ADDR_WIDTH = 32;
    parameter BANK_WIDTH = 3;
    parameter ROW_WIDTH  = 14;
    parameter COL_WIDTH  = 10;
    parameter CLK_PERIOD = 10; // 100MHz

    // Clock and Reset
    logic clk;
    logic rst_n;
    
    // AXI4 Interface signals
    logic [ADDR_WIDTH-1:0]  axi_awaddr;
    logic [7:0]             axi_awlen;
    logic [2:0]             axi_awsize;
    logic [1:0]             axi_awburst;
    logic                   axi_awvalid;
    logic                   axi_awready;
    
    logic [DATA_WIDTH-1:0]  axi_wdata;
    logic [DATA_WIDTH/8-1:0] axi_wstrb;
    logic                   axi_wlast;
    logic                   axi_wvalid;
    logic                   axi_wready;
    
    logic [1:0]             axi_bresp;
    logic                   axi_bvalid;
    logic                   axi_bready;
    
    logic [ADDR_WIDTH-1:0]  axi_araddr;
    logic [7:0]             axi_arlen;
    logic [2:0]             axi_arsize;
    logic [1:0]             axi_arburst;
    logic                   axi_arvalid;
    logic                   axi_arready;
    
    logic [DATA_WIDTH-1:0]  axi_rdata;
    logic [1:0]             axi_rresp;
    logic                   axi_rlast;
    logic                   axi_rvalid;
    logic                   axi_rready;
    
    // DDR2 Physical Interface
    logic                   ddr_ck_p;
    logic                   ddr_ck_n;
    logic                   ddr_cke;
    logic                   ddr_cs_n;
    logic                   ddr_ras_n;
    logic                   ddr_cas_n;
    logic                   ddr_we_n;
    logic [BANK_WIDTH-1:0]  ddr_ba;
    logic [ROW_WIDTH-1:0]   ddr_a;
    wire  [DATA_WIDTH-1:0]  ddr_dq;
    wire  [DATA_WIDTH/8-1:0] ddr_dqs_p;
    wire  [DATA_WIDTH/8-1:0] ddr_dqs_n;
    logic [DATA_WIDTH/8-1:0] ddr_dm;
    logic                   ddr_odt;

    // DUT instantiation
    ddr2_controller #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .BANK_WIDTH(BANK_WIDTH),
        .ROW_WIDTH(ROW_WIDTH),
        .COL_WIDTH(COL_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .axi_awaddr(axi_awaddr),
        .axi_awlen(axi_awlen),
        .axi_awsize(axi_awsize),
        .axi_awburst(axi_awburst),
        .axi_awvalid(axi_awvalid),
        .axi_awready(axi_awready),
        .axi_wdata(axi_wdata),
        .axi_wstrb(axi_wstrb),
        .axi_wlast(axi_wlast),
        .axi_wvalid(axi_wvalid),
        .axi_wready(axi_wready),
        .axi_bresp(axi_bresp),
        .axi_bvalid(axi_bvalid),
        .axi_bready(axi_bready),
        .axi_araddr(axi_araddr),
        .axi_arlen(axi_arlen),
        .axi_arsize(axi_arsize),
        .axi_arburst(axi_arburst),
        .axi_arvalid(axi_arvalid),
        .axi_arready(axi_arready),
        .axi_rdata(axi_rdata),
        .axi_rresp(axi_rresp),
        .axi_rlast(axi_rlast),
        .axi_rvalid(axi_rvalid),
        .axi_rready(axi_rready),
        .ddr_ck_p(ddr_ck_p),
        .ddr_ck_n(ddr_ck_n),
        .ddr_cke(ddr_cke),
        .ddr_cs_n(ddr_cs_n),
        .ddr_ras_n(ddr_ras_n),
        .ddr_cas_n(ddr_cas_n),
        .ddr_we_n(ddr_we_n),
        .ddr_ba(ddr_ba),
        .ddr_a(ddr_a),
        .ddr_dq(ddr_dq),
        .ddr_dqs_p(ddr_dqs_p),
        .ddr_dqs_n(ddr_dqs_n),
        .ddr_dm(ddr_dm),
        .ddr_odt(ddr_odt)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Reset generation
    initial begin
        rst_n = 0;
        #(CLK_PERIOD * 10);
        rst_n = 1;
    end

    // Test stimulus
    initial begin
        // Initialize signals
        axi_awaddr = 0;
        axi_awlen = 0;
        axi_awsize = 3'b011; // 8 bytes
        axi_awburst = 2'b01; // INCR
        axi_awvalid = 0;
        axi_wdata = 0;
        axi_wstrb = 0;
        axi_wlast = 0;
        axi_wvalid = 0;
        axi_bready = 1;
        axi_araddr = 0;
        axi_arlen = 0;
        axi_arsize = 3'b011; // 8 bytes
        axi_arburst = 2'b01; // INCR
        axi_arvalid = 0;
        axi_rready = 1;

        // Wait for reset deassertion
        wait(rst_n);
        #(CLK_PERIOD * 10);

        // Test 1: Simple write transaction
        $display("Test 1: Simple write transaction");
        axi_awaddr = 32'h1000;
        axi_awlen = 0; // Single beat
        axi_awvalid = 1;
        axi_wdata = 64'hDEADBEEFCAFEBABE;
        axi_wstrb = 8'hFF;
        axi_wlast = 1;
        axi_wvalid = 1;
        
        @(posedge clk);
        wait(axi_awready);
        axi_awvalid = 0;
        wait(axi_wready);
        axi_wvalid = 0;
        axi_wlast = 0;
        wait(axi_bvalid);
        
        $display("Write transaction completed with response: %h", axi_bresp);
        #(CLK_PERIOD * 10);

        // Test 2: Simple read transaction
        $display("Test 2: Simple read transaction");
        axi_araddr = 32'h1000;
        axi_arlen = 0; // Single beat
        axi_arvalid = 1;
        
        @(posedge clk);
        wait(axi_arready);
        axi_arvalid = 0;
        wait(axi_rvalid);
        
        $display("Read transaction completed with data: %h, response: %h", axi_rdata, axi_rresp);
        #(CLK_PERIOD * 10);

        // Test 3: Burst write transaction
        $display("Test 3: Burst write transaction");
        axi_awaddr = 32'h2000;
        axi_awlen = 3; // 4 beats
        axi_awvalid = 1;
        
        @(posedge clk);
        wait(axi_awready);
        axi_awvalid = 0;
        
        // Send 4 data beats
        for (int i = 0; i < 4; i++) begin
            axi_wdata = 64'h1111111111111111 + i;
            axi_wstrb = 8'hFF;
            axi_wlast = (i == 3);
            axi_wvalid = 1;
            @(posedge clk);
            wait(axi_wready);
            axi_wvalid = 0;
            if (i < 3) @(posedge clk);
        end
        
        wait(axi_bvalid);
        $display("Burst write transaction completed");
        #(CLK_PERIOD * 10);

        $display("All tests completed successfully!");
        $finish;
    end

    // Monitor DDR2 interface
    initial begin
        $monitor("Time: %t, DDR2 - CKE: %b, CS_N: %b, RAS_N: %b, CAS_N: %b, WE_N: %b, BA: %h, A: %h", 
                 $time, ddr_cke, ddr_cs_n, ddr_ras_n, ddr_cas_n, ddr_we_n, ddr_ba, ddr_a);
    end

    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * 10000);
        $display("ERROR: Testbench timeout!");
        $finish;
    end

endmodule
