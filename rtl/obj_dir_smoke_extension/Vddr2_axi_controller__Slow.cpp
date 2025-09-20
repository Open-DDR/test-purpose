// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vddr2_axi_controller.h for the primary calling header

#include "Vddr2_axi_controller.h"
#include "Vddr2_axi_controller__Syms.h"

//==========

VL_CTOR_IMP(Vddr2_axi_controller) {
    Vddr2_axi_controller__Syms* __restrict vlSymsp = __VlSymsp = new Vddr2_axi_controller__Syms(this, name());
    Vddr2_axi_controller* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Reset internal values
    
    // Reset structure values
    _ctor_var_reset();
}

void Vddr2_axi_controller::__Vconfigure(Vddr2_axi_controller__Syms* vlSymsp, bool first) {
    if (false && first) {}  // Prevent unused
    this->__VlSymsp = vlSymsp;
    if (false && this->__VlSymsp) {}  // Prevent unused
    Verilated::timeunit(-9);
    Verilated::timeprecision(-12);
}

Vddr2_axi_controller::~Vddr2_axi_controller() {
    VL_DO_CLEAR(delete __VlSymsp, __VlSymsp = NULL);
}

void Vddr2_axi_controller::_initial__TOP__1(Vddr2_axi_controller__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vddr2_axi_controller::_initial__TOP__1\n"); );
    Vddr2_axi_controller* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Variables
    WData/*255:0*/ __Vtemp1[8];
    // Body
    if ((0U != VL_TESTPLUSARGS_I("dump"))) {
        __Vtemp1[0U] = 0x2e766364U;
        __Vtemp1[1U] = 0x74696f6eU;
        __Vtemp1[2U] = 0x696f6c61U;
        __Vtemp1[3U] = 0x65725f76U;
        __Vtemp1[4U] = 0x726f6c6cU;
        __Vtemp1[5U] = 0x636f6e74U;
        __Vtemp1[6U] = 0x6472325fU;
        __Vtemp1[7U] = 0x64U;
        vl_dumpctl_filenamep(true, VL_CVT_PACK_STR_NW(8, __Vtemp1));
        VL_PRINTF_MT("-Info: /aws/home/jayb/proj/open-ddr/test-purpose/rtl/ddr2_axi_controller_verilator_clean.sv:322: $dumpvar ignored, as Verilated without --trace\n");
    }
    vlTOPp->s_axi_bresp = 0U;
    vlTOPp->s_axi_rdata = 0ULL;
    vlTOPp->s_axi_rresp = 0U;
    vlTOPp->s_axi_rlast = 1U;
    vlTOPp->ddr2_dq = 0ULL;
    vlTOPp->ddr2_dqs = 0U;
    vlTOPp->ddr2_dqs_n = 0U;
}

void Vddr2_axi_controller::_settle__TOP__3(Vddr2_axi_controller__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vddr2_axi_controller::_settle__TOP__3\n"); );
    Vddr2_axi_controller* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->ddr2_clk = vlTOPp->ddr_clk;
    vlTOPp->ddr2_clk_n = (1U & (~ (IData)(vlTOPp->ddr_clk)));
    vlTOPp->ddr2_cke = vlTOPp->ddr_rst_n;
    vlTOPp->s_axi_bid = vlTOPp->s_axi_awid;
    vlTOPp->s_axi_rid = vlTOPp->s_axi_arid;
    vlTOPp->ddr2_cs_n = vlTOPp->ddr2_axi_controller__DOT__ddr2_cs_n_reg;
    vlTOPp->ddr2_ras_n = vlTOPp->ddr2_axi_controller__DOT__ddr2_ras_n_reg;
    vlTOPp->ddr2_cas_n = vlTOPp->ddr2_axi_controller__DOT__ddr2_cas_n_reg;
    vlTOPp->ddr2_we_n = vlTOPp->ddr2_axi_controller__DOT__ddr2_we_n_reg;
    vlTOPp->ddr2_ba = vlTOPp->ddr2_axi_controller__DOT__ddr2_ba_reg;
    vlTOPp->ddr2_a = vlTOPp->ddr2_axi_controller__DOT__ddr2_a_reg;
    vlTOPp->s_axi_wready = (3U == (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state));
    vlTOPp->s_axi_bvalid = (4U == (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state));
    vlTOPp->s_axi_rvalid = (2U == (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state));
    vlTOPp->s_axi_awready = ((0U == (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state)) 
                             & (~ (IData)(vlTOPp->s_axi_arvalid)));
    vlTOPp->s_axi_arready = ((0U == (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state)) 
                             & (~ (IData)(vlTOPp->s_axi_awvalid)));
}

void Vddr2_axi_controller::_eval_initial(Vddr2_axi_controller__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vddr2_axi_controller::_eval_initial\n"); );
    Vddr2_axi_controller* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->_initial__TOP__1(vlSymsp);
    vlTOPp->__Vclklast__TOP__ddr_clk = vlTOPp->ddr_clk;
    vlTOPp->__Vclklast__TOP__ddr_rst_n = vlTOPp->ddr_rst_n;
}

void Vddr2_axi_controller::final() {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vddr2_axi_controller::final\n"); );
    // Variables
    Vddr2_axi_controller__Syms* __restrict vlSymsp = this->__VlSymsp;
    Vddr2_axi_controller* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
}

