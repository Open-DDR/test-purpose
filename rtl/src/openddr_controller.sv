//==============================================================================
// OpenDDR Memory Controller
// 
// Description: Top-level DDR memory controller module interfacing with SystemC
// Author: Open DDR Project
// Date: 2025
//==============================================================================

`include "openddr_pkg.sv"

module openddr_controller #(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 40,
    parameter ID_WIDTH   = 12,
    parameter BANK_WIDTH = 3,
    parameter ROW_WIDTH  = 16,
    parameter COL_WIDTH  = 10
) (
    // Clock and Reset
    input  logic                    mck,
    input  logic                    mc_rst_b,
    input  logic                    porst_b,
    
    // AXI4 Interface (matches SystemC interface)
    input  logic [ID_WIDTH-1:0]     mc0_axi_awid,
    input  logic [ADDR_WIDTH-1:0]  mc0_axi_awaddr,
    input  logic [7:0]              mc0_axi_awlen,
    input  logic [2:0]              mc0_axi_awsize,
    input  logic [1:0]              mc0_axi_awburst,
    input  logic                    mc0_axi_awlock,
    input  logic [3:0]              mc0_axi_awcache,
    input  logic [2:0]              mc0_axi_awprot,
    input  logic [3:0]              mc0_axi_awqos,
    input  logic                    mc0_axi_awvalid,
    output logic                    mc0_axi_awready,
    
    input  logic [DATA_WIDTH-1:0]  mc0_axi_wdata,
    input  logic [DATA_WIDTH/8-1:0] mc0_axi_wstrb,
    input  logic                    mc0_axi_wlast,
    input  logic                    mc0_axi_wvalid,
    output logic                    mc0_axi_wready,
    
    output logic [ID_WIDTH-1:0]     mc0_axi_bid,
    output logic [1:0]              mc0_axi_bresp,
    output logic                    mc0_axi_bvalid,
    input  logic                    mc0_axi_bready,
    
    input  logic [ID_WIDTH-1:0]     mc0_axi_arid,
    input  logic [ADDR_WIDTH-1:0]  mc0_axi_araddr,
    input  logic [7:0]              mc0_axi_arlen,
    input  logic [2:0]              mc0_axi_arsize,
    input  logic [1:0]              mc0_axi_arburst,
    input  logic                    mc0_axi_arlock,
    input  logic [3:0]              mc0_axi_arcache,
    input  logic [2:0]              mc0_axi_arprot,
    input  logic [3:0]              mc0_axi_arqos,
    input  logic                    mc0_axi_arvalid,
    output logic                    mc0_axi_arready,
    
    output logic [ID_WIDTH-1:0]     mc0_axi_rid,
    output logic [DATA_WIDTH-1:0]  mc0_axi_rdata,
    output logic [1:0]              mc0_axi_rresp,
    output logic                    mc0_axi_rlast,
    output logic                    mc0_axi_rvalid,
    input  logic                    mc0_axi_rready,

    // APB Configuration Interface
    input  logic                    mc_penable,
    input  logic                    mc_psel,
    input  logic                    mc_pwr,
    input  logic [9:0]              mc_paddr,
    input  logic [31:0]             mc_pwdata,
    output logic [31:0]             mc_prdata,
    output logic                    mc_pready,
    output logic                    mc_pslverr,

    // DFI Command Interface (DDR)
    output logic [1:0]              dfi_dram_clk_disable_0,
    output logic [1:0]              dfi_dram_clk_disable_1,
    output logic                    dfi_dram_ca_disable,
    output logic [1:0]              dfi_cs_0_p0,
    output logic [1:0]              dfi_cs_0_p1,
    output logic [1:0]              dfi_cs_1_p2,
    output logic [1:0]              dfi_cs_1_p3,
    output logic [6:0]              dfi_address_0_p0,
    output logic [6:0]              dfi_address_0_p1,
    output logic [6:0]              dfi_address_1_p2,
    output logic [6:0]              dfi_address_1_p3,
    output logic                    dfi_reset_n,

    // DFI Write Data Interface
    output logic [DATA_WIDTH-1:0]  dfi_wrdata_0_p0,
    output logic [DATA_WIDTH-1:0]  dfi_wrdata_0_p1,
    output logic [DATA_WIDTH-1:0]  dfi_wrdata_1_p2,
    output logic [DATA_WIDTH-1:0]  dfi_wrdata_1_p3,
    output logic [DATA_WIDTH/8-1:0] dfi_wrdata_mask_0_p0,
    output logic [DATA_WIDTH/8-1:0] dfi_wrdata_mask_0_p1,
    output logic [DATA_WIDTH/8-1:0] dfi_wrdata_mask_1_p2,
    output logic [DATA_WIDTH/8-1:0] dfi_wrdata_mask_1_p3,
    output logic                    dfi_wrdata_en_0_p0,
    output logic                    dfi_wrdata_en_0_p1,
    output logic                    dfi_wrdata_en_1_p2,
    output logic                    dfi_wrdata_en_1_p3,

    // DFI Read Data Interface
    input  logic [DATA_WIDTH-1:0]  dfi_rddata_0_p0,
    input  logic [DATA_WIDTH-1:0]  dfi_rddata_0_p1,
    input  logic [DATA_WIDTH-1:0]  dfi_rddata_1_p2,
    input  logic [DATA_WIDTH-1:0]  dfi_rddata_1_p3,
    input  logic                    dfi_rddata_valid_0_p0,
    input  logic                    dfi_rddata_valid_0_p1,
    input  logic                    dfi_rddata_valid_1_p2,
    input  logic                    dfi_rddata_valid_1_p3,

    // DDR Physical Interface (for external PHY or memory model)
    output logic                    ddr_ck_p,
    output logic                    ddr_ck_n,
    output logic                    ddr_cke,
    output logic                    ddr_cs_n,
    output logic                    ddr_ras_n,
    output logic                    ddr_cas_n,
    output logic                    ddr_we_n,
    output logic [BANK_WIDTH-1:0]  ddr_ba,
    output logic [ROW_WIDTH-1:0]   ddr_a,
    inout  wire  [DATA_WIDTH-1:0]  ddr_dq,
    inout  wire  [DATA_WIDTH/8-1:0] ddr_dqs_p,
    inout  wire  [DATA_WIDTH/8-1:0] ddr_dqs_n,
    output logic [DATA_WIDTH/8-1:0] ddr_dm,
    output logic                    ddr_odt
);

    import openddr_pkg::*;

    // Internal signals
    logic [ADDR_WIDTH-1:0] decoded_addr;
    logic [BANK_WIDTH-1:0] bank_addr;
    logic [ROW_WIDTH-1:0]  row_addr;
    logic [COL_WIDTH-1:0]  col_addr;
    
    ctrl_state_t current_state, next_state;
    bank_state_t bank_states [2**BANK_WIDTH-1:0];
    
    // Configuration registers
    logic [31:0] config_regs [256];
    
    // Request queues
    logic [15:0] write_queue_depth;
    logic [15:0] read_queue_depth;
    
    // Timing counters
    logic [15:0] refresh_counter;
    logic [7:0]  timing_counters [8];

    // Reset synchronization
    logic rst_n_sync;
    always_ff @(posedge mck or negedge mc_rst_b) begin
        if (!mc_rst_b) begin
            rst_n_sync <= 1'b0;
        end else begin
            rst_n_sync <= 1'b1;
        end
    end

    // Address decoder
    openddr_addr_decoder #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .BANK_WIDTH(BANK_WIDTH),
        .ROW_WIDTH(ROW_WIDTH),
        .COL_WIDTH(COL_WIDTH)
    ) u_addr_decoder (
        .clk        (mck),
        .rst_n      (rst_n_sync),
        .axi_addr   (mc0_axi_awvalid ? mc0_axi_awaddr : mc0_axi_araddr),
        .bank_addr  (bank_addr),
        .row_addr   (row_addr),
        .col_addr   (col_addr)
    );

    // AXI interface controller
    openddr_axi_ctrl #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) u_axi_ctrl (
        .clk            (mck),
        .rst_n          (rst_n_sync),
        
        // AXI Interface
        .axi_awid       (mc0_axi_awid),
        .axi_awaddr     (mc0_axi_awaddr),
        .axi_awlen      (mc0_axi_awlen),
        .axi_awsize     (mc0_axi_awsize),
        .axi_awburst    (mc0_axi_awburst),
        .axi_awvalid    (mc0_axi_awvalid),
        .axi_awready    (mc0_axi_awready),
        
        .axi_wdata      (mc0_axi_wdata),
        .axi_wstrb      (mc0_axi_wstrb),
        .axi_wlast      (mc0_axi_wlast),
        .axi_wvalid     (mc0_axi_wvalid),
        .axi_wready     (mc0_axi_wready),
        
        .axi_bid        (mc0_axi_bid),
        .axi_bresp      (mc0_axi_bresp),
        .axi_bvalid     (mc0_axi_bvalid),
        .axi_bready     (mc0_axi_bready),
        
        .axi_arid       (mc0_axi_arid),
        .axi_araddr     (mc0_axi_araddr),
        .axi_arlen      (mc0_axi_arlen),
        .axi_arsize     (mc0_axi_arsize),
        .axi_arburst    (mc0_axi_arburst),
        .axi_arvalid    (mc0_axi_arvalid),
        .axi_arready    (mc0_axi_arready),
        
        .axi_rid        (mc0_axi_rid),
        .axi_rdata      (mc0_axi_rdata),
        .axi_rresp      (mc0_axi_rresp),
        .axi_rlast      (mc0_axi_rlast),
        .axi_rvalid     (mc0_axi_rvalid),
        .axi_rready     (mc0_axi_rready),
        
        // Internal memory interface
        .bank_addr      (bank_addr),
        .row_addr       (row_addr),
        .col_addr       (col_addr),
        .current_state  (current_state)
    );

    // Command scheduler and bank state machine
    openddr_scheduler #(
        .BANK_WIDTH(BANK_WIDTH),
        .ROW_WIDTH(ROW_WIDTH)
    ) u_scheduler (
        .clk            (mck),
        .rst_n          (rst_n_sync),
        .bank_addr      (bank_addr),
        .row_addr       (row_addr),
        .col_addr       (col_addr),
        .current_state  (current_state),
        .next_state     (next_state),
        .bank_states    (bank_states),
        
        // DFI Command outputs
        .dfi_cs_0_p0    (dfi_cs_0_p0),
        .dfi_cs_0_p1    (dfi_cs_0_p1),
        .dfi_cs_1_p2    (dfi_cs_1_p2),
        .dfi_cs_1_p3    (dfi_cs_1_p3),
        .dfi_address_0_p0(dfi_address_0_p0),
        .dfi_address_0_p1(dfi_address_0_p1),
        .dfi_address_1_p2(dfi_address_1_p2),
        .dfi_address_1_p3(dfi_address_1_p3)
    );

    // DFI data path
    openddr_dfi_datapath #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_dfi_datapath (
        .clk                    (mck),
        .rst_n                  (rst_n_sync),
        
        // Write data
        .axi_wdata              (mc0_axi_wdata),
        .axi_wstrb              (mc0_axi_wstrb),
        .dfi_wrdata_0_p0        (dfi_wrdata_0_p0),
        .dfi_wrdata_0_p1        (dfi_wrdata_0_p1),
        .dfi_wrdata_1_p2        (dfi_wrdata_1_p2),
        .dfi_wrdata_1_p3        (dfi_wrdata_1_p3),
        .dfi_wrdata_mask_0_p0   (dfi_wrdata_mask_0_p0),
        .dfi_wrdata_mask_0_p1   (dfi_wrdata_mask_0_p1),
        .dfi_wrdata_mask_1_p2   (dfi_wrdata_mask_1_p2),
        .dfi_wrdata_mask_1_p3   (dfi_wrdata_mask_1_p3),
        .dfi_wrdata_en_0_p0     (dfi_wrdata_en_0_p0),
        .dfi_wrdata_en_0_p1     (dfi_wrdata_en_0_p1),
        .dfi_wrdata_en_1_p2     (dfi_wrdata_en_1_p2),
        .dfi_wrdata_en_1_p3     (dfi_wrdata_en_1_p3),
        
        // Read data
        .dfi_rddata_0_p0        (dfi_rddata_0_p0),
        .dfi_rddata_0_p1        (dfi_rddata_0_p1),
        .dfi_rddata_1_p2        (dfi_rddata_1_p2),
        .dfi_rddata_1_p3        (dfi_rddata_1_p3),
        .dfi_rddata_valid_0_p0  (dfi_rddata_valid_0_p0),
        .dfi_rddata_valid_0_p1  (dfi_rddata_valid_0_p1),
        .dfi_rddata_valid_1_p2  (dfi_rddata_valid_1_p2),
        .dfi_rddata_valid_1_p3  (dfi_rddata_valid_1_p3),
        .axi_rdata              (/* connected through u_axi_ctrl */)
    );

    // APB configuration interface
    openddr_apb_cfg u_apb_cfg (
        .clk        (mck),
        .rst_n      (rst_n_sync),
        .penable    (mc_penable),
        .psel       (mc_psel),
        .pwr        (mc_pwr),
        .paddr      (mc_paddr),
        .pwdata     (mc_pwdata),
        .prdata     (mc_prdata),
        .pready     (mc_pready),
        .pslverr    (mc_pslverr),
        .config_regs(config_regs)
    );

    // Control signals
    assign dfi_dram_clk_disable_0 = 2'b00;
    assign dfi_dram_clk_disable_1 = 2'b00;
    assign dfi_dram_ca_disable = 1'b0;
    assign dfi_reset_n = rst_n_sync;

    // DDR PHY interface (simplified)
    assign ddr_ck_p = mck;
    assign ddr_ck_n = ~mck;
    assign ddr_cke = rst_n_sync;
    assign ddr_cs_n = ~(|dfi_cs_0_p0);

endmodule
