// ddr2_axi_controller.sv
`timescale 1ns/1ps
// DDR2 Controller RTL with AXI4-Lite interface (simplified, extend as needed)

`include "ddr2_pkg.sv"

module ddr2_axi_controller #(
    parameter ADDR_WIDTH = 28, // DDR2 address width
    parameter DATA_WIDTH = 32, // Data bus width
    parameter AXI_ID_WIDTH = 4
) (
    // AXI4-Lite Slave Interface
    input  wire                     ACLK,
    input  wire                     ARESETN,
    // Write address channel
    input  wire [AXI_ID_WIDTH-1:0]  S_AXI_AWID,
    input  wire [ADDR_WIDTH-1:0]    S_AXI_AWADDR,
    input  wire                     S_AXI_AWVALID,
    output wire                     S_AXI_AWREADY,
    // Write data channel
    input  wire [DATA_WIDTH-1:0]    S_AXI_WDATA,
    input  wire [(DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input  wire                     S_AXI_WVALID,
    output wire                     S_AXI_WREADY,
    // Write response channel
    output wire [1:0]               S_AXI_BRESP,
    output wire                     S_AXI_BVALID,
    input  wire                     S_AXI_BREADY,
    // Read address channel
    input  wire [AXI_ID_WIDTH-1:0]  S_AXI_ARID,
    input  wire [ADDR_WIDTH-1:0]    S_AXI_ARADDR,
    input  wire                     S_AXI_ARVALID,
    output wire                     S_AXI_ARREADY,
    // Read data channel
    output wire [DATA_WIDTH-1:0]    S_AXI_RDATA,
    output wire [1:0]               S_AXI_RRESP,
    output wire                     S_AXI_RVALID,
    input  wire                     S_AXI_RREADY,

    // DDR2 SDRAM Interface (simplified)
    output wire [ADDR_WIDTH-1:0]    ddr2_addr,
    output wire [2:0]               ddr2_ba,
    output wire                     ddr2_ras_n,
    output wire                     ddr2_cas_n,
    output wire                     ddr2_we_n,
    output wire                     ddr2_cs_n,
    output wire                     ddr2_cke,
    output wire                     ddr2_odt,
    output wire                     ddr2_reset_n,
    inout  wire [15:0]              ddr2_dq,
    inout  wire [1:0]               ddr2_dqs,
    output wire [1:0]               ddr2_dm,
    output wire                     ddr2_clk,
    output wire                     ddr2_clk_n
);


    import ddr2_pkg::*;

    // State machine for controller
    ctrl_state_t ctrl_state, ctrl_state_next;
    bank_state_t bank_state;
    ddr2_cmd_t   ddr2_cmd;

    // AXI request buffering
    logic [ADDR_WIDTH-1:0] axi_addr_buf;
    logic [DATA_WIDTH-1:0] axi_wdata_buf;
    logic [DATA_WIDTH-1:0] axi_rdata_buf;
    logic                  axi_wr_en, axi_rd_en;
    logic                  axi_req_valid, axi_req_ready;

    // DDR2 address mapping
    logic [2:0]  ddr2_bank;
    logic [13:0] ddr2_row;
    logic [9:0]  ddr2_col;

    // Simple refresh timer
    logic [15:0] refresh_counter;
    logic        refresh_req;

    // AXI handshake
    assign S_AXI_AWREADY = (ctrl_state == CTRL_IDLE);
    assign S_AXI_WREADY  = (ctrl_state == CTRL_IDLE);
    assign S_AXI_BRESP   = 2'b00; // OKAY
    assign S_AXI_BVALID  = (ctrl_state == CTRL_WRITE && ctrl_state_next == CTRL_IDLE);
    assign S_AXI_ARREADY = (ctrl_state == CTRL_IDLE);
    assign S_AXI_RDATA   = axi_rdata_buf;
    assign S_AXI_RRESP   = 2'b00; // OKAY
    assign S_AXI_RVALID  = (ctrl_state == CTRL_READ && ctrl_state_next == CTRL_IDLE);

    // DDR2 command outputs
    // Pad upper bits to match ADDR_WIDTH (28) if needed
    assign ddr2_addr    = {{(ADDR_WIDTH-24){1'b0}}, ddr2_row, ddr2_col};
    assign ddr2_ba      = ddr2_bank;
    assign ddr2_ras_n   = (ddr2_cmd == CMD_ACT) ? 1'b0 : 1'b1;
    assign ddr2_cas_n   = (ddr2_cmd == CMD_RD || ddr2_cmd == CMD_WR) ? 1'b0 : 1'b1;
    assign ddr2_we_n    = (ddr2_cmd == CMD_WR) ? 1'b0 : 1'b1;
    assign ddr2_cs_n    = 1'b0;
    assign ddr2_cke     = 1'b1;
    assign ddr2_odt     = (ddr2_cmd == CMD_WR);
    assign ddr2_reset_n = 1'b1;
    assign ddr2_dm      = 2'b00;
    assign ddr2_clk     = ACLK;
    assign ddr2_clk_n   = ~ACLK;

    // DDR2 DQ/DQS handling (simplified)
    assign ddr2_dq  = (ctrl_state == CTRL_WRITE) ? axi_wdata_buf[15:0] : 'z;
    assign ddr2_dqs = (ctrl_state == CTRL_WRITE) ? 2'b11 : 2'bzz;

    // Address decode (simple mapping)
    always_comb begin
        ddr2_bank = S_AXI_AWADDR[13:11];
        ddr2_row  = S_AXI_AWADDR[27:14];
        ddr2_col  = S_AXI_AWADDR[10:1];
    end

    // Refresh timer
    always_ff @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            refresh_counter <= 0;
            refresh_req <= 0;
        end else if ({16'b0, refresh_counter} >= tREFI) begin
            refresh_counter <= 0;
            refresh_req <= 1;
        end else begin
            refresh_counter <= refresh_counter + 1;
            refresh_req <= 0;
        end
    end

    // Main state machine
    always_ff @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            ctrl_state <= CTRL_INIT;
        end else begin
            ctrl_state <= ctrl_state_next;
        end
    end

    always_comb begin
        ctrl_state_next = ctrl_state;
        ddr2_cmd = CMD_NOP;
        axi_addr_buf = '0;
        axi_wdata_buf = '0;
        axi_rdata_buf = '0;
        case (ctrl_state)
            CTRL_INIT: begin
                // Initialization sequence (simplified)
                ctrl_state_next = CTRL_IDLE;
            end
            CTRL_IDLE: begin
                if (refresh_req) begin
                    ddr2_cmd = CMD_REF;
                    ctrl_state_next = CTRL_REFRESH;
                end else if (S_AXI_AWVALID && S_AXI_WVALID) begin
                    axi_addr_buf = S_AXI_AWADDR;
                    axi_wdata_buf = S_AXI_WDATA;
                    ddr2_cmd = CMD_ACT;
                    ctrl_state_next = CTRL_ACTIVATE;
                end else if (S_AXI_ARVALID) begin
                    axi_addr_buf = S_AXI_ARADDR;
                    ddr2_cmd = CMD_ACT;
                    ctrl_state_next = CTRL_ACTIVATE;
                end
            end
            CTRL_ACTIVATE: begin
                ddr2_cmd = CMD_ACT;
                // Wait tRCD, then issue read/write
                if (S_AXI_AWVALID && S_AXI_WVALID)
                    ctrl_state_next = CTRL_WRITE;
                else if (S_AXI_ARVALID)
                    ctrl_state_next = CTRL_READ;
            end
            CTRL_WRITE: begin
                ddr2_cmd = CMD_WR;
                // Write data to DDR2
                ctrl_state_next = CTRL_PRECHARGE;
            end
            CTRL_READ: begin
                ddr2_cmd = CMD_RD;
                // Read data from DDR2
                axi_rdata_buf = {16'b0, ddr2_dq}; // zero-extend to 32 bits
                ctrl_state_next = CTRL_PRECHARGE;
            end
            CTRL_PRECHARGE: begin
                ddr2_cmd = CMD_PRE;
                ctrl_state_next = CTRL_IDLE;
            end
            CTRL_REFRESH: begin
                ddr2_cmd = CMD_REF;
                ctrl_state_next = CTRL_IDLE;
            end
            default: begin
                ctrl_state_next = CTRL_IDLE;
            end
        endcase
    end

endmodule