void Vddr2_axi_controller::_eval_settle(Vddr2_axi_controller__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vddr2_axi_controller::_eval_settle\n"); );
    Vddr2_axi_controller* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->_settle__TOP__3(vlSymsp);
}

void Vddr2_axi_controller::_ctor_var_reset() {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vddr2_axi_controller::_ctor_var_reset\n"); );
    // Body
    axi_aclk = VL_RAND_RESET_I(1);
    axi_aresetn = VL_RAND_RESET_I(1);
    ddr_clk = VL_RAND_RESET_I(1);
    ddr_rst_n = VL_RAND_RESET_I(1);
    s_axi_awid = VL_RAND_RESET_I(4);
    s_axi_awaddr = VL_RAND_RESET_I(32);
    s_axi_awlen = VL_RAND_RESET_I(8);
    s_axi_awsize = VL_RAND_RESET_I(3);
    s_axi_awburst = VL_RAND_RESET_I(2);
    s_axi_awlock = VL_RAND_RESET_I(1);
    s_axi_awcache = VL_RAND_RESET_I(4);
    s_axi_awprot = VL_RAND_RESET_I(3);
    s_axi_awvalid = VL_RAND_RESET_I(1);
    s_axi_awready = VL_RAND_RESET_I(1);
    s_axi_wdata = VL_RAND_RESET_Q(64);
    s_axi_wstrb = VL_RAND_RESET_I(8);
    s_axi_wlast = VL_RAND_RESET_I(1);
    s_axi_wvalid = VL_RAND_RESET_I(1);
    s_axi_wready = VL_RAND_RESET_I(1);
    s_axi_bid = VL_RAND_RESET_I(4);
    s_axi_bresp = VL_RAND_RESET_I(2);
    s_axi_bvalid = VL_RAND_RESET_I(1);
    s_axi_bready = VL_RAND_RESET_I(1);
    s_axi_arid = VL_RAND_RESET_I(4);
    s_axi_araddr = VL_RAND_RESET_I(32);
    s_axi_arlen = VL_RAND_RESET_I(8);
    s_axi_arsize = VL_RAND_RESET_I(3);
    s_axi_arburst = VL_RAND_RESET_I(2);
    s_axi_arlock = VL_RAND_RESET_I(1);
    s_axi_arcache = VL_RAND_RESET_I(4);
    s_axi_arprot = VL_RAND_RESET_I(3);
    s_axi_arvalid = VL_RAND_RESET_I(1);
    s_axi_arready = VL_RAND_RESET_I(1);
    s_axi_rid = VL_RAND_RESET_I(4);
    s_axi_rdata = VL_RAND_RESET_Q(64);
    s_axi_rresp = VL_RAND_RESET_I(2);
    s_axi_rlast = VL_RAND_RESET_I(1);
    s_axi_rvalid = VL_RAND_RESET_I(1);
    s_axi_rready = VL_RAND_RESET_I(1);
    ddr2_clk = VL_RAND_RESET_I(1);
    ddr2_clk_n = VL_RAND_RESET_I(1);
    ddr2_cke = VL_RAND_RESET_I(1);
    ddr2_cs_n = VL_RAND_RESET_I(1);
    ddr2_ras_n = VL_RAND_RESET_I(1);
    ddr2_cas_n = VL_RAND_RESET_I(1);
    ddr2_we_n = VL_RAND_RESET_I(1);
    ddr2_ba = VL_RAND_RESET_I(3);
    ddr2_a = VL_RAND_RESET_I(13);
    ddr2_dq = VL_RAND_RESET_Q(64);
    ddr2_dqs = VL_RAND_RESET_I(8);
    ddr2_dqs_n = VL_RAND_RESET_I(8);
    ddr2_dm = VL_RAND_RESET_I(8);
    ddr2_axi_controller__DOT__current_state = VL_RAND_RESET_I(3);
    ddr2_axi_controller__DOT__refresh_counter = VL_RAND_RESET_I(16);
    ddr2_axi_controller__DOT__activate_count_window = VL_RAND_RESET_I(16);
    { int __Vi0=0; for (; __Vi0<4; ++__Vi0) {
            ddr2_axi_controller__DOT__activate_timestamps[__Vi0] = VL_RAND_RESET_Q(64);
    }}
    ddr2_axi_controller__DOT__last_activate_time = VL_RAND_RESET_Q(64);
    ddr2_axi_controller__DOT__last_precharge_time = VL_RAND_RESET_Q(64);
    ddr2_axi_controller__DOT__ddr2_cs_n_reg = VL_RAND_RESET_I(1);
    ddr2_axi_controller__DOT__ddr2_ras_n_reg = VL_RAND_RESET_I(1);
    ddr2_axi_controller__DOT__ddr2_cas_n_reg = VL_RAND_RESET_I(1);
    ddr2_axi_controller__DOT__ddr2_we_n_reg = VL_RAND_RESET_I(1);
    ddr2_axi_controller__DOT__ddr2_ba_reg = VL_RAND_RESET_I(3);
    ddr2_axi_controller__DOT__ddr2_a_reg = VL_RAND_RESET_I(13);
}
