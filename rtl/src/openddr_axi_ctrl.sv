//==============================================================================
// OpenDDR AXI Controller
// 
// Description: Handles AXI protocol and interfaces with memory controller
// Author: Open DDR Project
// Date: 2025
//==============================================================================

`include "openddr_pkg.sv"

module openddr_axi_ctrl #(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 40,
    parameter ID_WIDTH   = 12
) (
    input  logic                    clk,
    input  logic                    rst_n,
    
    // AXI Write Address Channel
    input  logic [ID_WIDTH-1:0]     axi_awid,
    input  logic [ADDR_WIDTH-1:0]  axi_awaddr,
    input  logic [7:0]              axi_awlen,
    input  logic [2:0]              axi_awsize,
    input  logic [1:0]              axi_awburst,
    input  logic                    axi_awvalid,
    output logic                    axi_awready,
    
    // AXI Write Data Channel
    input  logic [DATA_WIDTH-1:0]  axi_wdata,
    input  logic [DATA_WIDTH/8-1:0] axi_wstrb,
    input  logic                    axi_wlast,
    input  logic                    axi_wvalid,
    output logic                    axi_wready,
    
    // AXI Write Response Channel
    output logic [ID_WIDTH-1:0]     axi_bid,
    output logic [1:0]              axi_bresp,
    output logic                    axi_bvalid,
    input  logic                    axi_bready,
    
    // AXI Read Address Channel
    input  logic [ID_WIDTH-1:0]     axi_arid,
    input  logic [ADDR_WIDTH-1:0]  axi_araddr,
    input  logic [7:0]              axi_arlen,
    input  logic [2:0]              axi_arsize,
    input  logic [1:0]              axi_arburst,
    input  logic                    axi_arvalid,
    output logic                    axi_arready,
    
    // AXI Read Data Channel
    output logic [ID_WIDTH-1:0]     axi_rid,
    output logic [DATA_WIDTH-1:0]  axi_rdata,
    output logic [1:0]              axi_rresp,
    output logic                    axi_rlast,
    output logic                    axi_rvalid,
    input  logic                    axi_rready,
    
    // Memory Controller Interface
    input  logic [2:0]              bank_addr,
    input  logic [15:0]             row_addr,
    input  logic [9:0]              col_addr,
    input  openddr_pkg::ctrl_state_t current_state
);

    import openddr_pkg::*;

    // AXI State machines
    typedef enum logic [2:0] {
        AW_IDLE,
        AW_ACCEPT,
        AW_WAIT
    } aw_state_t;

    typedef enum logic [2:0] {
        W_IDLE,
        W_TRANSFER,
        W_RESPONSE
    } w_state_t;

    typedef enum logic [2:0] {
        AR_IDLE,
        AR_ACCEPT,
        AR_WAIT
    } ar_state_t;

    typedef enum logic [2:0] {
        R_IDLE,
        R_TRANSFER
    } r_state_t;

    aw_state_t aw_state, aw_next;
    w_state_t  w_state, w_next;
    ar_state_t ar_state, ar_next;
    r_state_t  r_state, r_next;

    // Transaction storage
    logic [ID_WIDTH-1:0]    stored_awid, stored_arid;
    logic [ADDR_WIDTH-1:0]  stored_awaddr, stored_araddr;
    logic [7:0]             stored_awlen, stored_arlen;
    logic [7:0]             w_beat_count, r_beat_count;

    // Write address channel FSM
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            aw_state <= AW_IDLE;
        else
            aw_state <= aw_next;
    end

    always_comb begin
        aw_next = aw_state;
        case (aw_state)
            AW_IDLE: if (axi_awvalid) aw_next = AW_ACCEPT;
            AW_ACCEPT: aw_next = AW_WAIT;
            AW_WAIT: if (w_state == W_RESPONSE && axi_bready) aw_next = AW_IDLE;
        endcase
    end

    // Write data channel FSM
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            w_state <= W_IDLE;
        else
            w_state <= w_next;
    end

    always_comb begin
        w_next = w_state;
        case (w_state)
            W_IDLE: if (aw_state == AW_ACCEPT) w_next = W_TRANSFER;
            W_TRANSFER: if (axi_wvalid && axi_wlast) w_next = W_RESPONSE;
            W_RESPONSE: if (axi_bready) w_next = W_IDLE;
        endcase
    end

    // Read address channel FSM
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            ar_state <= AR_IDLE;
        else
            ar_state <= ar_next;
    end

    always_comb begin
        ar_next = ar_state;
        case (ar_state)
            AR_IDLE: if (axi_arvalid) ar_next = AR_ACCEPT;
            AR_ACCEPT: ar_next = AR_WAIT;
            AR_WAIT: if (r_state == R_TRANSFER && axi_rready && axi_rlast) ar_next = AR_IDLE;
        endcase
    end

    // Read data channel FSM
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            r_state <= R_IDLE;
        else
            r_state <= r_next;
    end

    always_comb begin
        r_next = r_state;
        case (r_state)
            R_IDLE: if (ar_state == AR_ACCEPT) r_next = R_TRANSFER;
            R_TRANSFER: if (axi_rready && axi_rlast) r_next = R_IDLE;
        endcase
    end

    // Store transaction info
    always_ff @(posedge clk) begin
        if (axi_awvalid && axi_awready) begin
            stored_awid   <= axi_awid;
            stored_awaddr <= axi_awaddr;
            stored_awlen  <= axi_awlen;
        end
        
        if (axi_arvalid && axi_arready) begin
            stored_arid   <= axi_arid;
            stored_araddr <= axi_araddr;
            stored_arlen  <= axi_arlen;
        end
    end

    // Beat counters
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_beat_count <= 0;
            r_beat_count <= 0;
        end else begin
            if (axi_wvalid && axi_wready) begin
                if (axi_wlast)
                    w_beat_count <= 0;
                else
                    w_beat_count <= w_beat_count + 1;
            end
            
            if (axi_rvalid && axi_rready) begin
                if (axi_rlast)
                    r_beat_count <= 0;
                else
                    r_beat_count <= r_beat_count + 1;
            end
        end
    end

    // AXI signal assignments
    assign axi_awready = (aw_state == AW_IDLE);
    assign axi_wready  = (w_state == W_TRANSFER);
    
    assign axi_bid     = stored_awid;
    assign axi_bresp   = AXI_OKAY;
    assign axi_bvalid  = (w_state == W_RESPONSE);
    
    assign axi_arready = (ar_state == AR_IDLE);
    
    assign axi_rid     = stored_arid;
    assign axi_rdata   = {DATA_WIDTH{1'b0}}; // Connected to memory data path
    assign axi_rresp   = AXI_OKAY;
    assign axi_rlast   = (r_beat_count == stored_arlen);
    assign axi_rvalid  = (r_state == R_TRANSFER);

endmodule
