#ifndef OPENDDR_SYSTEMC_MODEL_H
#define OPENDDR_SYSTEMC_MODEL_H

#define SC_INCLUDE_DYNAMIC_PROCESSES
#include <systemc.h>
#include <vector>
#include <queue>
#include <map>

// Forward declarations
struct AXITransaction;
struct DDRCommand;
struct BufferEntry;

// Constants for DDRCommand struct
static const int ROW_WIDTH = 16;
static const int BUF_ADR_WIDTH = 7;

// SystemC model for OpenDDR DDR Memory Controller
SC_MODULE(OpenDDRSystemCModel) {
    // Clock and Reset
    sc_in<bool> mck;
    sc_in<bool> mc_rst_b;
    sc_in<bool> porst_b;
    sc_in<bool> slow_clk;

    // AXI Port 0 Interface
    sc_in<bool> mc0_aclk;
    sc_in<bool> mc0_aresetn;
    
    // AXI Write Address Channel
    sc_in<sc_uint<12>> mc0_axi_awid;
    sc_in<sc_uint<40>> mc0_axi_awaddr;
    sc_in<sc_uint<8>> mc0_axi_awlen;
    sc_in<sc_uint<3>> mc0_axi_awsize;
    sc_in<sc_uint<2>> mc0_axi_awburst;
    sc_in<bool> mc0_axi_awlock;
    sc_in<sc_uint<4>> mc0_axi_awcache;
    sc_in<sc_uint<3>> mc0_axi_awprot;
    sc_in<sc_uint<4>> mc0_axi_awqos;
    sc_in<bool> mc0_axi_awvalid;
    sc_out<bool> mc0_axi_awready;
    // AXI Write Data Channel
    sc_in<sc_uint<64>> mc0_axi_wdata;
    sc_in<sc_uint<8>> mc0_axi_wstrb;
    sc_in<bool> mc0_axi_wlast;
    sc_in<bool> mc0_axi_wvalid;
    sc_out<bool> mc0_axi_wready;

    // AXI Write Response Channel
    sc_out<sc_uint<12>> mc0_axi_bid;
    sc_out<sc_uint<2>> mc0_axi_bresp;
    sc_out<bool> mc0_axi_bvalid;
    sc_in<bool> mc0_axi_bready;

    // AXI Read Address Channel
    sc_in<sc_uint<12>> mc0_axi_arid;
    sc_in<sc_uint<40>> mc0_axi_araddr;
    sc_in<sc_uint<8>> mc0_axi_arlen;
    sc_in<sc_uint<3>> mc0_axi_arsize;
    sc_in<sc_uint<2>> mc0_axi_arburst;
    sc_in<bool> mc0_axi_arlock;
    sc_in<sc_uint<4>> mc0_axi_arcache;
    sc_in<sc_uint<3>> mc0_axi_arprot;
    sc_in<sc_uint<4>> mc0_axi_arqos;
    sc_in<bool> mc0_axi_arvalid;
    sc_out<bool> mc0_axi_arready;

    // AXI Read Data Channel
    sc_out<sc_uint<12>> mc0_axi_rid;
    sc_out<sc_uint<64>> mc0_axi_rdata;
    sc_out<sc_uint<2>> mc0_axi_rresp;
    sc_out<bool> mc0_axi_rlast;
    sc_out<bool> mc0_axi_rvalid;
    sc_in<bool> mc0_axi_rready;

    // APB Interface
    sc_in<bool> mc_penable;
    sc_in<bool> mc_psel;
    sc_in<bool> mc_pwr;
    sc_in<sc_uint<10>> mc_paddr;
    sc_in<sc_uint<32>> mc_pwdata;
    sc_out<sc_uint<32>> mc_prdata;
    sc_out<bool> mc_pready;
    sc_out<bool> mc_pslverr;

    // DFI Command Interface (DDR)
    sc_out<sc_uint<2>> dfi_dram_clk_disable_0;
    sc_out<sc_uint<2>> dfi_dram_clk_disable_1;
    sc_out<bool> dfi_dram_ca_disable;
    sc_out<sc_uint<2>> dfi_cs_0_p0;
    sc_out<sc_uint<2>> dfi_cs_0_p1;
    sc_out<sc_uint<2>> dfi_cs_1_p2;
    sc_out<sc_uint<2>> dfi_cs_1_p3;
    sc_out<sc_uint<7>> dfi_address_0_p0;
    sc_out<sc_uint<7>> dfi_address_0_p1;
    sc_out<sc_uint<7>> dfi_address_1_p2;
    sc_out<sc_uint<7>> dfi_address_1_p3;
    sc_out<bool> dfi_reset_n;

    // DFI WCK Control Interface
    sc_out<sc_uint<4>> dfi_wck_cs;
    sc_out<sc_uint<4>> dfi_wck_en;
    sc_out<sc_uint<2>> dfi_wck_toggle;

    // DFI Write Data Interface (DDRx - 16 phases)
    sc_out<sc_uint<32>> dfi_wrdata_0;
    sc_out<sc_uint<32>> dfi_wrdata_1;
    sc_out<sc_uint<32>> dfi_wrdata_2;
    sc_out<sc_uint<32>> dfi_wrdata_3;
    sc_out<sc_uint<32>> dfi_wrdata_4;
    sc_out<sc_uint<32>> dfi_wrdata_5;
    sc_out<sc_uint<32>> dfi_wrdata_6;
    sc_out<sc_uint<32>> dfi_wrdata_7;
    sc_out<sc_uint<32>> dfi_wrdata_8;
    sc_out<sc_uint<32>> dfi_wrdata_9;
    sc_out<sc_uint<32>> dfi_wrdata_10;
    sc_out<sc_uint<32>> dfi_wrdata_11;
    sc_out<sc_uint<32>> dfi_wrdata_12;
    sc_out<sc_uint<32>> dfi_wrdata_13;
    sc_out<sc_uint<32>> dfi_wrdata_14;
    sc_out<sc_uint<32>> dfi_wrdata_15;

    // DFI Write Data Mask
    sc_out<sc_uint<4>> dfi_wrdata_mask_0;
    sc_out<sc_uint<4>> dfi_wrdata_mask_1;
    sc_out<sc_uint<4>> dfi_wrdata_mask_2;
    sc_out<sc_uint<4>> dfi_wrdata_mask_3;
    sc_out<sc_uint<4>> dfi_wrdata_mask_4;
    sc_out<sc_uint<4>> dfi_wrdata_mask_5;
    sc_out<sc_uint<4>> dfi_wrdata_mask_6;
    sc_out<sc_uint<4>> dfi_wrdata_mask_7;
    sc_out<sc_uint<4>> dfi_wrdata_mask_8;
    sc_out<sc_uint<4>> dfi_wrdata_mask_9;
    sc_out<sc_uint<4>> dfi_wrdata_mask_10;
    sc_out<sc_uint<4>> dfi_wrdata_mask_11;
    sc_out<sc_uint<4>> dfi_wrdata_mask_12;
    sc_out<sc_uint<4>> dfi_wrdata_mask_13;
    sc_out<sc_uint<4>> dfi_wrdata_mask_14;
    sc_out<sc_uint<4>> dfi_wrdata_mask_15;

    // DFI Write Data Enable
    sc_out<sc_uint<4>> dfi_wrdata_en_0;
    sc_out<sc_uint<4>> dfi_wrdata_en_1;
    sc_out<sc_uint<4>> dfi_wrdata_en_2;
    sc_out<sc_uint<4>> dfi_wrdata_en_3;
    sc_out<sc_uint<4>> dfi_wrdata_en_4;
    sc_out<sc_uint<4>> dfi_wrdata_en_5;
    sc_out<sc_uint<4>> dfi_wrdata_en_6;
    sc_out<sc_uint<4>> dfi_wrdata_en_7;
    sc_out<sc_uint<4>> dfi_wrdata_en_8;
    sc_out<sc_uint<4>> dfi_wrdata_en_9;
    sc_out<sc_uint<4>> dfi_wrdata_en_10;
    sc_out<sc_uint<4>> dfi_wrdata_en_11;
    sc_out<sc_uint<4>> dfi_wrdata_en_12;
    sc_out<sc_uint<4>> dfi_wrdata_en_13;
    sc_out<sc_uint<4>> dfi_wrdata_en_14;
    sc_out<sc_uint<4>> dfi_wrdata_en_15;

    // DFI Read Data Interface
    sc_out<bool> mc_rdrst_b;
    sc_out<bool> mc_rcv_en;
    sc_out<bool> dfi_rddata_en;
    sc_in<bool> dfi_rddata_valid;

    sc_in<sc_uint<32>> dfi_rddata_0;
    sc_in<sc_uint<32>> dfi_rddata_1;
    sc_in<sc_uint<32>> dfi_rddata_2;
    sc_in<sc_uint<32>> dfi_rddata_3;
    sc_in<sc_uint<32>> dfi_rddata_4;
    sc_in<sc_uint<32>> dfi_rddata_5;
    sc_in<sc_uint<32>> dfi_rddata_6;
    sc_in<sc_uint<32>> dfi_rddata_7;
    sc_in<sc_uint<32>> dfi_rddata_8;
    sc_in<sc_uint<32>> dfi_rddata_9;
    sc_in<sc_uint<32>> dfi_rddata_10;
    sc_in<sc_uint<32>> dfi_rddata_11;
    sc_in<sc_uint<32>> dfi_rddata_12;
    sc_in<sc_uint<32>> dfi_rddata_13;
    sc_in<sc_uint<32>> dfi_rddata_14;
    sc_in<sc_uint<32>> dfi_rddata_15;

    // Internal signals and variables
    sc_signal<bool> mc0_axi_awready_int;
    sc_signal<bool> mc0_axi_wready_int;
    sc_signal<bool> mc0_axi_bvalid_int;
    sc_signal<bool> mc0_axi_arready_int;
    sc_signal<bool> mc0_axi_rvalid_int;
    sc_signal<sc_uint<32>> mc_prdata_int;
    sc_signal<bool> mc_pready_int;

    // Configuration registers
    sc_uint<32> seq_control_reg;
    sc_uint<32> buf_config_reg;
    sc_uint<32> ddr_config_reg;
    sc_uint<32> ddr_adr_config_reg;
    sc_uint<32> pmu_cmd_reg;
    sc_uint<32> pmu_mrs_reg;
    sc_uint<32> pmu_mpc_reg;
    sc_uint<32> pmu_status_reg;
    sc_uint<32> ac_timing_reg1;
    sc_uint<32> ac_timing_reg2;
    sc_uint<32> ac_timing_reg3;
    sc_uint<32> ac_timing_reg4;
    sc_uint<32> ac_timing_reg5;
    sc_uint<32> ac_timing_reg6;
    sc_uint<32> ac_timing_reg7;
    sc_uint<32> ac_timing_reg8;
    sc_uint<32> ac_timing_reg9;
    sc_uint<32> ac_timing_reg10;
    sc_uint<32> refresh_cntrl_reg;
    sc_uint<32> test_config_reg;

    // Internal state variables
    enum SequencerState {
        SEQ_IDLE = 0,
        SEQ_W_ACT = 1,
        SEQ_W_WR = 2,
        SEQ_W_RD = 3,
        SEQ_W_PRE = 4,
        SEQ_W_REF = 5,
        SEQ_W_MRS = 6,
        SEQ_W_SLFR = 7
    };

    SequencerState seq_state;
    bool ddr_init_done;
    bool bufacc_cycle_en;
    bool bufacc_cycle_mode_wr;

    // Buffer structures
    static const int BUF_DEPTH = 128;
    static const int WRBUF_DATA_WIDTH = 256;
    static const int RDBUF_DATA_WIDTH = 256;
    static const int CMD_WIDTH = 59;

    // Write buffer
    std::vector<bool> wbuf_cmd_vld_memory;
    std::vector<sc_uint<CMD_WIDTH>> wbuf_cmd_memory;
    std::vector<sc_biguint<WRBUF_DATA_WIDTH>> wbuf_data_memory;
    std::vector<sc_uint<WRBUF_DATA_WIDTH/8>> wbuf_data_vld_memory;

    // Read buffer
    std::vector<bool> rbuf_cmd_vld_memory;
    std::vector<sc_uint<CMD_WIDTH>> rbuf_cmd_memory;
    std::vector<sc_biguint<RDBUF_DATA_WIDTH>> rbuf_data_memory;
    std::vector<bool> rbuf_data_vld_memory;

    // Page table for open page policy
    static const int PAGE_TABLE_DEPTH = 16;
    std::vector<bool> page_table_vld_memory;
    std::vector<sc_uint<ROW_WIDTH>> page_table_row_memory;

    // AXI transaction queues
    std::queue<AXITransaction> write_addr_queue;
    std::queue<AXITransaction> write_data_queue;
    std::queue<AXITransaction> write_resp_queue;
    std::queue<AXITransaction> read_addr_queue;
    std::queue<AXITransaction> read_resp_queue;

    // DDR command queue
    std::queue<DDRCommand> ddr_cmd_queue;

    // Timing counters
    sc_uint<16> refresh_counter;
    sc_uint<8> refresh_pending_counter;
    std::map<int, sc_uint<16>> bank_timers; // For tRAS, tRP, etc.

    // Statistics and debug
    sc_uint<32> total_write_transactions;
    sc_uint<32> total_read_transactions;
    sc_uint<32> total_ddr_commands;
    sc_uint<32> page_hits;
    sc_uint<32> page_misses;

    // Constructor
    SC_CTOR(OpenDDRSystemCModel) : 
        wbuf_cmd_vld_memory(BUF_DEPTH, false),
        wbuf_cmd_memory(BUF_DEPTH, 0),
        wbuf_data_memory(BUF_DEPTH, 0),
        wbuf_data_vld_memory(BUF_DEPTH, 0),
        rbuf_cmd_vld_memory(BUF_DEPTH, false),
        rbuf_cmd_memory(BUF_DEPTH, 0),
        rbuf_data_memory(BUF_DEPTH, 0),
        rbuf_data_vld_memory(BUF_DEPTH, false),
        page_table_vld_memory(PAGE_TABLE_DEPTH, false),
        page_table_row_memory(PAGE_TABLE_DEPTH, 0)
    {
        // Initialize state
        seq_state = SEQ_IDLE;
        ddr_init_done = false;
        bufacc_cycle_en = false;
        bufacc_cycle_mode_wr = false;
        refresh_counter = 0;
        refresh_pending_counter = 0;
        total_write_transactions = 0;
        total_read_transactions = 0;
        total_ddr_commands = 0;
        page_hits = 0;
        page_misses = 0;

        // Initialize configuration registers with default values
        seq_control_reg = 0x00000001; // DDR init done
        buf_config_reg = 0x00000000;
        ddr_config_reg = 0x00030000; // DDR, 32-bit data width, BL32
        ddr_adr_config_reg = 0x00000000;
        pmu_cmd_reg = 0x00000000;
        pmu_mrs_reg = 0x00000000;
        pmu_mpc_reg = 0x00000000;
        pmu_status_reg = 0x00000030; // SEQ TYPE = DDRx
        refresh_cntrl_reg = 0x00001F40; // Enable refresh, tREF = 7.8us
        test_config_reg = 0x00000000;

        // Set timing registers (example values for DDR)
        ac_timing_reg1 = 0x12345678; // tCL, tWL, etc.
        ac_timing_reg2 = 0x9ABCDEF0;
        ac_timing_reg3 = 0x11223344;
        ac_timing_reg4 = 0x55667788;
        ac_timing_reg5 = 0x99AABBCC;
        ac_timing_reg6 = 0xDDEEFF00;
        ac_timing_reg7 = 0x12345678;
        ac_timing_reg8 = 0x9ABCDEF0;
        ac_timing_reg9 = 0x11223344;
        ac_timing_reg10 = 0x55667788;

        // Register processes
        SC_METHOD(axi_write_addr_process);
        sensitive << mck.pos();
        dont_initialize();

        SC_METHOD(axi_write_data_process);
        sensitive << mck.pos();
        dont_initialize();

        SC_METHOD(axi_write_resp_process);
        sensitive << mck.pos();
        dont_initialize();

        SC_METHOD(axi_read_addr_process);
        sensitive << mck.pos();
        dont_initialize();

        SC_METHOD(axi_read_data_process);
        sensitive << mck.pos();
        dont_initialize();

        SC_METHOD(apb_process);
        sensitive << mck.pos();
        dont_initialize();

        SC_METHOD(scheduler_process);
        sensitive << mck.pos();
        dont_initialize();

        SC_METHOD(sequencer_process);
        sensitive << mck.pos();
        dont_initialize();

        SC_METHOD(dfi_command_process);
        sensitive << mck.pos();
        dont_initialize();

        SC_METHOD(dfi_write_data_process);
        sensitive << mck.pos();
        dont_initialize();

        SC_METHOD(dfi_read_data_process);
        sensitive << mck.pos();
        dont_initialize();

        SC_METHOD(refresh_timer_process);
        sensitive << slow_clk.pos();
        dont_initialize();

        // Note: Internal signals will be connected to outputs in the processes
    }

    // Process declarations
    void axi_write_addr_process();
    void axi_write_data_process();
    void axi_write_resp_process();
    void axi_read_addr_process();
    void axi_read_data_process();
    void apb_process();
    void scheduler_process();
    void sequencer_process();
    void dfi_command_process();
    void dfi_write_data_process();
    void dfi_read_data_process();
    void refresh_timer_process();

    // Helper functions
    void reset_model();
    void update_page_table(int bank, sc_uint<ROW_WIDTH> row, bool open);
    bool check_page_hit(int bank, sc_uint<ROW_WIDTH> row);
    void schedule_ddr_command(const DDRCommand& cmd);
    void execute_ddr_command(const DDRCommand& cmd);
    sc_uint<32> read_register(sc_uint<10> addr);
    void write_register(sc_uint<10> addr, sc_uint<32> data);
    void decode_address(sc_uint<40> addr, int& rank, int& bank, sc_uint<ROW_WIDTH>& row, sc_uint<10>& col);
    void print_statistics();
};

