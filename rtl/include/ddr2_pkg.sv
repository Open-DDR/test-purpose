//==============================================================================
`timescale 1ns/1ps
// DDR2 Package - Enhanced with Timing Violation Detection
// 
// Description: Common definitions and parameters for DDR2 controller
// Author: Open DDR Project - Enhanced for VS Code Extension
// Date: 2025
//==============================================================================

package ddr2_pkg;

    // DDR2 Timing Parameters (ns) - Real values for precise timing violation detection
    parameter real tRC   = 60.0;   // RAS cycle time
    parameter real tRAS  = 45.0;   // RAS active time
    parameter real tRP   = 15.0;   // RAS precharge time
    parameter real tRCD  = 15.0;   // RAS to CAS delay
    parameter real tRRD  = 10.0;   // RAS to RAS delay
    parameter real tFAW  = 50.0;   // Four activate window
    parameter real tCL   = 15.0;   // CAS latency
    parameter real tWR   = 15.0;   // Write recovery time
    parameter real tRTP  = 7.5;    // Read to precharge
    parameter real tWTR  = 7.5;    // Write to read delay
    parameter real tREFI = 7800.0; // Refresh interval
    parameter real tRFC  = 127.5;  // Refresh cycle time
    parameter real tCK   = 5.0;    // Clock period (200MHz)

    // DDR2 Command Types
    typedef enum logic [2:0] {
        CMD_NOP      = 3'b111,
        CMD_ACTIVE   = 3'b011,
        CMD_READ     = 3'b101,
        CMD_WRITE    = 3'b100,
        CMD_PRECHARGE= 3'b010,
        CMD_REFRESH  = 3'b001,
        CMD_MRS      = 3'b000
    } ddr2_cmd_t;

    // DDR2 State Machine States
    typedef enum logic [3:0] {
        IDLE         = 4'b0000,
        ACTIVE       = 4'b0001,
        READ         = 4'b0010,
        WRITE        = 4'b0011,
        PRECHARGE    = 4'b0100,
        REFRESH      = 4'b0101,
        MODE_REG_SET = 4'b0110,
        POWER_DOWN   = 4'b0111,
        SELF_REFRESH = 4'b1000
    } ddr2_state_t;

    // Bank States
    typedef enum logic [2:0] {
        BANK_IDLE       = 3'b000,
        BANK_ACTIVATING = 3'b001,
        BANK_ACTIVE     = 3'b010,
        BANK_READING    = 3'b011,
        BANK_WRITING    = 3'b100,
        BANK_PRECHARGE  = 3'b101
    } bank_state_t;

    // DDR2 Configuration Structure
    typedef struct packed {
        logic [2:0]  burst_length;
        logic        burst_type;
        logic [2:0]  cas_latency;
        logic        test_mode;
        logic [2:0]  dll_reset;
        logic [2:0]  write_recovery;
        logic        power_down_mode;
    } ddr2_mode_reg_t;

    // Address mapping structure
    typedef struct packed {
        logic [2:0]  bank;
        logic [13:0] row;
        logic [9:0]  col;
    } addr_map_t;

    // Request structure
    typedef struct packed {
        logic [31:0] addr;
        logic [31:0] data;
        logic [3:0]  strb;
        logic        wr_en;
        logic        rd_en;
        logic        valid;
    } mem_req_t;

    // Response structure
    typedef struct packed {
        logic [31:0] data;
        logic [1:0]  resp;
        logic        valid;
        logic        ready;
    } mem_resp_t;

    // Timing Violation Detection Structure
    typedef struct packed {
        logic trc_violation;
        logic tras_violation;
        logic trp_violation;
        logic trcd_violation;
        logic trrd_violation;
        logic tfaw_violation;
        logic twr_violation;
        logic trtp_violation;
        logic twtr_violation;
    } timing_violations_t;

    // Function to check timing violations
    function automatic timing_violations_t check_timing_violations(
        input real current_time,
        input real last_activate_time,
        input real last_precharge_time,
        input real last_read_time,
        input real last_write_time
    );
        timing_violations_t violations = '0;
        
        if ((current_time - last_activate_time) < tRCD) begin
            violations.trcd_violation = 1'b1;
        end
        
        if ((current_time - last_precharge_time) < tRP) begin
            violations.trp_violation = 1'b1;
        end
        
        if ((current_time - last_write_time) < tWR) begin
            violations.twr_violation = 1'b1;
        end
        
        return violations;
    endfunction

endpackage : ddr2_pkg
