#define SC_INCLUDE_DYNAMIC_PROCESSES
#include "whitney_systemc_model.h"
#include <systemc.h>

// Simple AXI Master for testing
SC_MODULE(AXIMaster) {
    // Clock and Reset
    sc_in<bool> clk;
    sc_in<bool> rst_n;
    
    // AXI Write Address Channel
    sc_out<sc_uint<12>> axi_awid;
    sc_out<sc_uint<40>> axi_awaddr;
    sc_out<sc_uint<8>> axi_awlen;
    sc_out<sc_uint<3>> axi_awsize;
    sc_out<sc_uint<2>> axi_awburst;
    sc_out<bool> axi_awlock;
    sc_out<sc_uint<4>> axi_awcache;
    sc_out<sc_uint<3>> axi_awprot;
    sc_out<sc_uint<4>> axi_awqos;
    sc_out<bool> axi_awvalid;
    sc_in<bool> axi_awready;

    // AXI Write Data Channel
    sc_out<sc_uint<64>> axi_wdata;
    sc_out<sc_uint<8>> axi_wstrb;
    sc_out<bool> axi_wlast;
    sc_out<bool> axi_wvalid;
    sc_in<bool> axi_wready;

    // AXI Write Response Channel
    sc_in<sc_uint<12>> axi_bid;
    sc_in<sc_uint<2>> axi_bresp;
    sc_in<bool> axi_bvalid;
    sc_out<bool> axi_bready;

    // AXI Read Address Channel
    sc_out<sc_uint<12>> axi_arid;
    sc_out<sc_uint<40>> axi_araddr;
    sc_out<sc_uint<8>> axi_arlen;
    sc_out<sc_uint<3>> axi_arsize;
    sc_out<sc_uint<2>> axi_arburst;
    sc_out<bool> axi_arlock;
    sc_out<sc_uint<4>> axi_arcache;
    sc_out<sc_uint<3>> axi_arprot;
    sc_out<sc_uint<4>> axi_arqos;
    sc_out<bool> axi_arvalid;
    sc_in<bool> axi_arready;

    // AXI Read Data Channel
    sc_in<sc_uint<12>> axi_rid;
    sc_in<sc_uint<64>> axi_rdata;
    sc_in<sc_uint<2>> axi_rresp;
    sc_in<bool> axi_rlast;
    sc_in<bool> axi_rvalid;
    sc_out<bool> axi_rready;

    SC_CTOR(AXIMaster) {
        SC_THREAD(stimulus_process);
        sensitive << clk.pos();
        dont_initialize();
    }

    void stimulus_process();
    void write_transaction(sc_uint<40> addr, sc_uint<64> data, sc_uint<12> id = 0);
    void read_transaction(sc_uint<40> addr, sc_uint<12> id = 0);
};

void AXIMaster::stimulus_process() {
    // Initialize outputs
    axi_awvalid.write(false);
    axi_wvalid.write(false);
    axi_bready.write(true);
    axi_arvalid.write(false);
    axi_rready.write(true);
    
    // Wait for reset deassertion
    while (!rst_n.read()) {
        wait();
    }
    
    // Wait a few cycles
    for (int i = 0; i < 10; i++) {
        wait();
    }
    
    std::cout << "@" << sc_time_stamp() << " Starting AXI transactions..." << std::endl;
    
    // Test sequence: Write then Read
    write_transaction(0x10000000, 0x123456789ABCDEF0ULL, 1);
    wait(10, SC_NS);
    
    write_transaction(0x10000008, 0xFEDCBA9876543210ULL, 2);
    wait(10, SC_NS);
    
    read_transaction(0x10000000, 3);
    wait(10, SC_NS);
    
    read_transaction(0x10000008, 4);
    wait(10, SC_NS);
    
    // Test different banks
    write_transaction(0x11000000, 0xAAAABBBBCCCCDDDDULL, 5);
    wait(10, SC_NS);
    
    read_transaction(0x11000000, 6);
    wait(10, SC_NS);
    
    // Test page hit scenario
    write_transaction(0x10000010, 0x1111222233334444ULL, 7);
    wait(10, SC_NS);
    
    read_transaction(0x10000010, 8);
    wait(10, SC_NS);
    
    std::cout << "@" << sc_time_stamp() << " AXI transactions completed." << std::endl;
    
    // Wait for all transactions to complete
    wait(100, SC_NS);
    
    sc_stop();
}

