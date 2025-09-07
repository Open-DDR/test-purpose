//==============================================================================
// Simple DDR2 Memory Test Example
// 
// Description: Basic example showing how to use the DDR2 controller
// Author: Open DDR Project
// Date: 2025
//==============================================================================

`timescale 1ns/1ps

module simple_memory_test;

    // Parameters
    parameter DATA_WIDTH = 64;
    parameter ADDR_WIDTH = 32;
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

    // DDR2 Controller instantiation
    ddr2_controller #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) ddr2_ctrl (
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
        // DDR2 physical interface connections would go here
        .ddr_ck_p(),
        .ddr_ck_n(),
        .ddr_cke(),
        .ddr_cs_n(),
        .ddr_ras_n(),
        .ddr_cas_n(),
        .ddr_we_n(),
        .ddr_ba(),
        .ddr_a(),
        .ddr_dq(),
        .ddr_dqs_p(),
        .ddr_dqs_n(),
        .ddr_dm(),
        .ddr_odt()
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

    // Test sequence
    initial begin
        // Initialize all signals
        init_signals();
        
        // Wait for reset deassertion
        wait(rst_n);
        #(CLK_PERIOD * 10);
        
        $display("=== DDR2 Memory Test Started ===");
        
        // Test 1: Single word write and read
        test_single_write_read();
        
        // Test 2: Burst write and read
        test_burst_write_read();
        
        // Test 3: Multiple bank access
        test_multi_bank_access();
        
        $display("=== DDR2 Memory Test Completed ===");
        $finish;
    end

    // Initialize all AXI signals
    task init_signals();
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
    endtask

    // Test 1: Single word write and read
    task test_single_write_read();
        logic [DATA_WIDTH-1:0] test_data = 64'hDEADBEEFCAFEBABE;
        logic [ADDR_WIDTH-1:0] test_addr = 32'h00001000;
        
        $display("Test 1: Single word write and read");
        
        // Write operation
        write_single(test_addr, test_data);
        
        // Read operation
        read_single(test_addr);
        
        // Check data
        if (axi_rdata == test_data) begin
            $display("  PASS: Data matches (Expected: %h, Got: %h)", test_data, axi_rdata);
        end else begin
            $display("  FAIL: Data mismatch (Expected: %h, Got: %h)", test_data, axi_rdata);
        end
        
        #(CLK_PERIOD * 10);
    endtask

    // Test 2: Burst write and read
    task test_burst_write_read();
        logic [DATA_WIDTH-1:0] test_data [4];
        logic [ADDR_WIDTH-1:0] test_addr = 32'h00002000;
        int i;
        
        $display("Test 2: Burst write and read");
        
        // Prepare test data
        for (i = 0; i < 4; i++) begin
            test_data[i] = 64'h1111111111111111 + i;
        end
        
        // Burst write operation
        write_burst(test_addr, test_data, 4);
        
        // Burst read operation
        read_burst(test_addr, 4);
        
        $display("  Burst test completed");
        #(CLK_PERIOD * 10);
    endtask

    // Test 3: Multiple bank access
    task test_multi_bank_access();
        logic [ADDR_WIDTH-1:0] bank0_addr = 32'h00010000; // Bank 0
        logic [ADDR_WIDTH-1:0] bank1_addr = 32'h00020000; // Bank 1
        logic [DATA_WIDTH-1:0] bank0_data = 64'hAAAAAAAAAAAAAAAA;
        logic [DATA_WIDTH-1:0] bank1_data = 64'h5555555555555555;
        
        $display("Test 3: Multiple bank access");
        
        // Write to different banks
        write_single(bank0_addr, bank0_data);
        write_single(bank1_addr, bank1_data);
        
        // Read from different banks
        read_single(bank0_addr);
        read_single(bank1_addr);
        
        $display("  Multi-bank test completed");
        #(CLK_PERIOD * 10);
    endtask

    // Single write transaction
    task write_single(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        axi_awaddr = addr;
        axi_awlen = 0; // Single beat
        axi_awvalid = 1;
        axi_wdata = data;
        axi_wstrb = {(DATA_WIDTH/8){1'b1}}; // All bytes valid
        axi_wlast = 1;
        axi_wvalid = 1;
        
        @(posedge clk);
        wait(axi_awready);
        axi_awvalid = 0;
        wait(axi_wready);
        axi_wvalid = 0;
        axi_wlast = 0;
        wait(axi_bvalid);
        
        if (axi_bresp != 2'b00) begin
            $display("  WARNING: Write response error: %h", axi_bresp);
        end
    endtask

    // Single read transaction
    task read_single(input [ADDR_WIDTH-1:0] addr);
        axi_araddr = addr;
        axi_arlen = 0; // Single beat
        axi_arvalid = 1;
        
        @(posedge clk);
        wait(axi_arready);
        axi_arvalid = 0;
        wait(axi_rvalid);
        
        if (axi_rresp != 2'b00) begin
            $display("  WARNING: Read response error: %h", axi_rresp);
        end
    endtask

    // Burst write transaction
    task write_burst(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data[], input int length);
        int i;
        
        axi_awaddr = addr;
        axi_awlen = length - 1;
        axi_awvalid = 1;
        
        @(posedge clk);
        wait(axi_awready);
        axi_awvalid = 0;
        
        // Send data beats
        for (i = 0; i < length; i++) begin
            axi_wdata = data[i];
            axi_wstrb = {(DATA_WIDTH/8){1'b1}};
            axi_wlast = (i == length - 1);
            axi_wvalid = 1;
            @(posedge clk);
            wait(axi_wready);
            axi_wvalid = 0;
            if (i < length - 1) @(posedge clk);
        end
        
        wait(axi_bvalid);
    endtask

    // Burst read transaction
    task read_burst(input [ADDR_WIDTH-1:0] addr, input int length);
        int i;
        
        axi_araddr = addr;
        axi_arlen = length - 1;
        axi_arvalid = 1;
        
        @(posedge clk);
        wait(axi_arready);
        axi_arvalid = 0;
        
        // Receive data beats
        for (i = 0; i < length; i++) begin
            wait(axi_rvalid);
            $display("    Read data[%0d]: %h", i, axi_rdata);
            @(posedge clk);
        end
    endtask

    // Timeout watchdog
    initial begin
        #(CLK_PERIOD * 50000);
        $display("ERROR: Test timeout!");
        $finish;
    end

endmodule
