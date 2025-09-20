//==============================================================================
// OpenDDR Package - Enhanced with Timing Violation Detection
// 
// Description: Common definitions and parameters for OpenDDR controller
// Author: Open DDR Project - Enhanced for VS Code Extension
// Date: 2025
//==============================================================================

`timescale 1ns/1ps

package openddr_pkg;

    import ddr2_pkg::*;

    // Simulation Configuration
    parameter int SIMULATION_TIME_LIMIT = 100000; // ns
    parameter int MAX_TRANSACTIONS = 1000;
    parameter int CLOCK_PERIOD = 5; // ns (200MHz)

    // DDR Timing Parameters (preserved for compatibility)
    parameter int tRCD_cycles = 18;    // RAS to CAS delay
    parameter int tRP_cycles  = 18;    // Row precharge time
    parameter int tRAS_cycles = 42;    // Row active time
    parameter int tRC_cycles  = 60;    // Row cycle time
    parameter int tRRD_cycles = 8;     // Row to row delay
    parameter int tWR_cycles  = 15;    // Write recovery time
    parameter int tWTR_cycles = 8;     // Write to read delay
    parameter int tRTP_cycles = 8;     // Read to precharge delay
    parameter int tCCD_cycles = 4;     // Column to column delay
    parameter int tFAW_cycles = 40;    // Four bank activate window
    parameter int tREFI_cycles = 3120; // Refresh interval (7.8us @ 400MHz)

    // Test Configuration Types
    typedef enum logic [1:0] {
        TEST_SMOKE      = 2'b00,
        TEST_THROUGHPUT = 2'b01,
        TEST_CUSTOM     = 2'b10,
        TEST_VIOLATION  = 2'b11
    } test_type_t;

    typedef enum logic [1:0] {
        VIOLATION_MINOR    = 2'b00,
        VIOLATION_MODERATE = 2'b01,
        VIOLATION_SEVERE   = 2'b10,
        VIOLATION_CRITICAL = 2'b11
    } violation_severity_t;
    
    // DDR Commands (enhanced)
    typedef enum logic [3:0] {
        CMD_NOP     = 4'b0111,
        CMD_ACT     = 4'b0011,
        CMD_RD      = 4'b0101,
        CMD_WR      = 4'b0100,
        CMD_PRE     = 4'b0010,
        CMD_PREA    = 4'b1010,  // Precharge all
        CMD_REF     = 4'b0001,
        CMD_MRS     = 4'b0000,
        CMD_DES     = 4'b1000
    } ddr_cmd_t;
    
    // Bank States
    typedef enum logic [2:0] {
        BANK_IDLE       = 3'b000,
        BANK_ACTIVATING = 3'b001,
        BANK_ACTIVE     = 3'b010,
        BANK_READING    = 3'b011,
        BANK_WRITING    = 3'b100,
        BANK_PRECHARGE  = 3'b101
    } bank_state_t;
    
    // Controller States
    typedef enum logic [3:0] {
        CTRL_INIT       = 4'b0000,
        CTRL_IDLE       = 4'b0001,
        CTRL_ACTIVATE   = 4'b0010,
        CTRL_READ       = 4'b0011,
        CTRL_WRITE      = 4'b0100,
        CTRL_PRECHARGE  = 4'b0101,
        CTRL_REFRESH    = 4'b0110,
        CTRL_MRS        = 4'b0111,
        CTRL_WAIT       = 4'b1000
    } ctrl_state_t;

    // AXI Response codes
    typedef enum logic [1:0] {
        AXI_OKAY   = 2'b00,
        AXI_EXOKAY = 2'b01,
        AXI_SLVERR = 2'b10,
        AXI_DECERR = 2'b11
    } axi_resp_t;

    // DFI Command structure
    typedef struct packed {
        logic [1:0] cs;
        logic [6:0] address;
        logic       valid;
        logic [3:0] cmd_type;
    } dfi_cmd_t;

    // AXI Transaction structure
    typedef struct packed {
        logic [11:0] id;
        logic [39:0] addr;
        logic [7:0]  len;
        logic [2:0]  size;
        logic [1:0]  burst;
        logic [63:0] data;
        logic [7:0]  strb;
        logic        last;
        logic        valid;
        logic        ready;
    } axi_trans_t;

    // Memory Transaction Types
    typedef enum logic [2:0] {
        TXN_READ  = 3'b000,
        TXN_WRITE = 3'b001,
        TXN_RMW   = 3'b010, // Read-Modify-Write
        TXN_REFRESH = 3'b011,
        TXN_PRECHARGE_ALL = 3'b100
    } transaction_type_t;

    // Performance Counters
    typedef struct {
        int read_count;
        int write_count;
        int refresh_count;
        int bank_conflict_count;
        int timing_violation_count;
        real total_latency;
        real peak_bandwidth;
        real average_bandwidth;
    } performance_counters_t;

    // SystemC-RTL Interface signals
    typedef struct packed {
        logic        clk;
        logic        rst_n;
        axi_trans_t  axi_aw;
        axi_trans_t  axi_w;
        axi_trans_t  axi_b;
        axi_trans_t  axi_ar;
        axi_trans_t  axi_r;
        dfi_cmd_t    dfi_cmd_p0;
        dfi_cmd_t    dfi_cmd_p1;
        dfi_cmd_t    dfi_cmd_p2;
        dfi_cmd_t    dfi_cmd_p3;
    } systemc_rtl_if_t;

    // Utility Functions for Verilator Compatibility
    function automatic string get_violation_name(input logic [3:0] violation_type);
        case (violation_type)
            4'h0: return "tFAW";
            4'h1: return "tRCD";
            4'h2: return "tRP";
            4'h3: return "tRAS";
            4'h4: return "tRRD";
            4'h5: return "tWR";
            4'h6: return "tRTP";
            4'h7: return "tWTR";
            default: return "UNKNOWN";
        endcase
    endfunction

    function automatic real get_violation_factor(input violation_severity_t severity);
        case (severity)
            VIOLATION_MINOR:    return 0.9;   // 10% reduction
            VIOLATION_MODERATE: return 0.75;  // 25% reduction
            VIOLATION_SEVERE:   return 0.5;   // 50% reduction
            VIOLATION_CRITICAL: return 0.25;  // 75% reduction
            default:            return 1.0;
        endcase
    endfunction

    // Timing violation checking function
    function automatic logic check_timing_violation(
        input real current_time,
        input real reference_time,
        input real required_delay,
        input string violation_name
    );
        if ((current_time - reference_time) < required_delay) begin
            return 1'b1;
        end
        return 1'b0;
    endfunction

endpackage
