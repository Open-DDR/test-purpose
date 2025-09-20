// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Primary design header
//
// This header should be included by all source files instantiating the design.
// The class here is then constructed to instantiate the design.
// See the Verilator manual for examples.

#ifndef _VDDR2_AXI_CONTROLLER_H_
#define _VDDR2_AXI_CONTROLLER_H_  // guard

#include "verilated_heavy.h"

//==========

class Vddr2_axi_controller__Syms;

//----------

VL_MODULE(Vddr2_axi_controller) {
  public:
    
    // PORTS
    // The application code writes and reads these signals to
    // propagate new values into/out from the Verilated model.
    VL_IN8(ddr_clk,0,0);
    VL_IN8(ddr_rst_n,0,0);
    VL_IN8(axi_aclk,0,0);
    VL_IN8(axi_aresetn,0,0);
    VL_IN8(s_axi_awid,3,0);
    VL_IN8(s_axi_awlen,7,0);
    VL_IN8(s_axi_awsize,2,0);
    VL_IN8(s_axi_awburst,1,0);
    VL_IN8(s_axi_awlock,0,0);
    VL_IN8(s_axi_awcache,3,0);
    VL_IN8(s_axi_awprot,2,0);
    VL_IN8(s_axi_awvalid,0,0);
    VL_OUT8(s_axi_awready,0,0);
    VL_IN8(s_axi_wstrb,7,0);
    VL_IN8(s_axi_wlast,0,0);
    VL_IN8(s_axi_wvalid,0,0);
    VL_OUT8(s_axi_wready,0,0);
    VL_OUT8(s_axi_bid,3,0);
    VL_OUT8(s_axi_bresp,1,0);
    VL_OUT8(s_axi_bvalid,0,0);
    VL_IN8(s_axi_bready,0,0);
    VL_IN8(s_axi_arid,3,0);
    VL_IN8(s_axi_arlen,7,0);
    VL_IN8(s_axi_arsize,2,0);
    VL_IN8(s_axi_arburst,1,0);
    VL_IN8(s_axi_arlock,0,0);
    VL_IN8(s_axi_arcache,3,0);
    VL_IN8(s_axi_arprot,2,0);
    VL_IN8(s_axi_arvalid,0,0);
    VL_OUT8(s_axi_arready,0,0);
    VL_OUT8(s_axi_rid,3,0);
    VL_OUT8(s_axi_rresp,1,0);
    VL_OUT8(s_axi_rlast,0,0);
    VL_OUT8(s_axi_rvalid,0,0);
    VL_IN8(s_axi_rready,0,0);
    VL_OUT8(ddr2_clk,0,0);
    VL_OUT8(ddr2_clk_n,0,0);
    VL_OUT8(ddr2_cke,0,0);
    VL_OUT8(ddr2_cs_n,0,0);
    VL_OUT8(ddr2_ras_n,0,0);
    VL_OUT8(ddr2_cas_n,0,0);
    VL_OUT8(ddr2_we_n,0,0);
    VL_OUT8(ddr2_ba,2,0);
    VL_INOUT8(ddr2_dqs,7,0);
    VL_INOUT8(ddr2_dqs_n,7,0);
    VL_OUT8(ddr2_dm,7,0);
    VL_OUT16(ddr2_a,12,0);
    VL_IN(s_axi_awaddr,31,0);
    VL_IN(s_axi_araddr,31,0);
    VL_IN64(s_axi_wdata,63,0);
    VL_OUT64(s_axi_rdata,63,0);
    VL_INOUT64(ddr2_dq,63,0);
    
    // LOCAL SIGNALS
    // Internals; generally not touched by application code
    CData/*2:0*/ ddr2_axi_controller__DOT__current_state;
    CData/*0:0*/ ddr2_axi_controller__DOT__ddr2_cs_n_reg;
    CData/*0:0*/ ddr2_axi_controller__DOT__ddr2_ras_n_reg;
    CData/*0:0*/ ddr2_axi_controller__DOT__ddr2_cas_n_reg;
    CData/*0:0*/ ddr2_axi_controller__DOT__ddr2_we_n_reg;
    CData/*2:0*/ ddr2_axi_controller__DOT__ddr2_ba_reg;
    SData/*15:0*/ ddr2_axi_controller__DOT__refresh_counter;
    SData/*15:0*/ ddr2_axi_controller__DOT__activate_count_window;
    SData/*12:0*/ ddr2_axi_controller__DOT__ddr2_a_reg;
    QData/*63:0*/ ddr2_axi_controller__DOT__last_activate_time;
    QData/*63:0*/ ddr2_axi_controller__DOT__last_precharge_time;
    QData/*63:0*/ ddr2_axi_controller__DOT__activate_timestamps[4];
    
    // LOCAL VARIABLES
    // Internals; generally not touched by application code
    CData/*0:0*/ __Vclklast__TOP__ddr_clk;
    CData/*0:0*/ __Vclklast__TOP__ddr_rst_n;
    
    // INTERNAL VARIABLES
    // Internals; generally not touched by application code
    Vddr2_axi_controller__Syms* __VlSymsp;  // Symbol table
    
    // CONSTRUCTORS
  private:
    VL_UNCOPYABLE(Vddr2_axi_controller);  ///< Copying not allowed
  public:
    /// Construct the model; called by application code
    /// The special name  may be used to make a wrapper with a
    /// single model invisible with respect to DPI scope names.
    Vddr2_axi_controller(const char* name = "TOP");
    /// Destroy the model; called (often implicitly) by application code
    ~Vddr2_axi_controller();
    
    // API METHODS
    /// Evaluate the model.  Application must call when inputs change.
    void eval() { eval_step(); }
    /// Evaluate when calling multiple units/models per time step.
    void eval_step();
    /// Evaluate at end of a timestep for tracing, when using eval_step().
    /// Application must call after all eval() and before time changes.
    void eval_end_step() {}
    /// Simulation complete, run final blocks.  Application must call on completion.
    void final();
    
    // INTERNAL METHODS
  private:
    static void _eval_initial_loop(Vddr2_axi_controller__Syms* __restrict vlSymsp);
  public:
    void __Vconfigure(Vddr2_axi_controller__Syms* symsp, bool first);
  private:
    static QData _change_request(Vddr2_axi_controller__Syms* __restrict vlSymsp);
    static QData _change_request_1(Vddr2_axi_controller__Syms* __restrict vlSymsp);
  public:
    static void _combo__TOP__2(Vddr2_axi_controller__Syms* __restrict vlSymsp);
    static void _combo__TOP__6(Vddr2_axi_controller__Syms* __restrict vlSymsp);
  private:
    void _ctor_var_reset() VL_ATTR_COLD;
  public:
    static void _eval(Vddr2_axi_controller__Syms* __restrict vlSymsp);
  private:
#ifdef VL_DEBUG
    void _eval_debug_assertions();
#endif  // VL_DEBUG
  public:
    static void _eval_initial(Vddr2_axi_controller__Syms* __restrict vlSymsp) VL_ATTR_COLD;
    static void _eval_settle(Vddr2_axi_controller__Syms* __restrict vlSymsp) VL_ATTR_COLD;
    static void _initial__TOP__1(Vddr2_axi_controller__Syms* __restrict vlSymsp) VL_ATTR_COLD;
    static void _sequent__TOP__4(Vddr2_axi_controller__Syms* __restrict vlSymsp);
    static void _sequent__TOP__5(Vddr2_axi_controller__Syms* __restrict vlSymsp);
    static void _settle__TOP__3(Vddr2_axi_controller__Syms* __restrict vlSymsp) VL_ATTR_COLD;
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);

//----------


#endif  // guard
