//==============================================================================
// OpenDDR Command Scheduler
// 
// Description: Schedules DDR commands and manages bank state machines
// Author: Open DDR Project
// Date: 2025
//==============================================================================

`include "openddr_pkg.sv"

module openddr_scheduler #(
    parameter BANK_WIDTH = 3,
    parameter ROW_WIDTH  = 16
) (
    input  logic                        clk,
    input  logic                        rst_n,
    input  logic [BANK_WIDTH-1:0]      bank_addr,
    input  logic [ROW_WIDTH-1:0]       row_addr,
    input  logic [9:0]                  col_addr,
    input  openddr_pkg::ctrl_state_t    current_state,
    output openddr_pkg::ctrl_state_t    next_state,
    output openddr_pkg::bank_state_t    bank_states [2**BANK_WIDTH-1:0],
    
    // DFI Command Interface
    output logic [1:0]                  dfi_cs_0_p0,
    output logic [1:0]                  dfi_cs_0_p1,
    output logic [1:0]                  dfi_cs_1_p2,
    output logic [1:0]                  dfi_cs_1_p3,
    output logic [6:0]                  dfi_address_0_p0,
    output logic [6:0]                  dfi_address_0_p1,
    output logic [6:0]                  dfi_address_1_p2,
    output logic [6:0]                  dfi_address_1_p3
);

    import openddr_pkg::*;

    // Bank state tracking
    bank_state_t bank_state_regs [2**BANK_WIDTH-1:0];
    logic [ROW_WIDTH-1:0] open_rows [2**BANK_WIDTH-1:0];
    
    // Timing counters
    logic [15:0] timing_counters [2**BANK_WIDTH-1:0];
    logic [15:0] refresh_counter;
    
    // Command generation
    ddr_cmd_t current_cmd;
    logic cmd_valid;

    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 2**BANK_WIDTH; i++) begin
                bank_state_regs[i] <= BANK_IDLE;
                open_rows[i] <= 0;
                timing_counters[i] <= 0;
            end
            refresh_counter <= 0;
        end else begin
            // Update timing counters
            for (int i = 0; i < 2**BANK_WIDTH; i++) begin
                if (timing_counters[i] > 0)
                    timing_counters[i] <= timing_counters[i] - 1;
            end
            
            // Refresh counter
            if (refresh_counter > 0)
                refresh_counter <= refresh_counter - 1;
            else
                refresh_counter <= tREFI;
            
            // Bank state updates based on commands
            case (current_state)
                CTRL_ACTIVATE: begin
                    if (bank_state_regs[bank_addr] == BANK_IDLE) begin
                        bank_state_regs[bank_addr] <= BANK_ACTIVATING;
                        open_rows[bank_addr] <= row_addr;
                        timing_counters[bank_addr] <= tRCD;
                    end
                end
                
                CTRL_READ, CTRL_WRITE: begin
                    if (bank_state_regs[bank_addr] == BANK_ACTIVE) begin
                        bank_state_regs[bank_addr] <= (current_state == CTRL_READ) ? 
                                                     BANK_READING : BANK_WRITING;
                    end
                end
                
                CTRL_PRECHARGE: begin
                    if (bank_state_regs[bank_addr] != BANK_IDLE) begin
                        bank_state_regs[bank_addr] <= BANK_PRECHARGE;
                        timing_counters[bank_addr] <= tRP;
                    end
                end
            endcase
            
            // Auto-transition from timing states
            for (int i = 0; i < 2**BANK_WIDTH; i++) begin
                if (timing_counters[i] == 1) begin
                    case (bank_state_regs[i])
                        BANK_ACTIVATING: bank_state_regs[i] <= BANK_ACTIVE;
                        BANK_PRECHARGE:  bank_state_regs[i] <= BANK_IDLE;
                        BANK_READING:    bank_state_regs[i] <= BANK_ACTIVE;
                        BANK_WRITING:    bank_state_regs[i] <= BANK_ACTIVE;
                    endcase
                end
            end
        end
    end

    // Next state logic
    always_comb begin
        next_state = current_state;
        
        case (current_state)
            CTRL_IDLE: begin
                if (refresh_counter < 10)
                    next_state = CTRL_REFRESH;
                else if (bank_state_regs[bank_addr] == BANK_IDLE)
                    next_state = CTRL_ACTIVATE;
                else if (bank_state_regs[bank_addr] == BANK_ACTIVE) begin
                    if (open_rows[bank_addr] == row_addr)
                        next_state = CTRL_READ; // or CTRL_WRITE based on request
                    else
                        next_state = CTRL_PRECHARGE;
                end
            end
            
            CTRL_ACTIVATE: begin
                if (timing_counters[bank_addr] == 0)
                    next_state = CTRL_READ; // or CTRL_WRITE
            end
            
            CTRL_READ, CTRL_WRITE: begin
                next_state = CTRL_IDLE;
            end
            
            CTRL_PRECHARGE: begin
                if (timing_counters[bank_addr] == 0)
                    next_state = CTRL_ACTIVATE;
            end
            
            CTRL_REFRESH: begin
                next_state = CTRL_IDLE;
            end
            
            default: next_state = CTRL_IDLE;
        endcase
    end

    // Command generation
    always_comb begin
        current_cmd = CMD_NOP;
        cmd_valid = 1'b0;
        
        case (current_state)
            CTRL_ACTIVATE: begin
                current_cmd = CMD_ACT;
                cmd_valid = 1'b1;
            end
            
            CTRL_READ: begin
                current_cmd = CMD_RD;
                cmd_valid = 1'b1;
            end
            
            CTRL_WRITE: begin
                current_cmd = CMD_WR;
                cmd_valid = 1'b1;
            end
            
            CTRL_PRECHARGE: begin
                current_cmd = CMD_PRE;
                cmd_valid = 1'b1;
            end
            
            CTRL_REFRESH: begin
                current_cmd = CMD_REF;
                cmd_valid = 1'b1;
            end
        endcase
    end

    // DFI command outputs (4-phase interface)
    always_comb begin
        // Default values
        dfi_cs_0_p0 = 2'b11;
        dfi_cs_0_p1 = 2'b11;
        dfi_cs_1_p2 = 2'b11;
        dfi_cs_1_p3 = 2'b11;
        dfi_address_0_p0 = 7'h00;
        dfi_address_0_p1 = 7'h00;
        dfi_address_1_p2 = 7'h00;
        dfi_address_1_p3 = 7'h00;
        
        if (cmd_valid) begin
            // Phase 0 - Command
            dfi_cs_0_p0 = {1'b0, current_cmd[3]};
            case (current_state)
                CTRL_ACTIVATE: dfi_address_0_p0 = row_addr[6:0];
                CTRL_READ, CTRL_WRITE: dfi_address_0_p0 = col_addr[6:0];
                CTRL_PRECHARGE: dfi_address_0_p0 = {4'h0, bank_addr};
                default: dfi_address_0_p0 = 7'h00;
            endcase
        end
    end

    // Output bank states
    assign bank_states = bank_state_regs;

endmodule