void AXIMaster::write_transaction(sc_uint<40> addr, sc_uint<64> data, sc_uint<12> id) {
    // Write Address Phase
    axi_awid.write(id);
    axi_awaddr.write(addr);
    axi_awlen.write(0); // Single beat
    axi_awsize.write(3); // 8 bytes
    axi_awburst.write(1); // INCR
    axi_awlock.write(false);
    axi_awcache.write(0);
    axi_awprot.write(0);
    axi_awqos.write(0);
    axi_awvalid.write(true);
    
    // Wait for address ready
    do {
        wait();
    } while (!axi_awready.read());
    
    axi_awvalid.write(false);
    
    // Write Data Phase
    axi_wdata.write(data);
    axi_wstrb.write(0xFF); // All bytes valid
    axi_wlast.write(true);
    axi_wvalid.write(true);
    
    // Wait for data ready
    do {
        wait();
    } while (!axi_wready.read());
    
    axi_wvalid.write(false);
    
    std::cout << "@" << sc_time_stamp() << " Write Transaction: Addr=0x" 
              << std::hex << addr << " Data=0x" << data << " ID=" << id << std::endl;
}

void AXIMaster::read_transaction(sc_uint<40> addr, sc_uint<12> id) {
    // Read Address Phase
    axi_arid.write(id);
    axi_araddr.write(addr);
    axi_arlen.write(0); // Single beat
    axi_arsize.write(3); // 8 bytes
    axi_arburst.write(1); // INCR
    axi_arlock.write(false);
    axi_arcache.write(0);
    axi_arprot.write(0);
    axi_arqos.write(0);
    axi_arvalid.write(true);
    
    // Wait for address ready
    do {
        wait();
    } while (!axi_arready.read());
    
    axi_arvalid.write(false);
    
    std::cout << "@" << sc_time_stamp() << " Read Transaction: Addr=0x" 
              << std::hex << addr << " ID=" << id << std::endl;
}

// Simple LPDDR5 PHY Model for DFI interface
SC_MODULE(LPDDR5PHY) {
    // Clock and Reset
    sc_in<bool> clk;
    sc_in<bool> rst_n;
    
    // DFI Command Interface
    sc_in<sc_uint<2>> dfi_dram_clk_disable_0;
    sc_in<sc_uint<2>> dfi_dram_clk_disable_1;
    sc_in<bool> dfi_dram_ca_disable;
    sc_in<sc_uint<2>> dfi_cs_0_p0;
    sc_in<sc_uint<2>> dfi_cs_0_p1;
    sc_in<sc_uint<2>> dfi_cs_1_p2;
    sc_in<sc_uint<2>> dfi_cs_1_p3;
    sc_in<sc_uint<7>> dfi_address_0_p0;
    sc_in<sc_uint<7>> dfi_address_0_p1;
    sc_in<sc_uint<7>> dfi_address_1_p2;
    sc_in<sc_uint<7>> dfi_address_1_p3;
    sc_in<bool> dfi_reset_n;

    // DFI WCK Control
    sc_in<sc_uint<4>> dfi_wck_cs;
    sc_in<sc_uint<4>> dfi_wck_en;
    sc_in<sc_uint<2>> dfi_wck_toggle;

    // DFI Write Data Interface
    sc_in<sc_uint<32>> dfi_wrdata_0;
    sc_in<sc_uint<32>> dfi_wrdata_1;
    sc_in<sc_uint<32>> dfi_wrdata_2;
    sc_in<sc_uint<32>> dfi_wrdata_3;
    sc_in<sc_uint<4>> dfi_wrdata_mask_0;
    sc_in<sc_uint<4>> dfi_wrdata_mask_1;
    sc_in<sc_uint<4>> dfi_wrdata_mask_2;
    sc_in<sc_uint<4>> dfi_wrdata_mask_3;
    sc_in<sc_uint<4>> dfi_wrdata_en_0;
    sc_in<sc_uint<4>> dfi_wrdata_en_1;
    sc_in<sc_uint<4>> dfi_wrdata_en_2;
    sc_in<sc_uint<4>> dfi_wrdata_en_3;

    // DFI Read Data Interface
    sc_in<bool> mc_rdrst_b;
    sc_in<bool> mc_rcv_en;
    sc_in<bool> dfi_rddata_en;
    sc_out<bool> dfi_rddata_valid;
    sc_out<sc_uint<32>> dfi_rddata_0;
    sc_out<sc_uint<32>> dfi_rddata_1;
    sc_out<sc_uint<32>> dfi_rddata_2;
    sc_out<sc_uint<32>> dfi_rddata_3;

    // Memory array (simplified)
    std::map<sc_uint<40>, sc_uint<64>> memory;

    SC_CTOR(LPDDR5PHY) {
        SC_METHOD(dfi_monitor_process);
        sensitive << clk.pos();
        dont_initialize();
        
        SC_METHOD(read_data_process);
        sensitive << clk.pos();
        dont_initialize();
    }

    void dfi_monitor_process();
    void read_data_process();
};

