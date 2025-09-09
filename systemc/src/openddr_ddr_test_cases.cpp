#include "openddr_systemc_model_enhanced.h"
#include <systemc.h>
#include <iostream>
#include <iomanip>
#include <vector>
#include <random>
#include <map>

// DDR-Specific Test Cases for openddr SystemC Model
SC_MODULE(openddrDDRTestCases) {
    // Clock and reset signals
    sc_clock mck;
    sc_signal<bool> mc_rst_b;
    sc_signal<bool> porst_b;
    sc_clock slow_clk;

    // AXI Port 0 signals
    sc_clock mc0_aclk;
    sc_signal<bool> mc0_aresetn;
    
    // AXI Write Address Channel
    sc_signal<sc_uint<12>> mc0_axi_awid;
    sc_signal<sc_uint<40>> mc0_axi_awaddr;
    sc_signal<sc_uint<8>> mc0_axi_awlen;
    sc_signal<sc_uint<3>> mc0_axi_awsize;
    sc_signal<sc_uint<2>> mc0_axi_awburst;
    sc_signal<bool> mc0_axi_awlock;
    sc_signal<sc_uint<4>> mc0_axi_awcache;
    sc_signal<sc_uint<3>> mc0_axi_awprot;
    sc_signal<sc_uint<4>> mc0_axi_awqos;
    sc_signal<bool> mc0_axi_awvalid;
    sc_signal<bool> mc0_axi_awready;

    // AXI Write Data Channel
    sc_signal<sc_uint<64>> mc0_axi_wdata;
    sc_signal<sc_uint<8>> mc0_axi_wstrb;
    sc_signal<bool> mc0_axi_wlast;
    sc_signal<bool> mc0_axi_wvalid;
    sc_signal<bool> mc0_axi_wready;

    // AXI Write Response Channel
    sc_signal<sc_uint<12>> mc0_axi_bid;
    sc_signal<sc_uint<2>> mc0_axi_bresp;
    sc_signal<bool> mc0_axi_bvalid;
    sc_signal<bool> mc0_axi_bready;

    // AXI Read Address Channel
    sc_signal<sc_uint<12>> mc0_axi_arid;
    sc_signal<sc_uint<40>> mc0_axi_araddr;
    sc_signal<sc_uint<8>> mc0_axi_arlen;
    sc_signal<sc_uint<3>> mc0_axi_arsize;
    sc_signal<sc_uint<2>> mc0_axi_arburst;
    sc_signal<bool> mc0_axi_arlock;
    sc_signal<sc_uint<4>> mc0_axi_arcache;
    sc_signal<sc_uint<3>> mc0_axi_arprot;
    sc_signal<sc_uint<4>> mc0_axi_arqos;
    sc_signal<bool> mc0_axi_arvalid;
    sc_signal<bool> mc0_axi_arready;

    // AXI Read Data Channel
    sc_signal<sc_uint<12>> mc0_axi_rid;
    sc_signal<sc_uint<64>> mc0_axi_rdata;
    sc_signal<sc_uint<2>> mc0_axi_rresp;
    sc_signal<bool> mc0_axi_rlast;
    sc_signal<bool> mc0_axi_rvalid;
    sc_signal<bool> mc0_axi_rready;

    // APB Interface
    sc_signal<bool> mc_penable;
    sc_signal<bool> mc_psel;
    sc_signal<bool> mc_pwr;
    sc_signal<sc_uint<10>> mc_paddr;
    sc_signal<sc_uint<32>> mc_pwdata;
    sc_signal<sc_uint<32>> mc_prdata;
    sc_signal<bool> mc_pready;
    sc_signal<bool> mc_pslverr;

    // DFI Command Interface
    sc_signal<sc_uint<2>> dfi_dram_clk_disable_0;
    sc_signal<sc_uint<2>> dfi_dram_clk_disable_1;
    sc_signal<bool> dfi_dram_ca_disable;
    sc_signal<sc_uint<2>> dfi_cs_0_p0;
    sc_signal<sc_uint<2>> dfi_cs_0_p1;
    sc_signal<sc_uint<2>> dfi_cs_1_p2;
    sc_signal<sc_uint<2>> dfi_cs_1_p3;
    sc_signal<sc_uint<7>> dfi_address_0_p0;
    sc_signal<sc_uint<7>> dfi_address_0_p1;
    sc_signal<sc_uint<7>> dfi_address_1_p2;
    sc_signal<sc_uint<7>> dfi_address_1_p3;
    sc_signal<bool> dfi_reset_n;

    // DFI WCK Control Interface (DDR-specific)
    sc_signal<sc_uint<4>> dfi_wck_cs;
    sc_signal<sc_uint<4>> dfi_wck_en;
    sc_signal<sc_uint<2>> dfi_wck_toggle;

    // DFI Write Data Interface (16 phases for DDR)
    sc_signal<sc_uint<32>> dfi_wrdata_0;
    sc_signal<sc_uint<32>> dfi_wrdata_1;
    sc_signal<sc_uint<32>> dfi_wrdata_2;
    sc_signal<sc_uint<32>> dfi_wrdata_3;
    sc_signal<sc_uint<32>> dfi_wrdata_4;
    sc_signal<sc_uint<32>> dfi_wrdata_5;
    sc_signal<sc_uint<32>> dfi_wrdata_6;
    sc_signal<sc_uint<32>> dfi_wrdata_7;
    sc_signal<sc_uint<32>> dfi_wrdata_8;
    sc_signal<sc_uint<32>> dfi_wrdata_9;
    sc_signal<sc_uint<32>> dfi_wrdata_10;
    sc_signal<sc_uint<32>> dfi_wrdata_11;
    sc_signal<sc_uint<32>> dfi_wrdata_12;
    sc_signal<sc_uint<32>> dfi_wrdata_13;
    sc_signal<sc_uint<32>> dfi_wrdata_14;
    sc_signal<sc_uint<32>> dfi_wrdata_15;

    // DFI Write Data Mask and Enable
    sc_signal<sc_uint<4>> dfi_wrdata_mask_0;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_1;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_2;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_3;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_4;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_5;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_6;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_7;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_8;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_9;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_10;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_11;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_12;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_13;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_14;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_15;

    sc_signal<sc_uint<4>> dfi_wrdata_en_0;
    sc_signal<sc_uint<4>> dfi_wrdata_en_1;
    sc_signal<sc_uint<4>> dfi_wrdata_en_2;
    sc_signal<sc_uint<4>> dfi_wrdata_en_3;
    sc_signal<sc_uint<4>> dfi_wrdata_en_4;
    sc_signal<sc_uint<4>> dfi_wrdata_en_5;
    sc_signal<sc_uint<4>> dfi_wrdata_en_6;
    sc_signal<sc_uint<4>> dfi_wrdata_en_7;
    sc_signal<sc_uint<4>> dfi_wrdata_en_8;
    sc_signal<sc_uint<4>> dfi_wrdata_en_9;
    sc_signal<sc_uint<4>> dfi_wrdata_en_10;
    sc_signal<sc_uint<4>> dfi_wrdata_en_11;
    sc_signal<sc_uint<4>> dfi_wrdata_en_12;
    sc_signal<sc_uint<4>> dfi_wrdata_en_13;
    sc_signal<sc_uint<4>> dfi_wrdata_en_14;
    sc_signal<sc_uint<4>> dfi_wrdata_en_15;

    // DFI Read Data Interface
    sc_signal<bool> mc_rdrst_b;
    sc_signal<bool> mc_rcv_en;
    sc_signal<bool> dfi_rddata_en;
    sc_signal<bool> dfi_rddata_valid;

    sc_signal<sc_uint<32>> dfi_rddata_0;
    sc_signal<sc_uint<32>> dfi_rddata_1;
    sc_signal<sc_uint<32>> dfi_rddata_2;
    sc_signal<sc_uint<32>> dfi_rddata_3;
    sc_signal<sc_uint<32>> dfi_rddata_4;
    sc_signal<sc_uint<32>> dfi_rddata_5;
    sc_signal<sc_uint<32>> dfi_rddata_6;
    sc_signal<sc_uint<32>> dfi_rddata_7;
    sc_signal<sc_uint<32>> dfi_rddata_8;
    sc_signal<sc_uint<32>> dfi_rddata_9;
    sc_signal<sc_uint<32>> dfi_rddata_10;
    sc_signal<sc_uint<32>> dfi_rddata_11;
    sc_signal<sc_uint<32>> dfi_rddata_12;
    sc_signal<sc_uint<32>> dfi_rddata_13;
    sc_signal<sc_uint<32>> dfi_rddata_14;
    sc_signal<sc_uint<32>> dfi_rddata_15;

    // DUT instance
    openddrSystemCModelEnhanced* dut;

    // Test control variables
    std::mt19937 random_gen;
    int test_errors;
    int test_passed;
    int current_test_id;
    std::map<sc_uint<40>, sc_uint<64>> memory_model;  // Simple memory model for verification

    // Constructor
    SC_CTOR(openddrDDRTestCases) : 
        mck("mck", 5, SC_NS),           // 200MHz main clock
        slow_clk("slow_clk", 40, SC_NS), // 25MHz slow clock
        mc0_aclk("mc0_aclk", 5, SC_NS),  // 200MHz AXI clock
        random_gen(std::random_device{}()),
        test_errors(0),
        test_passed(0),
        current_test_id(0)
    {
        // Create DUT instance
        dut = new openddrSystemCModelEnhanced("dut");

        // Connect all signals
        connect_signals();

        // Initialize all signals to safe values
        initialize_signals();

        // Register test processes
        SC_THREAD(reset_sequence);
        SC_THREAD(DDR_test_suite);
        SC_THREAD(dfi_read_data_driver);
        SC_THREAD(wck_monitor);
    }

    ~openddrDDRTestCases() {
        delete dut;
    }

    void connect_signals();
    void initialize_signals();
    void reset_sequence();
    void DDR_test_suite();
    void dfi_read_data_driver();
    void wck_monitor();

    // DDR-Specific Test Cases
    void test_case_1_bl32_burst_operations();
    void test_case_2_wck_training_sequence();
    void test_case_3_bank_group_interleaving();
    void test_case_4_refresh_management_DDR();
    void test_case_5_power_management_features();

    // Helper functions
    void axi_write_transaction(sc_uint<12> id, sc_uint<40> addr, sc_uint<64> data, sc_uint<8> len = 0, sc_uint<8> strb = 0xFF);
    void axi_read_transaction(sc_uint<12> id, sc_uint<40> addr, sc_uint<8> len = 0);
    void apb_write(sc_uint<10> addr, sc_uint<32> data);
    sc_uint<32> apb_read(sc_uint<10> addr);
    void configure_DDR_timing();
    void configure_DDR_mode_registers();
    void wait_for_wck_training();
    void verify_dfi_command_sequence(const std::string& expected_sequence);
    void print_test_results();
};