// AXI Transaction structure
struct AXITransaction {
    sc_uint<12> id;
    sc_uint<40> addr;
    sc_uint<8> len;
    sc_uint<3> size;
    sc_uint<2> burst;
    sc_uint<64> data;
    sc_uint<8> strb;
    bool last;
    sc_uint<2> resp;
    bool is_write;
    sc_time timestamp;

    AXITransaction() : id(0), addr(0), len(0), size(0), burst(0), 
                      data(0), strb(0), last(false), resp(0), 
                      is_write(false), timestamp(sc_time_stamp()) {}
};

// DDR Command structure
struct DDRCommand {
    enum CommandType {
        CMD_NOP = 0,
        CMD_ACT = 1,
        CMD_READ = 2,
        CMD_WRITE = 3,
        CMD_PRE = 4,
        CMD_PREA = 5,
        CMD_REF = 6,
        CMD_MRS = 7,
        CMD_MPC = 8,
        CMD_SLFR_ENTRY = 9,
        CMD_SLFR_EXIT = 10
    };

    CommandType cmd_type;
    int rank;
    int bank;
    sc_uint<ROW_WIDTH> row;
    sc_uint<10> col;
    sc_uint<32> data[16]; // For write data (16 phases)
    sc_uint<4> mask[16];  // For write mask
    sc_uint<BUF_ADR_WIDTH> buf_index;
    sc_time issue_time;
    sc_time execute_time;

    DDRCommand() : cmd_type(CMD_NOP), rank(0), bank(0), row(0), col(0),
                   buf_index(0), issue_time(sc_time_stamp()), 
                   execute_time(sc_time_stamp()) {
        for(int i = 0; i < 16; i++) {
            data[i] = 0;
            mask[i] = 0;
        }
    }
};

#endif // OPENDDR_SYSTEMC_MODEL_H