void LPDDR5PHY::dfi_monitor_process() {
    if (!rst_n.read()) {
        return;
    }

    // Monitor DFI command interface
    if (dfi_cs_0_p0.read() != 0 || dfi_cs_0_p1.read() != 0 ||
        dfi_cs_1_p2.read() != 0 || dfi_cs_1_p3.read() != 0) {
        
        std::cout << "@" << sc_time_stamp() << " PHY: DFI Command - CS0_P0=0x" 
                  << std::hex << dfi_cs_0_p0.read() << " CS0_P1=0x" << dfi_cs_0_p1.read()
                  << " Addr0_P0=0x" << dfi_address_0_p0.read() 
                  << " Addr0_P1=0x" << dfi_address_0_p1.read() << std::endl;
    }
    
    // Monitor write data
    if (dfi_wrdata_en_0.read() != 0 || dfi_wrdata_en_1.read() != 0 ||
        dfi_wrdata_en_2.read() != 0 || dfi_wrdata_en_3.read() != 0) {
        
        std::cout << "@" << sc_time_stamp() << " PHY: Write Data - P0=0x" 
                  << std::hex << dfi_wrdata_0.read() << " P1=0x" << dfi_wrdata_1.read()
                  << " P2=0x" << dfi_wrdata_2.read() << " P3=0x" << dfi_wrdata_3.read() << std::endl;
    }
}

void LPDDR5PHY::read_data_process() {
    if (!rst_n.read()) {
        dfi_rddata_valid.write(false);
        dfi_rddata_0.write(0);
        dfi_rddata_1.write(0);
        dfi_rddata_2.write(0);
        dfi_rddata_3.write(0);
        return;
    }

    // Simple read data generation
    if (dfi_rddata_en.read()) {
        // Generate some test data
        dfi_rddata_0.write(0x12345678);
        dfi_rddata_1.write(0x9ABCDEF0);
        dfi_rddata_2.write(0x11223344);
        dfi_rddata_3.write(0x55667788);
        dfi_rddata_valid.write(true);
        
        std::cout << "@" << sc_time_stamp() << " PHY: Read Data Generated" << std::endl;
    } else {
        dfi_rddata_valid.write(false);
    }
}

// APB Master for register access
SC_MODULE(APBMaster) {
    sc_in<bool> clk;
    sc_in<bool> rst_n;
    
    sc_out<bool> psel;
    sc_out<bool> penable;
    sc_out<bool> pwrite;
    sc_out<sc_uint<10>> paddr;
    sc_out<sc_uint<32>> pwdata;
    sc_in<sc_uint<32>> prdata;
    sc_in<bool> pready;
    sc_in<bool> pslverr;

    SC_CTOR(APBMaster) {
        SC_THREAD(apb_stimulus_process);
        sensitive << clk.pos();
        dont_initialize();
    }

    void apb_stimulus_process();
    void apb_write(sc_uint<10> addr, sc_uint<32> data);
    sc_uint<32> apb_read(sc_uint<10> addr);
};

void APBMaster::apb_stimulus_process() {
    // Initialize
    psel.write(false);
    penable.write(false);
    pwrite.write(false);
    paddr.write(0);
    pwdata.write(0);
    
    // Wait for reset
    while (!rst_n.read()) {
        wait();
    }
    
    wait(5, SC_NS);
    
    std::cout << "@" << sc_time_stamp() << " Starting APB register access..." << std::endl;
    
    // Configure the memory controller
    apb_write(0x000, 0x00000001); // seq_control_reg - DDR init done
    apb_write(0x008, 0x00030520); // ddr_config_reg - LPDDR5, BL32
    apb_write(0x048, 0x00001F41); // refresh_cntrl_reg - Enable refresh
    
    // Read back some registers
    sc_uint<32> data = apb_read(0x01C); // pmu_status_reg
    std::cout << "@" << sc_time_stamp() << " PMU Status: 0x" << std::hex << data << std::endl;
    
    data = apb_read(0x008); // ddr_config_reg
    std::cout << "@" << sc_time_stamp() << " DDR Config: 0x" << std::hex << data << std::endl;
}

void APBMaster::apb_write(sc_uint<10> addr, sc_uint<32> data) {
    paddr.write(addr);
    pwdata.write(data);
    pwrite.write(true);
    psel.write(true);
    wait();
    
    penable.write(true);
    do {
        wait();
    } while (!pready.read());
    
    psel.write(false);
    penable.write(false);
    
    std::cout << "@" << sc_time_stamp() << " APB Write: Addr=0x" 
              << std::hex << addr << " Data=0x" << data << std::endl;
}