void openddrDDRTestCases::connect_signals() {
    // Connect clocks and resets
    dut->mck(mck);
    dut->mc_rst_b(mc_rst_b);
    dut->porst_b(porst_b);
    dut->slow_clk(slow_clk);

    // Connect AXI Port 0
    dut->mc0_aclk(mc0_aclk);
    dut->mc0_aresetn(mc0_aresetn);
    
    // AXI Write Address Channel
    dut->mc0_axi_awid(mc0_axi_awid);
    dut->mc0_axi_awaddr(mc0_axi_awaddr);
    dut->mc0_axi_awlen(mc0_axi_awlen);
    dut->mc0_axi_awsize(mc0_axi_awsize);
    dut->mc0_axi_awburst(mc0_axi_awburst);
    dut->mc0_axi_awlock(mc0_axi_awlock);
    dut->mc0_axi_awcache(mc0_axi_awcache);
    dut->mc0_axi_awprot(mc0_axi_awprot);
    dut->mc0_axi_awqos(mc0_axi_awqos);
    dut->mc0_axi_awvalid(mc0_axi_awvalid);
    dut->mc0_axi_awready(mc0_axi_awready);

    // AXI Write Data Channel
    dut->mc0_axi_wdata(mc0_axi_wdata);
    dut->mc0_axi_wstrb(mc0_axi_wstrb);
    dut->mc0_axi_wlast(mc0_axi_wlast);
    dut->mc0_axi_wvalid(mc0_axi_wvalid);
    dut->mc0_axi_wready(mc0_axi_wready);

    // AXI Write Response Channel
    dut->mc0_axi_bid(mc0_axi_bid);
    dut->mc0_axi_bresp(mc0_axi_bresp);
    dut->mc0_axi_bvalid(mc0_axi_bvalid);
    dut->mc0_axi_bready(mc0_axi_bready);

    // AXI Read Address Channel
    dut->mc0_axi_arid(mc0_axi_arid);
    dut->mc0_axi_araddr(mc0_axi_araddr);
    dut->mc0_axi_arlen(mc0_axi_arlen);
    dut->mc0_axi_arsize(mc0_axi_arsize);
    dut->mc0_axi_arburst(mc0_axi_arburst);
    dut->mc0_axi_arlock(mc0_axi_arlock);
    dut->mc0_axi_arcache(mc0_axi_arcache);
    dut->mc0_axi_arprot(mc0_axi_arprot);
    dut->mc0_axi_arqos(mc0_axi_arqos);
    dut->mc0_axi_arvalid(mc0_axi_arvalid);
    dut->mc0_axi_arready(mc0_axi_arready);

    // AXI Read Data Channel
    dut->mc0_axi_rid(mc0_axi_rid);
    dut->mc0_axi_rdata(mc0_axi_rdata);
    dut->mc0_axi_rresp(mc0_axi_rresp);
    dut->mc0_axi_rlast(mc0_axi_rlast);
    dut->mc0_axi_rvalid(mc0_axi_rvalid);
    dut->mc0_axi_rready(mc0_axi_rready);

    // Connect APB Interface
    dut->mc_penable(mc_penable);
    dut->mc_psel(mc_psel);
    dut->mc_pwr(mc_pwr);
    dut->mc_paddr(mc_paddr);
    dut->mc_pwdata(mc_pwdata);
    dut->mc_prdata(mc_prdata);
    dut->mc_pready(mc_pready);
    dut->mc_pslverr(mc_pslverr);

    // Connect DFI Command Interface
    dut->dfi_dram_clk_disable_0(dfi_dram_clk_disable_0);
    dut->dfi_dram_clk_disable_1(dfi_dram_clk_disable_1);
    dut->dfi_dram_ca_disable(dfi_dram_ca_disable);
    dut->dfi_cs_0_p0(dfi_cs_0_p0);
    dut->dfi_cs_0_p1(dfi_cs_0_p1);
    dut->dfi_cs_1_p2(dfi_cs_1_p2);
    dut->dfi_cs_1_p3(dfi_cs_1_p3);
    dut->dfi_address_0_p0(dfi_address_0_p0);
    dut->dfi_address_0_p1(dfi_address_0_p1);
    dut->dfi_address_1_p2(dfi_address_1_p2);
    dut->dfi_address_1_p3(dfi_address_1_p3);
    dut->dfi_reset_n(dfi_reset_n);

    // Connect DFI WCK Control (DDR-specific)
    dut->dfi_wck_cs(dfi_wck_cs);
    dut->dfi_wck_en(dfi_wck_en);
    dut->dfi_wck_toggle(dfi_wck_toggle);

    // Connect all 16 DFI Write Data phases
    dut->dfi_wrdata_0(dfi_wrdata_0);
    dut->dfi_wrdata_1(dfi_wrdata_1);
    dut->dfi_wrdata_2(dfi_wrdata_2);
    dut->dfi_wrdata_3(dfi_wrdata_3);
    dut->dfi_wrdata_4(dfi_wrdata_4);
    dut->dfi_wrdata_5(dfi_wrdata_5);
    dut->dfi_wrdata_6(dfi_wrdata_6);
    dut->dfi_wrdata_7(dfi_wrdata_7);
    dut->dfi_wrdata_8(dfi_wrdata_8);
    dut->dfi_wrdata_9(dfi_wrdata_9);
    dut->dfi_wrdata_10(dfi_wrdata_10);
    dut->dfi_wrdata_11(dfi_wrdata_11);
    dut->dfi_wrdata_12(dfi_wrdata_12);
    dut->dfi_wrdata_13(dfi_wrdata_13);
    dut->dfi_wrdata_14(dfi_wrdata_14);
    dut->dfi_wrdata_15(dfi_wrdata_15);

    // Connect DFI Write Data Masks and Enables
    dut->dfi_wrdata_mask_0(dfi_wrdata_mask_0);
    dut->dfi_wrdata_mask_1(dfi_wrdata_mask_1);
    dut->dfi_wrdata_mask_2(dfi_wrdata_mask_2);
    dut->dfi_wrdata_mask_3(dfi_wrdata_mask_3);
    dut->dfi_wrdata_mask_4(dfi_wrdata_mask_4);
    dut->dfi_wrdata_mask_5(dfi_wrdata_mask_5);
    dut->dfi_wrdata_mask_6(dfi_wrdata_mask_6);
    dut->dfi_wrdata_mask_7(dfi_wrdata_mask_7);
    dut->dfi_wrdata_mask_8(dfi_wrdata_mask_8);
    dut->dfi_wrdata_mask_9(dfi_wrdata_mask_9);
    dut->dfi_wrdata_mask_10(dfi_wrdata_mask_10);
    dut->dfi_wrdata_mask_11(dfi_wrdata_mask_11);
    dut->dfi_wrdata_mask_12(dfi_wrdata_mask_12);
    dut->dfi_wrdata_mask_13(dfi_wrdata_mask_13);
    dut->dfi_wrdata_mask_14(dfi_wrdata_mask_14);
    dut->dfi_wrdata_mask_15(dfi_wrdata_mask_15);

    dut->dfi_wrdata_en_0(dfi_wrdata_en_0);
    dut->dfi_wrdata_en_1(dfi_wrdata_en_1);
    dut->dfi_wrdata_en_2(dfi_wrdata_en_2);
    dut->dfi_wrdata_en_3(dfi_wrdata_en_3);
    dut->dfi_wrdata_en_4(dfi_wrdata_en_4);
    dut->dfi_wrdata_en_5(dfi_wrdata_en_5);
    dut->dfi_wrdata_en_6(dfi_wrdata_en_6);
    dut->dfi_wrdata_en_7(dfi_wrdata_en_7);
    dut->dfi_wrdata_en_8(dfi_wrdata_en_8);
    dut->dfi_wrdata_en_9(dfi_wrdata_en_9);
    dut->dfi_wrdata_en_10(dfi_wrdata_en_10);
    dut->dfi_wrdata_en_11(dfi_wrdata_en_11);
    dut->dfi_wrdata_en_12(dfi_wrdata_en_12);
    dut->dfi_wrdata_en_13(dfi_wrdata_en_13);
    dut->dfi_wrdata_en_14(dfi_wrdata_en_14);
    dut->dfi_wrdata_en_15(dfi_wrdata_en_15);

    // Connect DFI Read Data Interface
    dut->mc_rdrst_b(mc_rdrst_b);
    dut->mc_rcv_en(mc_rcv_en);
    dut->dfi_rddata_en(dfi_rddata_en);
    dut->dfi_rddata_valid(dfi_rddata_valid);

    dut->dfi_rddata_0(dfi_rddata_0);
    dut->dfi_rddata_1(dfi_rddata_1);
    dut->dfi_rddata_2(dfi_rddata_2);
    dut->dfi_rddata_3(dfi_rddata_3);
    dut->dfi_rddata_4(dfi_rddata_4);
    dut->dfi_rddata_5(dfi_rddata_5);
    dut->dfi_rddata_6(dfi_rddata_6);
    dut->dfi_rddata_7(dfi_rddata_7);
    dut->dfi_rddata_8(dfi_rddata_8);
    dut->dfi_rddata_9(dfi_rddata_9);
    dut->dfi_rddata_10(dfi_rddata_10);
    dut->dfi_rddata_11(dfi_rddata_11);
    dut->dfi_rddata_12(dfi_rddata_12);
    dut->dfi_rddata_13(dfi_rddata_13);
    dut->dfi_rddata_14(dfi_rddata_14);
    dut->dfi_rddata_15(dfi_rddata_15);
}

