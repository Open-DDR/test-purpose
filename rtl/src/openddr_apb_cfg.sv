//==============================================================================
// OpenDDR APB Configuration Interface
// 
// Description: APB slave for memory controller configuration
// Author: Open DDR Project
// Date: 2025
//==============================================================================

`include "openddr_pkg.sv"

module openddr_apb_cfg (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        penable,
    input  logic        psel,
    input  logic        pwr,
    input  logic [9:0]  paddr,
    input  logic [31:0] pwdata,
    output logic [31:0] prdata,
    output logic        pready,
    output logic        pslverr,
    output logic [31:0] config_regs [256]
);

    import openddr_pkg::*;

    // Internal configuration registers
    logic [31:0] cfg_regs [256];
    
    // APB state machine
    typedef enum logic [1:0] {
        APB_IDLE,
        APB_SETUP,
        APB_ACCESS
    } apb_state_t;
    
    apb_state_t apb_state, apb_next;

    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            apb_state <= APB_IDLE;
        else
            apb_state <= apb_next;
    end

    always_comb begin
        apb_next = apb_state;
        
        case (apb_state)
            APB_IDLE: begin
                if (psel)
                    apb_next = APB_SETUP;
            end
            
            APB_SETUP: begin
                if (penable)
                    apb_next = APB_ACCESS;
            end
            
            APB_ACCESS: begin
                apb_next = APB_IDLE;
            end
        endcase
    end

    // Address decode - word-aligned addresses
    wire [7:0] reg_addr = paddr[9:2];

    // Register write
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Initialize configuration registers with default values
            for (int i = 0; i < 256; i++) begin
                cfg_regs[i] <= 32'h0;
            end
            
            // Default configuration values
            cfg_regs[0] <= 32'h00000001;  // CTRL_REG - Enable
            cfg_regs[1] <= 32'h00030000;  // DDR_CONFIG - DDR, 64-bit, BL8
            cfg_regs[2] <= 32'h12345678;  // VERSION_REG
            cfg_regs[8] <= 32'h0000000F;  // tRCD
            cfg_regs[9] <= 32'h0000000F;  // tRP
            cfg_regs[10] <= 32'h0000002A; // tRAS
            cfg_regs[11] <= 32'h00000037; // tRC
        end else if (apb_state == APB_ACCESS && pwr && psel) begin
            cfg_regs[reg_addr] <= pwdata;
        end
    end

    // Register read
    always_comb begin
        prdata = 32'h0;
        if (apb_state == APB_ACCESS && !pwr && psel) begin
            prdata = cfg_regs[reg_addr];
        end
    end

    // APB response
    assign pready  = (apb_state == APB_ACCESS);
    assign pslverr = 1'b0; // No slave errors for this simple implementation
    
    // Output configuration registers
    assign config_regs = cfg_regs;

endmodule