sc_uint<32> APBMaster::apb_read(sc_uint<10> addr) {
    paddr.write(addr);
    pwrite.write(false);
    psel.write(true);
    wait();
    
    penable.write(true);
    do {
        wait();
    } while (!pready.read());
    
    sc_uint<32> data = prdata.read();
    psel.write(false);
    penable.write(false);
    
    std::cout << "@" << sc_time_stamp() << " APB Read: Addr=0x" 
              << std::hex << addr << " Data=0x" << data << std::endl;
    
    return data;
}

// Reset Generator Module
SC_MODULE(ResetGenerator) {
    sc_in<bool> clk;
    sc_out<bool> mc_rst_b;
    sc_out<bool> porst_b;
    sc_out<bool> axi_rst_n;

    SC_CTOR(ResetGenerator) {
        SC_THREAD(reset_sequence);
        sensitive << clk.pos();
        dont_initialize();
    }

    void reset_sequence();
};

void ResetGenerator::reset_sequence() {
    // Initial reset state
    mc_rst_b.write(false);
    porst_b.write(false);
    axi_rst_n.write(false);
    
    wait(20, SC_NS);
    
    // Release power-on reset
    porst_b.write(true);
    wait(10, SC_NS);
    
    // Release main reset
    mc_rst_b.write(true);
    axi_rst_n.write(true);
    
    std::cout << "@" << sc_time_stamp() << " Reset sequence completed" << std::endl;
}

