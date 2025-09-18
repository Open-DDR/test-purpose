//==============================================================================
// SystemC-RTL Interface Module
// 
// Description: Interface between SystemC model and RTL implementation
// Author: Open DDR Project
// Date: 2025
//==============================================================================

`include "openddr_pkg.sv"

module systemc_rtl_interface #(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 40,
    parameter ID_WIDTH   = 12
) (
    // Clock and Reset
    input  logic                    clk,
    input  logic                    rst_n,
    
    // SystemC Interface (DPI-C or similar)
    input  logic                    sc_valid,
    input  logic [ADDR_WIDTH-1:0]  sc_addr,
    input  logic [DATA_WIDTH-1:0]  sc_wdata,
    input  logic [DATA_WIDTH/8-1:0] sc_wstrb,
    input  logic                    sc_we,
    input  logic [ID_WIDTH-1:0]     sc_id,
    input  logic [7:0]              sc_len,
    output logic [DATA_WIDTH-1:0]  sc_rdata,
    output logic                    sc_ready,
    output logic                    sc_valid_out,
    
    // RTL AXI Interface
    output logic [ID_WIDTH-1:0]     axi_awid,
    output logic [ADDR_WIDTH-1:0]  axi_awaddr,
    output logic [7:0]              axi_awlen,
    output logic [2:0]              axi_awsize,
    output logic [1:0]              axi_awburst,
    output logic                    axi_awvalid,
    input  logic                    axi_awready,
    
    output logic [DATA_WIDTH-1:0]  axi_wdata,
    output logic [DATA_WIDTH/8-1:0] axi_wstrb,
    output logic                    axi_wlast,
    output logic                    axi_wvalid,
    input  logic                    axi_wready,
    
    input  logic [ID_WIDTH-1:0]     axi_bid,
    input  logic [1:0]              axi_bresp,
    input  logic                    axi_bvalid,
    output logic                    axi_bready,
    
    output logic [ID_WIDTH-1:0]     axi_arid,
    output logic [ADDR_WIDTH-1:0]  axi_araddr,
    output logic [7:0]              axi_arlen,
    output logic [2:0]              axi_arsize,
    output logic [1:0]              axi_arburst,
    output logic                    axi_arvalid,
    input  logic                    axi_arready,
    
    input  logic [ID_WIDTH-1:0]     axi_rid,
    input  logic [DATA_WIDTH-1:0]  axi_rdata,
    input  logic [1:0]              axi_rresp,
    input  logic                    axi_rlast,
    input  logic                    axi_rvalid,
    output logic                    axi_rready
);

    import openddr_pkg::*;

    // Internal state machine
    typedef enum logic [2:0] {
        IDLE,
        WRITE_ADDR,
        WRITE_DATA,
        WRITE_RESP,
        READ_ADDR,
        READ_DATA
    } if_state_t;

    if_state_t current_state, next_state;
    
    // Transaction storage
    logic [ADDR_WIDTH-1:0]  stored_addr;
    logic [DATA_WIDTH-1:0]  stored_wdata;
    logic [DATA_WIDTH/8-1:0] stored_wstrb;
    logic [ID_WIDTH-1:0]    stored_id;
    logic [7:0]             stored_len;
    logic                   stored_we;
    logic [7:0]             beat_count;

    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Next state logic
    always_comb begin
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (sc_valid) begin
                    if (sc_we)
                        next_state = WRITE_ADDR;
                    else
                        next_state = READ_ADDR;
                end
            end
            
            WRITE_ADDR: begin
                if (axi_awready)
                    next_state = WRITE_DATA;
            end
            
            WRITE_DATA: begin
                if (axi_wready && axi_wlast)
                    next_state = WRITE_RESP;
            end
            
            WRITE_RESP: begin
                if (axi_bvalid)
                    next_state = IDLE;
            end
            
            READ_ADDR: begin
                if (axi_arready)
                    next_state = READ_DATA;
            end
            
            READ_DATA: begin
                if (axi_rvalid && axi_rlast)
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end

    // Store transaction information
    always_ff @(posedge clk) begin
        if (sc_valid && current_state == IDLE) begin
            stored_addr  <= sc_addr;
            stored_wdata <= sc_wdata;
            stored_wstrb <= sc_wstrb;
            stored_id    <= sc_id;
            stored_len   <= sc_len;
            stored_we    <= sc_we;
        end
    end

    // Beat counter for burst transactions
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            beat_count <= 0;
        end else if (current_state == WRITE_DATA && axi_wvalid && axi_wready) begin
            beat_count <= beat_count + 1;
        end else if (current_state == READ_DATA && axi_rvalid && axi_rready) begin
            beat_count <= beat_count + 1;
        end else if (current_state == IDLE) begin
            beat_count <= 0;
        end
    end

    // AXI Write Address Channel
    assign axi_awid    = stored_id;
    assign axi_awaddr  = stored_addr;
    assign axi_awlen   = stored_len;
    assign axi_awsize  = $clog2(DATA_WIDTH/8);
    assign axi_awburst = 2'b01; // INCR
    assign axi_awvalid = (current_state == WRITE_ADDR);

    // AXI Write Data Channel
    assign axi_wdata  = stored_wdata;
    assign axi_wstrb  = stored_wstrb;
    assign axi_wlast  = (beat_count == stored_len);
    assign axi_wvalid = (current_state == WRITE_DATA);

    // AXI Write Response Channel
    assign axi_bready = (current_state == WRITE_RESP);

    // AXI Read Address Channel
    assign axi_arid    = stored_id;
    assign axi_araddr  = stored_addr;
    assign axi_arlen   = stored_len;
    assign axi_arsize  = $clog2(DATA_WIDTH/8);
    assign axi_arburst = 2'b01; // INCR
    assign axi_arvalid = (current_state == READ_ADDR);

    // AXI Read Data Channel
    assign axi_rready = (current_state == READ_DATA);

    // SystemC Interface outputs
    assign sc_rdata     = axi_rdata;
    assign sc_ready     = (current_state == IDLE) || 
                         (current_state == WRITE_RESP && axi_bvalid) ||
                         (current_state == READ_DATA && axi_rvalid && axi_rlast);
    assign sc_valid_out = sc_ready;

endmodule
