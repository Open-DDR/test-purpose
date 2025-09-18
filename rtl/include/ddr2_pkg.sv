//==============================================================================
// DDR2 Package
// 
// Description: Common definitions and parameters for DDR2 controller
// Author: Open DDR Project
// Date: 2025
//==============================================================================

package ddr2_pkg;

    // DDR2 Timing Parameters (in clock cycles)
    parameter int tRCD = 15;    // RAS to CAS delay
    parameter int tRP  = 15;    // Row precharge time
    parameter int tRAS = 40;    // Row active time
    parameter int tRC  = 55;    // Row cycle time
    parameter int tRRD = 10;    // Row to row delay
    parameter int tWR  = 15;    // Write recovery time
    parameter int tWTR = 7;     // Write to read delay
    parameter int tRTP = 7;     // Read to precharge delay
    parameter int tCCD = 2;     // Column to column delay
    parameter int tFAW = 45;    // Four bank activate window
    parameter int tREFI = 7800; // Refresh interval
    
    // DDR2 Commands
    typedef enum logic [3:0] {
        CMD_NOP  = 4'b0111,
        CMD_ACT  = 4'b0011,
        CMD_RD   = 4'b0101,
        CMD_WR   = 4'b0100,
        CMD_PRE  = 4'b0010,
        CMD_REF  = 4'b0001,
        CMD_MRS  = 4'b0000,
        CMD_DES  = 4'b1000
    } ddr2_cmd_t;
    
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
        CTRL_REFRESH    = 4'b0010,
        CTRL_ACTIVATE   = 4'b0011,
        CTRL_READ       = 4'b0100,
        CTRL_WRITE      = 4'b0101,
        CTRL_PRECHARGE  = 4'b0110,
        CTRL_POWER_DOWN = 4'b0111
    } ctrl_state_t;
    
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

endpackage : ddr2_pkg
