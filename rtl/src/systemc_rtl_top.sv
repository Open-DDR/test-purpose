//==============================================================================
// SystemC-RTL Top Level Integration
// 
// Description: Top-level module integrating SystemC model with RTL controller
// Author: Open DDR Project
// Date: 2025
//==============================================================================
`timescale 1ns/1ps

`include "openddr_pkg.sv"

module systemc_rtl_top #(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 40,
    parameter ID_WIDTH   = 12
) (
    // System Clock and Reset
    input  logic                    sys_clk,
    input  logic                    sys_rst_n,
    
    // External AXI Interface (from testbench or system)
    input  logic [ID_WIDTH-1:0]     ext_axi_awid,
    input  logic [ADDR_WIDTH-1:0]  ext_axi_awaddr,
    input  logic [7:0]              ext_axi_awlen,
    input  logic [2:0]              ext_axi_awsize,
    input  logic [1:0]              ext_axi_awburst,
    input  logic                    ext_axi_awvalid,
    output logic                    ext_axi_awready,
    
    input  logic [DATA_WIDTH-1:0]  ext_axi_wdata,
    input  logic [DATA_WIDTH/8-1:0] ext_axi_wstrb,
    input  logic                    ext_axi_wlast,
    input  logic                    ext_axi_wvalid,
    output logic                    ext_axi_wready,
    
    output logic [ID_WIDTH-1:0]     ext_axi_bid,
    output logic [1:0]              ext_axi_bresp,
    output logic                    ext_axi_bvalid,
    input  logic                    ext_axi_bready,
    
    input  logic [ID_WIDTH-1:0]     ext_axi_arid,
    input  logic [ADDR_WIDTH-1:0]  ext_axi_araddr,
    input  logic [7:0]              ext_axi_arlen,
    input  logic [2:0]              ext_axi_arsize,
    input  logic [1:0]              ext_axi_arburst,
    input  logic                    ext_axi_arvalid,
    output logic                    ext_axi_arready,
    
    output logic [ID_WIDTH-1:0]     ext_axi_rid,
    output logic [DATA_WIDTH-1:0]  ext_axi_rdata,
    output logic [1:0]              ext_axi_rresp,
    output logic                    ext_axi_rlast,
    output logic                    ext_axi_rvalid,
    input  logic                    ext_axi_rready,

    // External APB Interface
    input  logic                    ext_penable,
    input  logic                    ext_psel,
    input  logic                    ext_pwr,
    input  logic [9:0]              ext_paddr,
    input  logic [31:0]             ext_pwdata,
    output logic [31:0]             ext_prdata,
    output logic                    ext_pready,
    output logic                    ext_pslverr,
    
    // DDR Physical Interface
    output logic                    ddr_ck_p,
    output logic                    ddr_ck_n,
    output logic                    ddr_cke,
    output logic                    ddr_cs_n,
    output logic                    ddr_ras_n,
    output logic                    ddr_cas_n,
    output logic                    ddr_we_n,
    output logic [2:0]              ddr_ba,
    output logic [15:0]             ddr_a,
    inout  wire  [DATA_WIDTH-1:0]  ddr_dq,
    inout  wire  [DATA_WIDTH/8-1:0] ddr_dqs_p,
    inout  wire  [DATA_WIDTH/8-1:0] ddr_dqs_n,
    output logic [DATA_WIDTH/8-1:0] ddr_dm,
    output logic                    ddr_odt,
    
    // Control and Status
    output logic                    rtl_ready,
    output logic                    systemc_ready,
    input  logic                    mode_select  // 0: RTL mode, 1: SystemC mode
);

    import openddr_pkg::*;

    // Internal AXI buses
    logic [ID_WIDTH-1:0]     int_axi_awid;
    logic [ADDR_WIDTH-1:0]  int_axi_awaddr;
    logic [7:0]              int_axi_awlen;
    logic [2:0]              int_axi_awsize;
    logic [1:0]              int_axi_awburst;
    logic                    int_axi_awvalid;
    logic                    int_axi_awready;
    
    logic [DATA_WIDTH-1:0]  int_axi_wdata;
    logic [DATA_WIDTH/8-1:0] int_axi_wstrb;
    logic                    int_axi_wlast;
    logic                    int_axi_wvalid;
    logic                    int_axi_wready;
    
    logic [ID_WIDTH-1:0]     int_axi_bid;
    logic [1:0]              int_axi_bresp;
    logic                    int_axi_bvalid;
    logic                    int_axi_bready;
    
    logic [ID_WIDTH-1:0]     int_axi_arid;
    logic [ADDR_WIDTH-1:0]  int_axi_araddr;
    logic [7:0]              int_axi_arlen;
    logic [2:0]              int_axi_arsize;
    logic [1:0]              int_axi_arburst;
    logic                    int_axi_arvalid;
    logic                    int_axi_arready;
    
    logic [ID_WIDTH-1:0]     int_axi_rid;
    logic [DATA_WIDTH-1:0]  int_axi_rdata;
    logic [1:0]              int_axi_rresp;
    logic                    int_axi_rlast;
    logic                    int_axi_rvalid;
    logic                    int_axi_rready;

    // SystemC Interface signals (would connect to SystemC via DPI-C)
    logic                    sc_valid;
    logic [ADDR_WIDTH-1:0]  sc_addr;
    logic [DATA_WIDTH-1:0]  sc_wdata;
    logic [DATA_WIDTH/8-1:0] sc_wstrb;
    logic                    sc_we;
    logic [ID_WIDTH-1:0]     sc_id;
    logic [7:0]              sc_len;
    logic [DATA_WIDTH-1:0]  sc_rdata;
    logic                    sc_ready;
    logic                    sc_valid_out;

    // Mode selection multiplexer
    always_comb begin
        if (mode_select) begin
            // SystemC mode - route through SystemC interface
            int_axi_awid    = sc_id;
            int_axi_awaddr  = sc_addr;
            int_axi_awlen   = sc_len;
            int_axi_awsize  = 3'b011; // 8 bytes
            int_axi_awburst = 2'b01;   // INCR
            int_axi_awvalid = sc_valid && sc_we;
            
            int_axi_wdata   = sc_wdata;
            int_axi_wstrb   = sc_wstrb;
            int_axi_wlast   = 1'b1; // Single beat for simplicity
            int_axi_wvalid  = sc_valid && sc_we;
            int_axi_bready  = 1'b1;
            
            int_axi_arid    = sc_id;
            int_axi_araddr  = sc_addr;
            int_axi_arlen   = sc_len;
            int_axi_arsize  = 3'b011; // 8 bytes
            int_axi_arburst = 2'b01;   // INCR
            int_axi_arvalid = sc_valid && !sc_we;
            int_axi_rready  = 1'b1;
            
            // External interface outputs
            ext_axi_awready = sc_ready;
            ext_axi_wready  = sc_ready;
            ext_axi_bid     = sc_id;
            ext_axi_bresp   = 2'b00;
            ext_axi_bvalid  = sc_valid_out && sc_we;
            
            ext_axi_arready = sc_ready;
            ext_axi_rid     = sc_id;
            ext_axi_rdata   = sc_rdata;
            ext_axi_rresp   = 2'b00;
            ext_axi_rlast   = 1'b1;
            ext_axi_rvalid  = sc_valid_out && !sc_we;
        end else begin
            // RTL mode - direct connection
            int_axi_awid    = ext_axi_awid;
            int_axi_awaddr  = ext_axi_awaddr;
            int_axi_awlen   = ext_axi_awlen;
            int_axi_awsize  = ext_axi_awsize;
            int_axi_awburst = ext_axi_awburst;
            int_axi_awvalid = ext_axi_awvalid;
            
            int_axi_wdata   = ext_axi_wdata;
            int_axi_wstrb   = ext_axi_wstrb;
            int_axi_wlast   = ext_axi_wlast;
            int_axi_wvalid  = ext_axi_wvalid;
            int_axi_bready  = ext_axi_bready;
            
            int_axi_arid    = ext_axi_arid;
            int_axi_araddr  = ext_axi_araddr;
            int_axi_arlen   = ext_axi_arlen;
            int_axi_arsize  = ext_axi_arsize;
            int_axi_arburst = ext_axi_arburst;
            int_axi_arvalid = ext_axi_arvalid;
            int_axi_rready  = ext_axi_rready;
            
            // External interface outputs
            ext_axi_awready = int_axi_awready;
            ext_axi_wready  = int_axi_wready;
            ext_axi_bid     = int_axi_bid;
            ext_axi_bresp   = int_axi_bresp;
            ext_axi_bvalid  = int_axi_bvalid;
            
            ext_axi_arready = int_axi_arready;
            ext_axi_rid     = int_axi_rid;
            ext_axi_rdata   = int_axi_rdata;
            ext_axi_rresp   = int_axi_rresp;
            ext_axi_rlast   = int_axi_rlast;
            ext_axi_rvalid  = int_axi_rvalid;
        end
    end

    // SystemC-RTL Interface (for SystemC mode)
    systemc_rtl_interface #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) u_systemc_interface (
        .clk        (sys_clk),
        .rst_n      (sys_rst_n),
        .sc_valid   (sc_valid),
        .sc_addr    (sc_addr),
        .sc_wdata   (sc_wdata),
        .sc_wstrb   (sc_wstrb),
        .sc_we      (sc_we),
        .sc_id      (sc_id),
        .sc_len     (sc_len),
        .sc_rdata   (sc_rdata),
        .sc_ready   (sc_ready),
        .sc_valid_out(sc_valid_out),
        
        // Connect to internal AXI (when in SystemC mode)
        .axi_awid   (/* connected via mode select */),
        .axi_awaddr (/* connected via mode select */),
        .axi_awlen  (/* connected via mode select */),
        .axi_awsize (/* connected via mode select */),
        .axi_awburst(/* connected via mode select */),
        .axi_awvalid(/* connected via mode select */),
        .axi_awready(int_axi_awready),
        
        .axi_wdata  (/* connected via mode select */),
        .axi_wstrb  (/* connected via mode select */),
        .axi_wlast  (/* connected via mode select */),
        .axi_wvalid (/* connected via mode select */),
        .axi_wready (int_axi_wready),
        
        .axi_bid    (int_axi_bid),
        .axi_bresp  (int_axi_bresp),
        .axi_bvalid (int_axi_bvalid),
        .axi_bready (/* connected via mode select */),
        
        .axi_arid   (/* connected via mode select */),
        .axi_araddr (/* connected via mode select */),
        .axi_arlen  (/* connected via mode select */),
        .axi_arsize (/* connected via mode select */),
        .axi_arburst(/* connected via mode select */),
        .axi_arvalid(/* connected via mode select */),
        .axi_arready(int_axi_arready),
        
        .axi_rid    (int_axi_rid),
        .axi_rdata  (int_axi_rdata),
        .axi_rresp  (int_axi_rresp),
        .axi_rlast  (int_axi_rlast),
        .axi_rvalid (int_axi_rvalid),
        .axi_rready (/* connected via mode select */)
    );

    // OpenDDR Controller (RTL implementation)
    openddr_controller #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) u_openddr_controller (
        .mck                (sys_clk),
        .mc_rst_b          (sys_rst_n),
        .porst_b           (sys_rst_n),
        
        // AXI Interface
        .mc0_axi_awid      (int_axi_awid),
        .mc0_axi_awaddr    (int_axi_awaddr),
        .mc0_axi_awlen     (int_axi_awlen),
        .mc0_axi_awsize    (int_axi_awsize),
        .mc0_axi_awburst   (int_axi_awburst),
        .mc0_axi_awlock    (1'b0),
        .mc0_axi_awcache   (4'b0000),
        .mc0_axi_awprot    (3'b000),
        .mc0_axi_awqos     (4'b0000),
        .mc0_axi_awvalid   (int_axi_awvalid),
        .mc0_axi_awready   (int_axi_awready),
        
        .mc0_axi_wdata     (int_axi_wdata),
        .mc0_axi_wstrb     (int_axi_wstrb),
        .mc0_axi_wlast     (int_axi_wlast),
        .mc0_axi_wvalid    (int_axi_wvalid),
        .mc0_axi_wready    (int_axi_wready),
        
        .mc0_axi_bid       (int_axi_bid),
        .mc0_axi_bresp     (int_axi_bresp),
        .mc0_axi_bvalid    (int_axi_bvalid),
        .mc0_axi_bready    (int_axi_bready),
        
        .mc0_axi_arid      (int_axi_arid),
        .mc0_axi_araddr    (int_axi_araddr),
        .mc0_axi_arlen     (int_axi_arlen),
        .mc0_axi_arsize    (int_axi_arsize),
        .mc0_axi_arburst   (int_axi_arburst),
        .mc0_axi_arlock    (1'b0),
        .mc0_axi_arcache   (4'b0000),
        .mc0_axi_arprot    (3'b000),
        .mc0_axi_arqos     (4'b0000),
        .mc0_axi_arvalid   (int_axi_arvalid),
        .mc0_axi_arready   (int_axi_arready),
        
        .mc0_axi_rid       (int_axi_rid),
        .mc0_axi_rdata     (int_axi_rdata),
        .mc0_axi_rresp     (int_axi_rresp),
        .mc0_axi_rlast     (int_axi_rlast),
        .mc0_axi_rvalid    (int_axi_rvalid),
        .mc0_axi_rready    (int_axi_rready),
        
        // APB Interface
        .mc_penable        (ext_penable),
        .mc_psel           (ext_psel),
        .mc_pwr            (ext_pwr),
        .mc_paddr          (ext_paddr),
        .mc_pwdata         (ext_pwdata),
        .mc_prdata         (ext_prdata),
        .mc_pready         (ext_pready),
        .mc_pslverr        (ext_pslverr),
        
        // DDR Physical Interface
        .ddr_ck_p          (ddr_ck_p),
        .ddr_ck_n          (ddr_ck_n),
        .ddr_cke           (ddr_cke),
        .ddr_cs_n          (ddr_cs_n),
        .ddr_ras_n         (ddr_ras_n),
        .ddr_cas_n         (ddr_cas_n),
        .ddr_we_n          (ddr_we_n),
        .ddr_ba            (ddr_ba),
        .ddr_a             (ddr_a),
        .ddr_dq            (ddr_dq),
        .ddr_dqs_p         (ddr_dqs_p),
        .ddr_dqs_n         (ddr_dqs_n),
        .ddr_dm            (ddr_dm),
        .ddr_odt           (ddr_odt),
        
        // DFI Interface (internal to controller)
        .dfi_dram_clk_disable_0(),
        .dfi_dram_clk_disable_1(),
        .dfi_dram_ca_disable(),
        .dfi_cs_0_p0(),
        .dfi_cs_0_p1(),
        .dfi_cs_1_p2(),
        .dfi_cs_1_p3(),
        .dfi_address_0_p0(),
        .dfi_address_0_p1(),
        .dfi_address_1_p2(),
        .dfi_address_1_p3(),
        .dfi_reset_n(),
        
        .dfi_wrdata_0_p0(),
        .dfi_wrdata_0_p1(),
        .dfi_wrdata_1_p2(),
        .dfi_wrdata_1_p3(),
        .dfi_wrdata_mask_0_p0(),
        .dfi_wrdata_mask_0_p1(),
        .dfi_wrdata_mask_1_p2(),
        .dfi_wrdata_mask_1_p3(),
        .dfi_wrdata_en_0_p0(),
        .dfi_wrdata_en_0_p1(),
        .dfi_wrdata_en_1_p2(),
        .dfi_wrdata_en_1_p3(),
        
        .dfi_rddata_0_p0({DATA_WIDTH{1'b0}}),
        .dfi_rddata_0_p1({DATA_WIDTH{1'b0}}),
        .dfi_rddata_1_p2({DATA_WIDTH{1'b0}}),
        .dfi_rddata_1_p3({DATA_WIDTH{1'b0}}),
        .dfi_rddata_valid_0_p0(1'b0),
        .dfi_rddata_valid_0_p1(1'b0),
        .dfi_rddata_valid_1_p2(1'b0),
        .dfi_rddata_valid_1_p3(1'b0)
    );

    // Status outputs
    assign rtl_ready     = sys_rst_n;
    assign systemc_ready = sys_rst_n;

    // TODO: DPI-C interface for SystemC connection
    // This would include export/import functions to connect
    // sc_* signals to the SystemC model

endmodule