// Top-level testbench
int sc_main(int argc, char* argv[]) {
    // Clock and reset signals
    sc_clock mck("mck", 5, SC_NS); // 200MHz
    sc_clock axi_clk("axi_clk", 10, SC_NS); // 100MHz
    sc_clock slow_clk("slow_clk", 40, SC_NS); // 25MHz
    
    sc_signal<bool> mc_rst_b;
    sc_signal<bool> porst_b;
    sc_signal<bool> axi_rst_n;

    // AXI signals
    sc_signal<sc_uint<12>> axi_awid, axi_bid, axi_arid, axi_rid;
    sc_signal<sc_uint<40>> axi_awaddr, axi_araddr;
    sc_signal<sc_uint<8>> axi_awlen, axi_arlen;
    sc_signal<sc_uint<3>> axi_awsize, axi_arsize;
    sc_signal<sc_uint<2>> axi_awburst, axi_arburst, axi_bresp, axi_rresp;
    sc_signal<bool> axi_awlock, axi_arlock;
    sc_signal<sc_uint<4>> axi_awcache, axi_arcache;
    sc_signal<sc_uint<3>> axi_awprot, axi_arprot;
    sc_signal<sc_uint<4>> axi_awqos, axi_arqos;
    sc_signal<bool> axi_awvalid, axi_awready, axi_wvalid, axi_wready;
    sc_signal<bool> axi_bvalid, axi_bready, axi_arvalid, axi_arready;
    sc_signal<bool> axi_rvalid, axi_rready, axi_rlast, axi_wlast;
    sc_signal<sc_uint<64>> axi_wdata, axi_rdata;
    sc_signal<sc_uint<8>> axi_wstrb;

    // APB signals
    sc_signal<bool> apb_psel, apb_penable, apb_pwrite, apb_pready, apb_pslverr;
    sc_signal<sc_uint<10>> apb_paddr;
    sc_signal<sc_uint<32>> apb_pwdata, apb_prdata;

    // DFI signals
    sc_signal<sc_uint<2>> dfi_dram_clk_disable_0, dfi_dram_clk_disable_1;
    sc_signal<bool> dfi_dram_ca_disable, dfi_reset_n;
    sc_signal<sc_uint<2>> dfi_cs_0_p0, dfi_cs_0_p1, dfi_cs_1_p2, dfi_cs_1_p3;
    sc_signal<sc_uint<7>> dfi_address_0_p0, dfi_address_0_p1, dfi_address_1_p2, dfi_address_1_p3;
    sc_signal<sc_uint<4>> dfi_wck_cs, dfi_wck_en;
    sc_signal<sc_uint<2>> dfi_wck_toggle;
    
    // DFI Write Data (all 16 phases)
    sc_signal<sc_uint<32>> dfi_wrdata_0, dfi_wrdata_1, dfi_wrdata_2, dfi_wrdata_3;
    sc_signal<sc_uint<32>> dfi_wrdata_4, dfi_wrdata_5, dfi_wrdata_6, dfi_wrdata_7;
    sc_signal<sc_uint<32>> dfi_wrdata_8, dfi_wrdata_9, dfi_wrdata_10, dfi_wrdata_11;
    sc_signal<sc_uint<32>> dfi_wrdata_12, dfi_wrdata_13, dfi_wrdata_14, dfi_wrdata_15;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_0, dfi_wrdata_mask_1, dfi_wrdata_mask_2, dfi_wrdata_mask_3;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_4, dfi_wrdata_mask_5, dfi_wrdata_mask_6, dfi_wrdata_mask_7;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_8, dfi_wrdata_mask_9, dfi_wrdata_mask_10, dfi_wrdata_mask_11;
    sc_signal<sc_uint<4>> dfi_wrdata_mask_12, dfi_wrdata_mask_13, dfi_wrdata_mask_14, dfi_wrdata_mask_15;
    sc_signal<sc_uint<4>> dfi_wrdata_en_0, dfi_wrdata_en_1, dfi_wrdata_en_2, dfi_wrdata_en_3;
    sc_signal<sc_uint<4>> dfi_wrdata_en_4, dfi_wrdata_en_5, dfi_wrdata_en_6, dfi_wrdata_en_7;
    sc_signal<sc_uint<4>> dfi_wrdata_en_8, dfi_wrdata_en_9, dfi_wrdata_en_10, dfi_wrdata_en_11;
    sc_signal<sc_uint<4>> dfi_wrdata_en_12, dfi_wrdata_en_13, dfi_wrdata_en_14, dfi_wrdata_en_15;
    
    // DFI Read Data
    sc_signal<bool> mc_rdrst_b, mc_rcv_en, dfi_rddata_en, dfi_rddata_valid;
    sc_signal<sc_uint<32>> dfi_rddata_0, dfi_rddata_1, dfi_rddata_2, dfi_rddata_3;
    sc_signal<sc_uint<32>> dfi_rddata_4, dfi_rddata_5, dfi_rddata_6, dfi_rddata_7;
    sc_signal<sc_uint<32>> dfi_rddata_8, dfi_rddata_9, dfi_rddata_10, dfi_rddata_11;
    sc_signal<sc_uint<32>> dfi_rddata_12, dfi_rddata_13, dfi_rddata_14, dfi_rddata_15;

    // Instantiate modules
    WhitneySystemCModel whitney("whitney");
    AXIMaster axi_master("axi_master");
    APBMaster apb_master("apb_master");
    LPDDR5PHY phy("phy");
    ResetGenerator reset_gen("reset_gen");

    // Connect Whitney SystemC Model
    whitney.mck(mck);
    whitney.mc_rst_b(mc_rst_b);
    whitney.porst_b(porst_b);
    whitney.slow_clk(slow_clk);
    whitney.mc0_aclk(axi_clk);
    whitney.mc0_aresetn(axi_rst_n);
    
    // AXI connections
    whitney.mc0_axi_awid(axi_awid);
    whitney.mc0_axi_awaddr(axi_awaddr);
    whitney.mc0_axi_awlen(axi_awlen);
    whitney.mc0_axi_awsize(axi_awsize);
    whitney.mc0_axi_awburst(axi_awburst);
    whitney.mc0_axi_awlock(axi_awlock);
    whitney.mc0_axi_awcache(axi_awcache);
    whitney.mc0_axi_awprot(axi_awprot);
    whitney.mc0_axi_awqos(axi_awqos);
    whitney.mc0_axi_awvalid(axi_awvalid);
    whitney.mc0_axi_awready(axi_awready);
    
    whitney.mc0_axi_wdata(axi_wdata);
    whitney.mc0_axi_wstrb(axi_wstrb);
    whitney.mc0_axi_wlast(axi_wlast);
    whitney.mc0_axi_wvalid(axi_wvalid);
    whitney.mc0_axi_wready(axi_wready);
    
    whitney.mc0_axi_bid(axi_bid);
    whitney.mc0_axi_bresp(axi_bresp);
    whitney.mc0_axi_bvalid(axi_bvalid);
    whitney.mc0_axi_bready(axi_bready);
    
    whitney.mc0_axi_arid(axi_arid);
    whitney.mc0_axi_araddr(axi_araddr);
    whitney.mc0_axi_arlen(axi_arlen);
    whitney.mc0_axi_arsize(axi_arsize);
    whitney.mc0_axi_arburst(axi_arburst);
    whitney.mc0_axi_arlock(axi_arlock);
    whitney.mc0_axi_arcache(axi_arcache);
    whitney.mc0_axi_arprot(axi_arprot);
    whitney.mc0_axi_arqos(axi_arqos);
    whitney.mc0_axi_arvalid(axi_arvalid);
    whitney.mc0_axi_arready(axi_arready);
    
    whitney.mc0_axi_rid(axi_rid);
    whitney.mc0_axi_rdata(axi_rdata);
    whitney.mc0_axi_rresp(axi_rresp);
    whitney.mc0_axi_rlast(axi_rlast);
    whitney.mc0_axi_rvalid(axi_rvalid);
    whitney.mc0_axi_rready(axi_rready);
    
    // APB connections
    whitney.mc_psel(apb_psel);
    whitney.mc_penable(apb_penable);
    whitney.mc_pwr(apb_pwrite);
    whitney.mc_paddr(apb_paddr);
    whitney.mc_pwdata(apb_pwdata);
    whitney.mc_prdata(apb_prdata);
    whitney.mc_pready(apb_pready);
    whitney.mc_pslverr(apb_pslverr);
    
    // DFI connections (simplified)
    whitney.dfi_dram_clk_disable_0(dfi_dram_clk_disable_0);
    whitney.dfi_dram_clk_disable_1(dfi_dram_clk_disable_1);
    whitney.dfi_dram_ca_disable(dfi_dram_ca_disable);
    whitney.dfi_cs_0_p0(dfi_cs_0_p0);
    whitney.dfi_cs_0_p1(dfi_cs_0_p1);
    whitney.dfi_cs_1_p2(dfi_cs_1_p2);
    whitney.dfi_cs_1_p3(dfi_cs_1_p3);
    whitney.dfi_address_0_p0(dfi_address_0_p0);
    whitney.dfi_address_0_p1(dfi_address_0_p1);
    whitney.dfi_address_1_p2(dfi_address_1_p2);
    whitney.dfi_address_1_p3(dfi_address_1_p3);
    whitney.dfi_reset_n(dfi_reset_n);
    
    whitney.dfi_wck_cs(dfi_wck_cs);
    whitney.dfi_wck_en(dfi_wck_en);
    whitney.dfi_wck_toggle(dfi_wck_toggle);
    
    whitney.dfi_wrdata_0(dfi_wrdata_0);
    whitney.dfi_wrdata_1(dfi_wrdata_1);
    whitney.dfi_wrdata_2(dfi_wrdata_2);
    whitney.dfi_wrdata_3(dfi_wrdata_3);
    whitney.dfi_wrdata_4(dfi_wrdata_4);
    whitney.dfi_wrdata_5(dfi_wrdata_5);
    whitney.dfi_wrdata_6(dfi_wrdata_6);
    whitney.dfi_wrdata_7(dfi_wrdata_7);
    whitney.dfi_wrdata_8(dfi_wrdata_8);
    whitney.dfi_wrdata_9(dfi_wrdata_9);
    whitney.dfi_wrdata_10(dfi_wrdata_10);
    whitney.dfi_wrdata_11(dfi_wrdata_11);
    whitney.dfi_wrdata_12(dfi_wrdata_12);
    whitney.dfi_wrdata_13(dfi_wrdata_13);
    whitney.dfi_wrdata_14(dfi_wrdata_14);
    whitney.dfi_wrdata_15(dfi_wrdata_15);
    whitney.dfi_wrdata_mask_0(dfi_wrdata_mask_0);
    whitney.dfi_wrdata_mask_1(dfi_wrdata_mask_1);
    whitney.dfi_wrdata_mask_2(dfi_wrdata_mask_2);
    whitney.dfi_wrdata_mask_3(dfi_wrdata_mask_3);
    whitney.dfi_wrdata_mask_4(dfi_wrdata_mask_4);
    whitney.dfi_wrdata_mask_5(dfi_wrdata_mask_5);
    whitney.dfi_wrdata_mask_6(dfi_wrdata_mask_6);
    whitney.dfi_wrdata_mask_7(dfi_wrdata_mask_7);
    whitney.dfi_wrdata_mask_8(dfi_wrdata_mask_8);
    whitney.dfi_wrdata_mask_9(dfi_wrdata_mask_9);
    whitney.dfi_wrdata_mask_10(dfi_wrdata_mask_10);
    whitney.dfi_wrdata_mask_11(dfi_wrdata_mask_11);
    whitney.dfi_wrdata_mask_12(dfi_wrdata_mask_12);
    whitney.dfi_wrdata_mask_13(dfi_wrdata_mask_13);
    whitney.dfi_wrdata_mask_14(dfi_wrdata_mask_14);
    whitney.dfi_wrdata_mask_15(dfi_wrdata_mask_15);
    whitney.dfi_wrdata_en_0(dfi_wrdata_en_0);
    whitney.dfi_wrdata_en_1(dfi_wrdata_en_1);
    whitney.dfi_wrdata_en_2(dfi_wrdata_en_2);
    whitney.dfi_wrdata_en_3(dfi_wrdata_en_3);
    whitney.dfi_wrdata_en_4(dfi_wrdata_en_4);
    whitney.dfi_wrdata_en_5(dfi_wrdata_en_5);
    whitney.dfi_wrdata_en_6(dfi_wrdata_en_6);
    whitney.dfi_wrdata_en_7(dfi_wrdata_en_7);
    whitney.dfi_wrdata_en_8(dfi_wrdata_en_8);
    whitney.dfi_wrdata_en_9(dfi_wrdata_en_9);
    whitney.dfi_wrdata_en_10(dfi_wrdata_en_10);
    whitney.dfi_wrdata_en_11(dfi_wrdata_en_11);
    whitney.dfi_wrdata_en_12(dfi_wrdata_en_12);
    whitney.dfi_wrdata_en_13(dfi_wrdata_en_13);
    whitney.dfi_wrdata_en_14(dfi_wrdata_en_14);
    whitney.dfi_wrdata_en_15(dfi_wrdata_en_15);
    
    whitney.mc_rdrst_b(mc_rdrst_b);
    whitney.mc_rcv_en(mc_rcv_en);
    whitney.dfi_rddata_en(dfi_rddata_en);
    whitney.dfi_rddata_valid(dfi_rddata_valid);
    whitney.dfi_rddata_0(dfi_rddata_0);
    whitney.dfi_rddata_1(dfi_rddata_1);
    whitney.dfi_rddata_2(dfi_rddata_2);
    whitney.dfi_rddata_3(dfi_rddata_3);
    whitney.dfi_rddata_4(dfi_rddata_4);
    whitney.dfi_rddata_5(dfi_rddata_5);
    whitney.dfi_rddata_6(dfi_rddata_6);
    whitney.dfi_rddata_7(dfi_rddata_7);
    whitney.dfi_rddata_8(dfi_rddata_8);
    whitney.dfi_rddata_9(dfi_rddata_9);
    whitney.dfi_rddata_10(dfi_rddata_10);
    whitney.dfi_rddata_11(dfi_rddata_11);
    whitney.dfi_rddata_12(dfi_rddata_12);
    whitney.dfi_rddata_13(dfi_rddata_13);
    whitney.dfi_rddata_14(dfi_rddata_14);
    whitney.dfi_rddata_15(dfi_rddata_15);

    // Connect AXI Master
    axi_master.clk(axi_clk);
    axi_master.rst_n(axi_rst_n);
    axi_master.axi_awid(axi_awid);
    axi_master.axi_awaddr(axi_awaddr);
    axi_master.axi_awlen(axi_awlen);
    axi_master.axi_awsize(axi_awsize);
    axi_master.axi_awburst(axi_awburst);
    axi_master.axi_awlock(axi_awlock);
    axi_master.axi_awcache(axi_awcache);
    axi_master.axi_awprot(axi_awprot);
    axi_master.axi_awqos(axi_awqos);
    axi_master.axi_awvalid(axi_awvalid);
    axi_master.axi_awready(axi_awready);
    
    axi_master.axi_wdata(axi_wdata);
    axi_master.axi_wstrb(axi_wstrb);
    axi_master.axi_wlast(axi_wlast);
    axi_master.axi_wvalid(axi_wvalid);
    axi_master.axi_wready(axi_wready);
    
    axi_master.axi_bid(axi_bid);
    axi_master.axi_bresp(axi_bresp);
    axi_master.axi_bvalid(axi_bvalid);
    axi_master.axi_bready(axi_bready);
    
    axi_master.axi_arid(axi_arid);
    axi_master.axi_araddr(axi_araddr);
    axi_master.axi_arlen(axi_arlen);
    axi_master.axi_arsize(axi_arsize);
    axi_master.axi_arburst(axi_arburst);
    axi_master.axi_arlock(axi_arlock);
    axi_master.axi_arcache(axi_arcache);
    axi_master.axi_arprot(axi_arprot);
    axi_master.axi_arqos(axi_arqos);
    axi_master.axi_arvalid(axi_arvalid);
    axi_master.axi_arready(axi_arready);
    
    axi_master.axi_rid(axi_rid);
    axi_master.axi_rdata(axi_rdata);
    axi_master.axi_rresp(axi_rresp);
    axi_master.axi_rlast(axi_rlast);
    axi_master.axi_rvalid(axi_rvalid);
    axi_master.axi_rready(axi_rready);

    // Connect APB Master
    apb_master.clk(mck);
    apb_master.rst_n(mc_rst_b);
    apb_master.psel(apb_psel);
    apb_master.penable(apb_penable);
    apb_master.pwrite(apb_pwrite);
    apb_master.paddr(apb_paddr);
    apb_master.pwdata(apb_pwdata);
    apb_master.prdata(apb_prdata);
    apb_master.pready(apb_pready);
    apb_master.pslverr(apb_pslverr);

    // Connect PHY
    phy.clk(mck);
    phy.rst_n(mc_rst_b);
    phy.dfi_dram_clk_disable_0(dfi_dram_clk_disable_0);
    phy.dfi_dram_clk_disable_1(dfi_dram_clk_disable_1);
    phy.dfi_dram_ca_disable(dfi_dram_ca_disable);
    phy.dfi_cs_0_p0(dfi_cs_0_p0);
    phy.dfi_cs_0_p1(dfi_cs_0_p1);
    phy.dfi_cs_1_p2(dfi_cs_1_p2);
    phy.dfi_cs_1_p3(dfi_cs_1_p3);
    phy.dfi_address_0_p0(dfi_address_0_p0);
    phy.dfi_address_0_p1(dfi_address_0_p1);
    phy.dfi_address_1_p2(dfi_address_1_p2);
    phy.dfi_address_1_p3(dfi_address_1_p3);
    phy.dfi_reset_n(dfi_reset_n);
    
    phy.dfi_wck_cs(dfi_wck_cs);
    phy.dfi_wck_en(dfi_wck_en);
    phy.dfi_wck_toggle(dfi_wck_toggle);
    
    phy.dfi_wrdata_0(dfi_wrdata_0);
    phy.dfi_wrdata_1(dfi_wrdata_1);
    phy.dfi_wrdata_2(dfi_wrdata_2);
    phy.dfi_wrdata_3(dfi_wrdata_3);
    phy.dfi_wrdata_mask_0(dfi_wrdata_mask_0);
    phy.dfi_wrdata_mask_1(dfi_wrdata_mask_1);
    phy.dfi_wrdata_mask_2(dfi_wrdata_mask_2);
    phy.dfi_wrdata_mask_3(dfi_wrdata_mask_3);
    phy.dfi_wrdata_en_0(dfi_wrdata_en_0);
    phy.dfi_wrdata_en_1(dfi_wrdata_en_1);
    phy.dfi_wrdata_en_2(dfi_wrdata_en_2);
    phy.dfi_wrdata_en_3(dfi_wrdata_en_3);
    
    phy.mc_rdrst_b(mc_rdrst_b);
    phy.mc_rcv_en(mc_rcv_en);
    phy.dfi_rddata_en(dfi_rddata_en);
    phy.dfi_rddata_valid(dfi_rddata_valid);
    phy.dfi_rddata_0(dfi_rddata_0);
    phy.dfi_rddata_1(dfi_rddata_1);
    phy.dfi_rddata_2(dfi_rddata_2);
    phy.dfi_rddata_3(dfi_rddata_3);

    // Connect Reset Generator
    reset_gen.clk(mck);
    reset_gen.mc_rst_b(mc_rst_b);
    reset_gen.porst_b(porst_b);
    reset_gen.axi_rst_n(axi_rst_n);

    // Enable VCD tracing
    sc_trace_file* tf = sc_create_vcd_trace_file("whitney_trace");
    sc_trace(tf, mck, "mck");
    sc_trace(tf, mc_rst_b, "mc_rst_b");
    sc_trace(tf, axi_awvalid, "axi_awvalid");
    sc_trace(tf, axi_awready, "axi_awready");
    sc_trace(tf, axi_awaddr, "axi_awaddr");
    sc_trace(tf, axi_wvalid, "axi_wvalid");
    sc_trace(tf, axi_wready, "axi_wready");
    sc_trace(tf, axi_wdata, "axi_wdata");
    sc_trace(tf, axi_bvalid, "axi_bvalid");
    sc_trace(tf, axi_bready, "axi_bready");
    sc_trace(tf, axi_arvalid, "axi_arvalid");
    sc_trace(tf, axi_arready, "axi_arready");
    sc_trace(tf, axi_araddr, "axi_araddr");
    sc_trace(tf, axi_rvalid, "axi_rvalid");
    sc_trace(tf, axi_rready, "axi_rready");
    sc_trace(tf, axi_rdata, "axi_rdata");
    
    // DFI traces
    sc_trace(tf, dfi_cs_0_p0, "dfi_cs_0_p0");
    sc_trace(tf, dfi_address_0_p0, "dfi_address_0_p0");
    sc_trace(tf, dfi_wrdata_0, "dfi_wrdata_0");
    sc_trace(tf, dfi_rddata_0, "dfi_rddata_0");

    std::cout << "Starting Whitney LPDDR5 SystemC Model Simulation..." << std::endl;
    
    // Run simulation
    sc_start(1000, SC_NS);
    
    // Print final statistics
    whitney.print_statistics();
    
    sc_close_vcd_trace_file(tf);
    
    std::cout << "Simulation completed successfully!" << std::endl;
    return 0;
}
