//==============================================================================
// OpenDDR Address Decoder
// 
// Description: Decodes AXI address to DDR bank/row/column addresses
// Author: Open DDR Project
// Date: 2025
//==============================================================================

`include "openddr_pkg.sv"

module openddr_addr_decoder #(
    parameter ADDR_WIDTH = 40,
    parameter BANK_WIDTH = 3,
    parameter ROW_WIDTH  = 16,
    parameter COL_WIDTH  = 10
) (
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic [ADDR_WIDTH-1:0]  axi_addr,
    output logic [BANK_WIDTH-1:0]  bank_addr,
    output logic [ROW_WIDTH-1:0]   row_addr,
    output logic [COL_WIDTH-1:0]   col_addr
);

    import openddr_pkg::*;

    // Address mapping configuration
    localparam COL_OFFSET  = 3;  // 8-byte aligned
    localparam BANK_OFFSET = COL_OFFSET + COL_WIDTH;
    localparam ROW_OFFSET  = BANK_OFFSET + BANK_WIDTH;

    always_comb begin
        // Column address (lower bits)
        col_addr = axi_addr[COL_OFFSET +: COL_WIDTH];
        
        // Bank address (middle bits)
        bank_addr = axi_addr[BANK_OFFSET +: BANK_WIDTH];
        
        // Row address (upper bits)
        row_addr = axi_addr[ROW_OFFSET +: ROW_WIDTH];
    end

endmodule