void openddrDDRTestCases::initialize_signals() {
    // Initialize AXI signals to safe values
    mc0_axi_awvalid.write(false);
    mc0_axi_wvalid.write(false);
    mc0_axi_bready.write(true);
    mc0_axi_arvalid.write(false);
    mc0_axi_rready.write(true);
    
    // Initialize APB signals to safe values
    mc_psel.write(false);
    mc_penable.write(false);
    mc_pwr.write(false);
    mc_paddr.write(0);
    mc_pwdata.write(0);
    
    // Initialize DFI read data signals
    dfi_rddata_valid.write(false);
    mc_rdrst_b.write(true);
    mc_rcv_en.write(false);
    dfi_rddata_en.write(false);
    
    // Initialize all DFI read data to zero
    for (int i = 0; i < 16; i++) {
        switch(i) {
            case 0: dfi_rddata_0.write(0); break;
            case 1: dfi_rddata_1.write(0); break;
            case 2: dfi_rddata_2.write(0); break;
            case 3: dfi_rddata_3.write(0); break;
            case 4: dfi_rddata_4.write(0); break;
            case 5: dfi_rddata_5.write(0); break;
            case 6: dfi_rddata_6.write(0); break;
            case 7: dfi_rddata_7.write(0); break;
            case 8: dfi_rddata_8.write(0); break;
            case 9: dfi_rddata_9.write(0); break;
            case 10: dfi_rddata_10.write(0); break;
            case 11: dfi_rddata_11.write(0); break;
            case 12: dfi_rddata_12.write(0); break;
            case 13: dfi_rddata_13.write(0); break;
            case 14: dfi_rddata_14.write(0); break;
            case 15: dfi_rddata_15.write(0); break;
        }
    }
}

