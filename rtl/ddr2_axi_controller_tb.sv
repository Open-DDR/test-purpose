// ddr2_axi_controller_tb.sv
// Testbench for DDR2 AXI Controller

`timescale 1ns/1ps

module ddr2_axi_controller_tb;
    parameter ADDR_WIDTH = 28;
    parameter DATA_WIDTH = 32;
    parameter AXI_ID_WIDTH = 4;

    // Clock and reset
    reg ACLK = 0;
    reg ARESETN = 0;
    always #5 ACLK = ~ACLK; // 100MHz

    // AXI signals
    reg  [AXI_ID_WIDTH-1:0]  S_AXI_AWID;
    reg  [ADDR_WIDTH-1:0]    S_AXI_AWADDR;
    reg                      S_AXI_AWVALID;
    wire                     S_AXI_AWREADY;
    reg  [DATA_WIDTH-1:0]    S_AXI_WDATA;
    reg  [(DATA_WIDTH/8)-1:0] S_AXI_WSTRB;
    reg                      S_AXI_WVALID;
    wire                     S_AXI_WREADY;
    wire [1:0]               S_AXI_BRESP;
    wire                     S_AXI_BVALID;
    reg                      S_AXI_BREADY;
    reg  [AXI_ID_WIDTH-1:0]  S_AXI_ARID;
    reg  [ADDR_WIDTH-1:0]    S_AXI_ARADDR;
    reg                      S_AXI_ARVALID;
    wire                     S_AXI_ARREADY;
    wire [DATA_WIDTH-1:0]    S_AXI_RDATA;
    wire [1:0]               S_AXI_RRESP;
    wire                     S_AXI_RVALID;
    reg                      S_AXI_RREADY;

    // DDR2 signals (stubbed)
    wire [ADDR_WIDTH-1:0]    ddr2_addr;
    wire [2:0]               ddr2_ba;
    wire                     ddr2_ras_n;
    wire                     ddr2_cas_n;
    wire                     ddr2_we_n;
    wire                     ddr2_cs_n;
    wire                     ddr2_cke;
    wire                     ddr2_odt;
    wire                     ddr2_reset_n;
    wire [15:0]              ddr2_dq;
    wire [1:0]               ddr2_dqs;
    wire [1:0]               ddr2_dm;
    wire                     ddr2_clk;
    wire                     ddr2_clk_n;

    // Instantiate DUT
    ddr2_axi_controller #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .AXI_ID_WIDTH(AXI_ID_WIDTH)
    ) dut (
        .ACLK(ACLK),
        .ARESETN(ARESETN),
        .S_AXI_AWID(S_AXI_AWID),
        .S_AXI_AWADDR(S_AXI_AWADDR),
        .S_AXI_AWVALID(S_AXI_AWVALID),
        .S_AXI_AWREADY(S_AXI_AWREADY),
        .S_AXI_WDATA(S_AXI_WDATA),
        .S_AXI_WSTRB(S_AXI_WSTRB),
        .S_AXI_WVALID(S_AXI_WVALID),
        .S_AXI_WREADY(S_AXI_WREADY),
        .S_AXI_BRESP(S_AXI_BRESP),
        .S_AXI_BVALID(S_AXI_BVALID),
        .S_AXI_BREADY(S_AXI_BREADY),
        .S_AXI_ARID(S_AXI_ARID),
        .S_AXI_ARADDR(S_AXI_ARADDR),
        .S_AXI_ARVALID(S_AXI_ARVALID),
        .S_AXI_ARREADY(S_AXI_ARREADY),
        .S_AXI_RDATA(S_AXI_RDATA),
        .S_AXI_RRESP(S_AXI_RRESP),
        .S_AXI_RVALID(S_AXI_RVALID),
        .S_AXI_RREADY(S_AXI_RREADY),
        .ddr2_addr(ddr2_addr),
        .ddr2_ba(ddr2_ba),
        .ddr2_ras_n(ddr2_ras_n),
        .ddr2_cas_n(ddr2_cas_n),
        .ddr2_we_n(ddr2_we_n),
        .ddr2_cs_n(ddr2_cs_n),
        .ddr2_cke(ddr2_cke),
        .ddr2_odt(ddr2_odt),
        .ddr2_reset_n(ddr2_reset_n),
        .ddr2_dq(ddr2_dq),
        .ddr2_dqs(ddr2_dqs),
        .ddr2_dm(ddr2_dm),
        .ddr2_clk(ddr2_clk),
        .ddr2_clk_n(ddr2_clk_n)
    );

    // Simple DDR2 stub (no memory model)
    assign ddr2_dq = 16'hzzzz;
    assign ddr2_dqs = 2'bzz;

    // Test sequence  
    reg bvalid_seen = 0;
    reg rvalid_seen = 0;
    
    always @(posedge ACLK) begin
        if (S_AXI_BVALID) bvalid_seen <= 1;
        if (S_AXI_RVALID) rvalid_seen <= 1;
    end
    
    initial begin
        integer wait_count;
        
        // Reset
        ARESETN = 0;
        S_AXI_AWID = 0;
        S_AXI_AWADDR = 0;
        S_AXI_AWVALID = 0;
        S_AXI_WDATA = 0;
        S_AXI_WSTRB = 4'hF;
        S_AXI_WVALID = 0;
        S_AXI_BREADY = 1;
        S_AXI_ARID = 0;
        S_AXI_ARADDR = 0;
        S_AXI_ARVALID = 0;
        S_AXI_RREADY = 1;
        #100;
        ARESETN = 1;
        #50;
        // Write transaction
        S_AXI_AWADDR = 28'h000_1000;
        S_AXI_AWVALID = 1;
        S_AXI_WDATA = 32'hDEADBEEF;
        S_AXI_WVALID = 1;
        #10;
        S_AXI_AWVALID = 0;
        S_AXI_WVALID = 0;
        // Wait for write response
        bvalid_seen = 0;
        wait_count = 0;
        while (!bvalid_seen && wait_count < 1000) begin
            #10;
            wait_count = wait_count + 1;
        end
        #10;
        // Read transaction
        S_AXI_ARADDR = 28'h000_1000;
        S_AXI_ARVALID = 1;
        #10;
        S_AXI_ARVALID = 0;
        // Wait for read data
        rvalid_seen = 0;
        wait_count = 0;
        while (!rvalid_seen && wait_count < 1000) begin
            #10;
            wait_count = wait_count + 1;
        end
        #10;
        $display("Read Data: %h", S_AXI_RDATA);
        #100;
        $finish;
    end
endmodule
