//==============================================================================
// OpenDDR Package
// 
// Description: Common definitions and parameters for OpenDDR controller
// Author: Open DDR Project
// Date: 2025
//==============================================================================

package openddr_pkg;

    // DDR Timing Parameters (in clock cycles)
    parameter int tRCD = 18;    // RAS to CAS delay
    parameter int tRP  = 18;    // Row precharge time
    parameter int tRAS = 42;    // Row active time
    parameter int tRC  = 60;    // Row cycle time
    parameter int tRRD = 8;     // Row to row delay
    parameter int tWR  = 15;    // Write recovery time
    parameter int tWTR = 8;     // Write to read delay
    parameter int tRTP = 8;     // Read to precharge delay
    parameter int tCCD = 4;     // Column to column delay
    parameter int tFAW = 40;    // Four bank activate window
    parameter int tREFI = 3120; // Refresh interval (7.8us @ 400MHz)
    
    // DDR Commands
    typedef enum logic [3:0] {
        CMD_NOP     = 4'b0111,
        CMD_ACT     = 4'b0011,
        CMD_RD      = 4'b0101,
        CMD_WR      = 4'b0100,
        CMD_PRE     = 4'b0010,
        CMD_PREA    = 4'b0010,
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

endpackage
