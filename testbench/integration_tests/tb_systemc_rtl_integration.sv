//==============================================================================
// SystemC-RTL Integration Testbench
// 
// Description: Testbench for SystemC-RTL integration
// Author: Open DDR Project
// Date: 2025
//==============================================================================

`include "openddr_pkg.sv"

module tb_systemc_rtl_integration;

    import openddr_pkg::*;

    // Parameters
    parameter DATA_WIDTH = 64;
    parameter ADDR_WIDTH = 40;
    parameter ID_WIDTH   = 12;
    parameter CLK_PERIOD = 10ns;

    // Test signals
    logic                    sys_clk;
    logic                    sys_rst_n;
    
    // AXI Interface
    logic [ID_WIDTH-1:0]     ext_axi_awid;
    logic [ADDR_WIDTH-1:0]  ext_axi_awaddr;
    logic [7:0]              ext_axi_awlen;
    logic [2:0]              ext_axi_awsize;
    logic [1:0]              ext_axi_awburst;
    logic                    ext_axi_awvalid;
    logic                    ext_axi_awready;
    
    logic [DATA_WIDTH-1:0]  ext_axi_wdata;
    logic [DATA_WIDTH/8-1:0] ext_axi_wstrb;
    logic                    ext_axi_wlast;
    logic                    ext_axi_wvalid;
    logic                    ext_axi_wready;
    
    logic [ID_WIDTH-1:0]     ext_axi_bid;
    logic [1:0]              ext_axi_bresp;
    logic                    ext_axi_bvalid;
    logic                    ext_axi_bready;
    
    logic [ID_WIDTH-1:0]     ext_axi_arid;
    logic [ADDR_WIDTH-1:0]  ext_axi_araddr;
    logic [7:0]              ext_axi_arlen;
    logic [2:0]              ext_axi_arsize;
    logic [1:0]              ext_axi_arburst;
    logic                    ext_axi_arvalid;
    logic                    ext_axi_arready;
    
    logic [ID_WIDTH-1:0]     ext_axi_rid;
    logic [DATA_WIDTH-1:0]  ext_axi_rdata;
    logic [1:0]              ext_axi_rresp;
    logic                    ext_axi_rlast;
    logic                    ext_axi_rvalid;
    logic                    ext_axi_rready;

    // APB Interface
    logic                    ext_penable;
    logic                    ext_psel;
    logic                    ext_pwr;
    logic [9:0]              ext_paddr;
    logic [31:0]             ext_pwdata;
    logic [31:0]             ext_prdata;
    logic                    ext_pready;
    logic                    ext_pslverr;
    
    // DDR Interface
    logic                    ddr_ck_p, ddr_ck_n;
    logic                    ddr_cke, ddr_cs_n;
    logic                    ddr_ras_n, ddr_cas_n, ddr_we_n;
    logic [2:0]              ddr_ba;
    logic [15:0]             ddr_a;
    wire  [DATA_WIDTH-1:0]  ddr_dq;
    wire  [DATA_WIDTH/8-1:0] ddr_dqs_p, ddr_dqs_n;
    logic [DATA_WIDTH/8-1:0] ddr_dm;
    logic                    ddr_odt;
    
    // Control
    logic                    rtl_ready;
    logic                    systemc_ready;
    logic                    mode_select;

    // Clock generation
    always #(CLK_PERIOD/2) sys_clk = ~sys_clk;

    // DUT instantiation
    systemc_rtl_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) dut (
        .sys_clk        (sys_clk),
        .sys_rst_n      (sys_rst_n),
        
        .ext_axi_awid   (ext_axi_awid),
        .ext_axi_awaddr (ext_axi_awaddr),
        .ext_axi_awlen  (ext_axi_awlen),
        .ext_axi_awsize (ext_axi_awsize),
        .ext_axi_awburst(ext_axi_awburst),
        .ext_axi_awvalid(ext_axi_awvalid),
        .ext_axi_awready(ext_axi_awready),
        
        .ext_axi_wdata  (ext_axi_wdata),
        .ext_axi_wstrb  (ext_axi_wstrb),
        .ext_axi_wlast  (ext_axi_wlast),
        .ext_axi_wvalid (ext_axi_wvalid),
        .ext_axi_wready (ext_axi_wready),
        
        .ext_axi_bid    (ext_axi_bid),
        .ext_axi_bresp  (ext_axi_bresp),
        .ext_axi_bvalid (ext_axi_bvalid),
        .ext_axi_bready (ext_axi_bready),
        
        .ext_axi_arid   (ext_axi_arid),
        .ext_axi_araddr (ext_axi_araddr),
        .ext_axi_arlen  (ext_axi_arlen),
        .ext_axi_arsize (ext_axi_arsize),
        .ext_axi_arburst(ext_axi_arburst),
        .ext_axi_arvalid(ext_axi_arvalid),
        .ext_axi_arready(ext_axi_arready),
        
        .ext_axi_rid    (ext_axi_rid),
        .ext_axi_rdata  (ext_axi_rdata),
        .ext_axi_rresp  (ext_axi_rresp),
        .ext_axi_rlast  (ext_axi_rlast),
        .ext_axi_rvalid (ext_axi_rvalid),
        .ext_axi_rready (ext_axi_rready),
        
        .ext_penable    (ext_penable),
        .ext_psel       (ext_psel),
        .ext_pwr        (ext_pwr),
        .ext_paddr      (ext_paddr),
        .ext_pwdata     (ext_pwdata),
        .ext_prdata     (ext_prdata),
        .ext_pready     (ext_pready),
        .ext_pslverr    (ext_pslverr),
        
        .ddr_ck_p       (ddr_ck_p),
        .ddr_ck_n       (ddr_ck_n),
        .ddr_cke        (ddr_cke),
        .ddr_cs_n       (ddr_cs_n),
        .ddr_ras_n      (ddr_ras_n),
        .ddr_cas_n      (ddr_cas_n),
        .ddr_we_n       (ddr_we_n),
        .ddr_ba         (ddr_ba),
        .ddr_a          (ddr_a),
        .ddr_dq         (ddr_dq),
        .ddr_dqs_p      (ddr_dqs_p),
        .ddr_dqs_n      (ddr_dqs_n),
        .ddr_dm         (ddr_dm),
        .ddr_odt        (ddr_odt),
        
        .rtl_ready      (rtl_ready),
        .systemc_ready  (systemc_ready),
        .mode_select    (mode_select)
    );

    // Test tasks
    task reset_system();
        sys_rst_n = 1'b0;
        repeat(10) @(posedge sys_clk);
        sys_rst_n = 1'b1;
        repeat(10) @(posedge sys_clk);
        $display("System reset completed at time %0t", $time);
    endtask

    task axi_write(input logic [ADDR_WIDTH-1:0] addr, 
                   input logic [DATA_WIDTH-1:0] data,
                   input logic [ID_WIDTH-1:0] id = 0);
        @(posedge sys_clk);
        
        // Write address
        ext_axi_awid = id;
        ext_axi_awaddr = addr;
        ext_axi_awlen = 0; // Single beat
        ext_axi_awsize = 3'b011; // 8 bytes
        ext_axi_awburst = 2'b01; // INCR
        ext_axi_awvalid = 1'b1;
        
        // Write data
        ext_axi_wdata = data;
        ext_axi_wstrb = {(DATA_WIDTH/8){1'b1}};
        ext_axi_wlast = 1'b1;
        ext_axi_wvalid = 1'b1;
        ext_axi_bready = 1'b1;
        
        // Wait for ready
        wait(ext_axi_awready && ext_axi_wready);
        @(posedge sys_clk);
        
        ext_axi_awvalid = 1'b0;
        ext_axi_wvalid = 1'b0;
        
        // Wait for response
        wait(ext_axi_bvalid);
        @(posedge sys_clk);
        ext_axi_bready = 1'b0;
        
        $display("AXI Write: Addr=0x%h, Data=0x%h, ID=%0d at time %0t", 
                 addr, data, id, $time);
    endtask

    task axi_read(input logic [ADDR_WIDTH-1:0] addr,
                  output logic [DATA_WIDTH-1:0] data,
                  input logic [ID_WIDTH-1:0] id = 0);
        @(posedge sys_clk);
        
        // Read address
        ext_axi_arid = id;
        ext_axi_araddr = addr;
        ext_axi_arlen = 0; // Single beat
        ext_axi_arsize = 3'b011; // 8 bytes
        ext_axi_arburst = 2'b01; // INCR
        ext_axi_arvalid = 1'b1;
        ext_axi_rready = 1'b1;
        
        // Wait for ready
        wait(ext_axi_arready);
        @(posedge sys_clk);
        
        ext_axi_arvalid = 1'b0;
        
        // Wait for data
        wait(ext_axi_rvalid);
        data = ext_axi_rdata;
        @(posedge sys_clk);
        ext_axi_rready = 1'b0;
        
        $display("AXI Read: Addr=0x%h, Data=0x%h, ID=%0d at time %0t", 
                 addr, data, id, $time);
    endtask

    task apb_write(input logic [9:0] addr, input logic [31:0] data);
        @(posedge sys_clk);
        
        ext_psel = 1'b1;
        ext_pwr = 1'b1;
        ext_paddr = addr;
        ext_pwdata = data;
        
        @(posedge sys_clk);
        ext_penable = 1'b1;
        
        wait(ext_pready);
        @(posedge sys_clk);
        
        ext_psel = 1'b0;
        ext_penable = 1'b0;
        ext_pwr = 1'b0;
        
        $display("APB Write: Addr=0x%h, Data=0x%h at time %0t", addr, data, $time);
    endtask

    task apb_read(input logic [9:0] addr, output logic [31:0] data);
        @(posedge sys_clk);
        
        ext_psel = 1'b1;
        ext_pwr = 1'b0;
        ext_paddr = addr;
        
        @(posedge sys_clk);
        ext_penable = 1'b1;
        
        wait(ext_pready);
        data = ext_prdata;
        @(posedge sys_clk);
        
        ext_psel = 1'b0;
        ext_penable = 1'b0;
        
        $display("APB Read: Addr=0x%h, Data=0x%h at time %0t", addr, data, $time);
    endtask

    // Main test sequence
    initial begin
        logic [DATA_WIDTH-1:0] read_data;
        logic [31:0] config_data;
        
        $display("Starting SystemC-RTL Integration Test");
        
        // Initialize signals
        sys_clk = 1'b0;
        sys_rst_n = 1'b0;
        mode_select = 1'b0; // Start in RTL mode
        
        // Initialize AXI signals
        ext_axi_awvalid = 1'b0;
        ext_axi_wvalid = 1'b0;
        ext_axi_bready = 1'b0;
        ext_axi_arvalid = 1'b0;
        ext_axi_rready = 1'b0;
        
        // Initialize APB signals
        ext_penable = 1'b0;
        ext_psel = 1'b0;
        ext_pwr = 1'b0;
        
        // Reset system
        reset_system();
        
        $display("\n=== RTL Mode Testing ===");
        mode_select = 1'b0;
        
        // Configure the controller
        apb_write(10'h000, 32'h00000001); // Enable controller
        apb_write(10'h004, 32'h00030000); // DDR config
        
        // Read back configuration
        apb_read(10'h000, config_data);
        apb_read(10'h004, config_data);
        
        // AXI memory operations
        axi_write(40'h00001000, 64'hDEADBEEFCAFEBABE, 12'h001);
        axi_write(40'h00002000, 64'h1234567890ABCDEF, 12'h002);
        
        axi_read(40'h00001000, read_data, 12'h001);
        axi_read(40'h00002000, read_data, 12'h002);
        
        $display("\n=== SystemC Mode Testing ===");
        mode_select = 1'b1;
        
        // In a real implementation, SystemC would drive sc_* signals
        // For this testbench, we simulate basic functionality
        
        repeat(100) @(posedge sys_clk);
        
        $display("\n=== Test Complete ===");
        $display("RTL Ready: %b", rtl_ready);
        $display("SystemC Ready: %b", systemc_ready);
        
        $finish;
    end

    // Timeout
    initial begin
        #1ms;
        $display("ERROR: Test timeout");
        $finish;
    end

    // Waveform dumping
    initial begin
        $dumpfile("systemc_rtl_integration.vcd");
        $dumpvars(0, tb_systemc_rtl_integration);
    end

endmodule