void openddrDDRTestCases::reset_sequence() {
    // Initialize all control signals
    mc_rst_b.write(false);
    porst_b.write(false);
    mc0_aresetn.write(false);
    
    std::cout << "Starting DDR-Specific Test Cases for openddr SystemC Model..." << std::endl;
    
    // Hold reset for several cycles
    wait(100, SC_NS);
    
    // Release resets
    porst_b.write(true);
    wait(50, SC_NS);
    mc_rst_b.write(true);
    mc0_aresetn.write(true);
    
    wait(50, SC_NS);
    std::cout << "@" << sc_time_stamp() << " Reset sequence completed" << std::endl;
}

void openddrDDRTestCases::DDR_test_suite() {
    // Wait for reset completion
    wait(200, SC_NS);
    
    std::cout << "@" << sc_time_stamp() << " Starting DDR-specific test suite..." << std::endl;
    
    // Configure DDR timing and mode registers
    configure_DDR_timing();
    configure_DDR_mode_registers();
    
    // Run DDR-specific test cases
    test_case_1_bl32_burst_operations();
    test_case_2_wck_training_sequence();
    test_case_3_bank_group_interleaving();
    test_case_4_refresh_management_DDR();
    test_case_5_power_management_features();
    
    // Wait for all transactions to complete
    wait(1000, SC_NS);
    
    // Print final results
    print_test_results();
    
    std::cout << "DDR test suite completed!" << std::endl;
}

void openddrDDRTestCases::dfi_read_data_driver() {
    // Enhanced DFI read data driver for DDR with 16-phase data
    while (true) {
        wait(mck.posedge_event());
        
        if (dfi_rddata_en.read()) {
            // Simulate DDR read data return with proper timing
            wait(25, SC_NS);  // tDQSCK + tRPRE timing
            dfi_rddata_valid.write(true);
            
            // Generate test pattern across all 16 phases
            for (int phase = 0; phase < 16; phase++) {
                sc_uint<32> data = 0x12345678 + (phase << 24);
