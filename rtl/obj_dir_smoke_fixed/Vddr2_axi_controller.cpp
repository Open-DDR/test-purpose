// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vddr2_axi_controller.h for the primary calling header

#include "Vddr2_axi_controller.h"
#include "Vddr2_axi_controller__Syms.h"

//==========

void Vddr2_axi_controller::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vddr2_axi_controller::eval\n"); );
    Vddr2_axi_controller__Syms* __restrict vlSymsp = this->__VlSymsp;  // Setup global symbol table
    Vddr2_axi_controller* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
#ifdef VL_DEBUG
    // Debug assertions
    _eval_debug_assertions();
#endif  // VL_DEBUG
    // Initialize
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) _eval_initial_loop(vlSymsp);
    // Evaluate till stable
    int __VclockLoop = 0;
    QData __Vchange = 1;
    do {
        VL_DEBUG_IF(VL_DBG_MSGF("+ Clock loop\n"););
        _eval(vlSymsp);
        if (VL_UNLIKELY(++__VclockLoop > 100)) {
            // About to fail, so enable debug to see what's not settling.
            // Note you must run make with OPT=-DVL_DEBUG for debug prints.
            int __Vsaved_debug = Verilated::debug();
            Verilated::debug(1);
            __Vchange = _change_request(vlSymsp);
            Verilated::debug(__Vsaved_debug);
            VL_FATAL_MT("/aws/home/jayb/proj/open-ddr/test-purpose/rtl/ddr2_axi_controller_verilator_clean.sv", 6, "",
                "Verilated model didn't converge\n"
                "- See DIDNOTCONVERGE in the Verilator manual");
        } else {
            __Vchange = _change_request(vlSymsp);
        }
    } while (VL_UNLIKELY(__Vchange));
}

void Vddr2_axi_controller::_eval_initial_loop(Vddr2_axi_controller__Syms* __restrict vlSymsp) {
    vlSymsp->__Vm_didInit = true;
    _eval_initial(vlSymsp);
    // Evaluate till stable
    int __VclockLoop = 0;
    QData __Vchange = 1;
    do {
        _eval_settle(vlSymsp);
        _eval(vlSymsp);
        if (VL_UNLIKELY(++__VclockLoop > 100)) {
            // About to fail, so enable debug to see what's not settling.
            // Note you must run make with OPT=-DVL_DEBUG for debug prints.
            int __Vsaved_debug = Verilated::debug();
            Verilated::debug(1);
            __Vchange = _change_request(vlSymsp);
            Verilated::debug(__Vsaved_debug);
            VL_FATAL_MT("/aws/home/jayb/proj/open-ddr/test-purpose/rtl/ddr2_axi_controller_verilator_clean.sv", 6, "",
                "Verilated model didn't DC converge\n"
                "- See DIDNOTCONVERGE in the Verilator manual");
        } else {
            __Vchange = _change_request(vlSymsp);
        }
    } while (VL_UNLIKELY(__Vchange));
}

VL_INLINE_OPT void Vddr2_axi_controller::_combo__TOP__2(Vddr2_axi_controller__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vddr2_axi_controller::_combo__TOP__2\n"); );
    Vddr2_axi_controller* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->ddr2_clk = vlTOPp->ddr_clk;
    vlTOPp->ddr2_clk_n = (1U & (~ (IData)(vlTOPp->ddr_clk)));
    vlTOPp->ddr2_cke = vlTOPp->ddr_rst_n;
    vlTOPp->s_axi_bid = vlTOPp->s_axi_awid;
    vlTOPp->s_axi_rid = vlTOPp->s_axi_arid;
}

VL_INLINE_OPT void Vddr2_axi_controller::_sequent__TOP__4(Vddr2_axi_controller__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vddr2_axi_controller::_sequent__TOP__4\n"); );
    Vddr2_axi_controller* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    if ((((IData)(vlTOPp->ddr_rst_n) & (1U == (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state))) 
         & (4U <= (IData)(vlTOPp->ddr2_axi_controller__DOT__activate_count_window)))) {
        if (VL_UNLIKELY(((VL_TIME_UNITED_D(1000) - 
                          VL_ITOR_D_I((IData)(vlTOPp->ddr2_axi_controller__DOT__activate_timestamps
                                              [(3U 
                                                & (IData)(vlTOPp->ddr2_axi_controller__DOT__activate_count_window))]))) 
                         < 50.0))) {
            VL_WRITEF("[%0t] %%Error: ddr2_axi_controller_verilator_clean.sv:277: Assertion failed in %Nddr2_axi_controller: tFAW violation: Four activates within 50.0 ns at time %0^\n",
                      64,VL_TIME_UNITED_Q(1000),vlSymsp->name(),
                      64,(1.00000000000000011e+03 * (QData)(VL_TIME_UNITED_D(1000))));
            VL_STOP_MT("/aws/home/jayb/proj/open-ddr/test-purpose/rtl/ddr2_axi_controller_verilator_clean.sv", 277, "");
        }
    }
    if (((IData)(vlTOPp->ddr_rst_n) & ((2U == (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state)) 
                                       | (3U == (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state))))) {
        if (VL_UNLIKELY(((VL_TIME_UNITED_D(1000) - 
                          VL_ITOR_D_I((IData)(vlTOPp->ddr2_axi_controller__DOT__last_activate_time))) 
                         < 15.0))) {
            VL_WRITEF("[%0t] %%Error: ddr2_axi_controller_verilator_clean.sv:283: Assertion failed in %Nddr2_axi_controller: tRCD violation: RAS to CAS delay 15.0 ns not met at time %0^\n",
                      64,VL_TIME_UNITED_Q(1000),vlSymsp->name(),
                      64,(1.00000000000000011e+03 * (QData)(VL_TIME_UNITED_D(1000))));
            VL_STOP_MT("/aws/home/jayb/proj/open-ddr/test-purpose/rtl/ddr2_axi_controller_verilator_clean.sv", 283, "");
        }
    }
    if (((IData)(vlTOPp->ddr_rst_n) & (1U == (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state)))) {
        if (VL_UNLIKELY(((VL_TIME_UNITED_D(1000) - 
                          VL_ITOR_D_I((IData)(vlTOPp->ddr2_axi_controller__DOT__last_precharge_time))) 
                         < 15.0))) {
            VL_WRITEF("[%0t] %%Error: ddr2_axi_controller_verilator_clean.sv:289: Assertion failed in %Nddr2_axi_controller: tRP violation: RAS precharge time 15.0 ns not met at time %0^\n",
                      64,VL_TIME_UNITED_Q(1000),vlSymsp->name(),
                      64,(1.00000000000000011e+03 * (QData)(VL_TIME_UNITED_D(1000))));
            VL_STOP_MT("/aws/home/jayb/proj/open-ddr/test-purpose/rtl/ddr2_axi_controller_verilator_clean.sv", 289, "");
        }
    }
    vlTOPp->ddr2_axi_controller__DOT__ddr2_we_n_reg 
        = (1U & ((~ (IData)(vlTOPp->ddr_rst_n)) | (
                                                   (4U 
                                                    & (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state))
                                                    ? 
                                                   (((IData)(vlTOPp->ddr2_axi_controller__DOT__current_state) 
                                                     >> 1U) 
                                                    | (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state))
                                                    : 
                                                   ((~ 
                                                     ((IData)(vlTOPp->ddr2_axi_controller__DOT__current_state) 
                                                      >> 1U)) 
                                                    | (~ (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state))))));
    vlTOPp->ddr2_axi_controller__DOT__ddr2_cas_n_reg 
        = (1U & ((~ (IData)(vlTOPp->ddr_rst_n)) | (
                                                   (4U 
                                                    & (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state))
                                                    ? 
                                                   (((IData)(vlTOPp->ddr2_axi_controller__DOT__current_state) 
                                                     >> 1U) 
                                                    | (~ (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state)))
                                                    : 
                                                   (~ 
                                                    ((IData)(vlTOPp->ddr2_axi_controller__DOT__current_state) 
                                                     >> 1U)))));
    vlTOPp->ddr2_axi_controller__DOT__ddr2_ras_n_reg 
        = (1U & ((~ (IData)(vlTOPp->ddr_rst_n)) | (
                                                   (4U 
                                                    & (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state))
                                                    ? 
                                                   ((IData)(vlTOPp->ddr2_axi_controller__DOT__current_state) 
                                                    >> 1U)
                                                    : 
                                                   (((IData)(vlTOPp->ddr2_axi_controller__DOT__current_state) 
                                                     >> 1U) 
                                                    | (~ (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state))))));
    vlTOPp->ddr2_axi_controller__DOT__ddr2_cs_n_reg 
        = (1U & ((~ (IData)(vlTOPp->ddr_rst_n)) | (
                                                   (4U 
                                                    & (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state))
                                                    ? 
                                                   ((IData)(vlTOPp->ddr2_axi_controller__DOT__current_state) 
                                                    >> 1U)
                                                    : 
                                                   ((~ 
                                                     ((IData)(vlTOPp->ddr2_axi_controller__DOT__current_state) 
                                                      >> 1U)) 
                                                    & (~ (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state))))));
    if (vlTOPp->ddr_rst_n) {
        if ((1U & (~ ((IData)(vlTOPp->ddr2_axi_controller__DOT__current_state) 
                      >> 2U)))) {
            if ((1U & (~ ((IData)(vlTOPp->ddr2_axi_controller__DOT__current_state) 
                          >> 1U)))) {
                if ((1U & (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state))) {
                    vlTOPp->ddr2_axi_controller__DOT__ddr2_ba_reg 
                        = (7U & ((IData)(vlTOPp->s_axi_awvalid)
                                  ? (vlTOPp->s_axi_awaddr 
                                     >> 0xdU) : (vlTOPp->s_axi_araddr 
                                                 >> 0xdU)));
                }
            }
        }
    } else {
        vlTOPp->ddr2_axi_controller__DOT__ddr2_ba_reg = 0U;
    }
    if (vlTOPp->ddr_rst_n) {
        if ((4U & (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state))) {
            if ((1U & (~ ((IData)(vlTOPp->ddr2_axi_controller__DOT__current_state) 
                          >> 1U)))) {
                if ((1U & (~ (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state)))) {
                    vlTOPp->ddr2_axi_controller__DOT__ddr2_a_reg 
                        = (0x400U | (IData)(vlTOPp->ddr2_axi_controller__DOT__ddr2_a_reg));
                }
            }
        } else {
            if ((2U & (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state))) {
                vlTOPp->ddr2_axi_controller__DOT__ddr2_a_reg 
                    = (0x1bffU & (IData)(vlTOPp->ddr2_axi_controller__DOT__ddr2_a_reg));
            } else {
                if ((1U & (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state))) {
                    vlTOPp->ddr2_axi_controller__DOT__ddr2_a_reg 
                        = (0x1fffU & ((IData)(vlTOPp->s_axi_awvalid)
                                       ? (vlTOPp->s_axi_awaddr 
                                          >> 0xdU) : 
                                      (vlTOPp->s_axi_araddr 
                                       >> 0xdU)));
                }
            }
        }
    } else {
        vlTOPp->ddr2_axi_controller__DOT__ddr2_a_reg = 0U;
    }
    vlTOPp->ddr2_we_n = vlTOPp->ddr2_axi_controller__DOT__ddr2_we_n_reg;
    vlTOPp->ddr2_cas_n = vlTOPp->ddr2_axi_controller__DOT__ddr2_cas_n_reg;
    vlTOPp->ddr2_ras_n = vlTOPp->ddr2_axi_controller__DOT__ddr2_ras_n_reg;
    vlTOPp->ddr2_cs_n = vlTOPp->ddr2_axi_controller__DOT__ddr2_cs_n_reg;
    vlTOPp->ddr2_ba = vlTOPp->ddr2_axi_controller__DOT__ddr2_ba_reg;
    vlTOPp->ddr2_a = vlTOPp->ddr2_axi_controller__DOT__ddr2_a_reg;
}

VL_INLINE_OPT void Vddr2_axi_controller::_sequent__TOP__5(Vddr2_axi_controller__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vddr2_axi_controller::_sequent__TOP__5\n"); );
    Vddr2_axi_controller* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Variables
    CData/*2:0*/ __Vdly__ddr2_axi_controller__DOT__current_state;
    CData/*1:0*/ __Vdlyvdim0__ddr2_axi_controller__DOT__activate_timestamps__v0;
    CData/*0:0*/ __Vdlyvset__ddr2_axi_controller__DOT__activate_timestamps__v0;
    CData/*0:0*/ __Vdlyvset__ddr2_axi_controller__DOT__activate_timestamps__v1;
    SData/*15:0*/ __Vdly__ddr2_axi_controller__DOT__refresh_counter;
    QData/*63:0*/ __Vdlyvval__ddr2_axi_controller__DOT__activate_timestamps__v0;
    // Body
    __Vdly__ddr2_axi_controller__DOT__refresh_counter 
        = vlTOPp->ddr2_axi_controller__DOT__refresh_counter;
    __Vdly__ddr2_axi_controller__DOT__current_state 
        = vlTOPp->ddr2_axi_controller__DOT__current_state;
    __Vdlyvset__ddr2_axi_controller__DOT__activate_timestamps__v0 = 0U;
    __Vdlyvset__ddr2_axi_controller__DOT__activate_timestamps__v1 = 0U;
    if (vlTOPp->ddr_rst_n) {
        if ((4U & (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state))) {
            __Vdly__ddr2_axi_controller__DOT__current_state = 0U;
        } else {
            if ((2U & (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state))) {
                __Vdly__ddr2_axi_controller__DOT__current_state = 0U;
            } else {
                if ((1U & (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state))) {
                    if (vlTOPp->s_axi_awvalid) {
                        __Vdly__ddr2_axi_controller__DOT__current_state = 3U;
                    } else {
                        if (vlTOPp->s_axi_arvalid) {
                            __Vdly__ddr2_axi_controller__DOT__current_state = 2U;
                        } else {
                            __Vdly__ddr2_axi_controller__DOT__current_state = 4U;
                            vlTOPp->ddr2_axi_controller__DOT__last_precharge_time 
                                = VL_RTOIROUND_Q_D(64, VL_TIME_UNITED_D(1000));
                        }
                    }
                } else {
                    if (((IData)(vlTOPp->s_axi_arvalid) 
                         | (IData)(vlTOPp->s_axi_awvalid))) {
                        __Vdly__ddr2_axi_controller__DOT__current_state = 1U;
                        vlTOPp->ddr2_axi_controller__DOT__last_activate_time 
                            = VL_RTOIROUND_Q_D(64, VL_TIME_UNITED_D(1000));
                        __Vdlyvval__ddr2_axi_controller__DOT__activate_timestamps__v0 
                            = VL_RTOIROUND_Q_D(64, VL_TIME_UNITED_D(1000));
                        __Vdlyvset__ddr2_axi_controller__DOT__activate_timestamps__v0 = 1U;
                        __Vdlyvdim0__ddr2_axi_controller__DOT__activate_timestamps__v0 
                            = (3U & (IData)(vlTOPp->ddr2_axi_controller__DOT__activate_count_window));
                        vlTOPp->ddr2_axi_controller__DOT__activate_count_window 
                            = (0xffffU & ((IData)(1U) 
                                          + (IData)(vlTOPp->ddr2_axi_controller__DOT__activate_count_window)));
                    }
                }
            }
        }
        __Vdly__ddr2_axi_controller__DOT__refresh_counter 
            = (0xffffU & ((IData)(1U) + (IData)(vlTOPp->ddr2_axi_controller__DOT__refresh_counter)));
        if ((0x3e8U <= (IData)(vlTOPp->ddr2_axi_controller__DOT__refresh_counter))) {
            if ((0U == (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state))) {
                __Vdly__ddr2_axi_controller__DOT__current_state = 5U;
            }
            __Vdly__ddr2_axi_controller__DOT__refresh_counter = 0U;
        }
    } else {
        vlTOPp->ddr2_axi_controller__DOT__activate_count_window = 0U;
        __Vdly__ddr2_axi_controller__DOT__current_state = 0U;
        vlTOPp->ddr2_axi_controller__DOT__last_activate_time = 0ULL;
        vlTOPp->ddr2_axi_controller__DOT__last_precharge_time = 0ULL;
        __Vdly__ddr2_axi_controller__DOT__refresh_counter = 0U;
        __Vdlyvset__ddr2_axi_controller__DOT__activate_timestamps__v1 = 1U;
    }
    vlTOPp->ddr2_axi_controller__DOT__refresh_counter 
        = __Vdly__ddr2_axi_controller__DOT__refresh_counter;
    if (__Vdlyvset__ddr2_axi_controller__DOT__activate_timestamps__v0) {
        vlTOPp->ddr2_axi_controller__DOT__activate_timestamps[__Vdlyvdim0__ddr2_axi_controller__DOT__activate_timestamps__v0] 
            = __Vdlyvval__ddr2_axi_controller__DOT__activate_timestamps__v0;
    }
    if (__Vdlyvset__ddr2_axi_controller__DOT__activate_timestamps__v1) {
        vlTOPp->ddr2_axi_controller__DOT__activate_timestamps[0U] = 0ULL;
        vlTOPp->ddr2_axi_controller__DOT__activate_timestamps[1U] = 0ULL;
        vlTOPp->ddr2_axi_controller__DOT__activate_timestamps[2U] = 0ULL;
        vlTOPp->ddr2_axi_controller__DOT__activate_timestamps[3U] = 0ULL;
    }
    vlTOPp->ddr2_axi_controller__DOT__current_state 
        = __Vdly__ddr2_axi_controller__DOT__current_state;
    vlTOPp->s_axi_wready = (3U == (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state));
    vlTOPp->s_axi_bvalid = (4U == (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state));
    vlTOPp->s_axi_rvalid = (2U == (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state));
}

VL_INLINE_OPT void Vddr2_axi_controller::_combo__TOP__6(Vddr2_axi_controller__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vddr2_axi_controller::_combo__TOP__6\n"); );
    Vddr2_axi_controller* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->s_axi_awready = ((0U == (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state)) 
                             & (~ (IData)(vlTOPp->s_axi_arvalid)));
    vlTOPp->s_axi_arready = ((0U == (IData)(vlTOPp->ddr2_axi_controller__DOT__current_state)) 
                             & (~ (IData)(vlTOPp->s_axi_awvalid)));
}

void Vddr2_axi_controller::_eval(Vddr2_axi_controller__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vddr2_axi_controller::_eval\n"); );
    Vddr2_axi_controller* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->_combo__TOP__2(vlSymsp);
    if (((IData)(vlTOPp->ddr_clk) & (~ (IData)(vlTOPp->__Vclklast__TOP__ddr_clk)))) {
        vlTOPp->_sequent__TOP__4(vlSymsp);
    }
    if ((((IData)(vlTOPp->ddr_clk) & (~ (IData)(vlTOPp->__Vclklast__TOP__ddr_clk))) 
         | ((~ (IData)(vlTOPp->ddr_rst_n)) & (IData)(vlTOPp->__Vclklast__TOP__ddr_rst_n)))) {
        vlTOPp->_sequent__TOP__5(vlSymsp);
    }
    vlTOPp->_combo__TOP__6(vlSymsp);
    // Final
    vlTOPp->__Vclklast__TOP__ddr_clk = vlTOPp->ddr_clk;
    vlTOPp->__Vclklast__TOP__ddr_rst_n = vlTOPp->ddr_rst_n;
}

VL_INLINE_OPT QData Vddr2_axi_controller::_change_request(Vddr2_axi_controller__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vddr2_axi_controller::_change_request\n"); );
    Vddr2_axi_controller* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    return (vlTOPp->_change_request_1(vlSymsp));
}

VL_INLINE_OPT QData Vddr2_axi_controller::_change_request_1(Vddr2_axi_controller__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vddr2_axi_controller::_change_request_1\n"); );
    Vddr2_axi_controller* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    // Change detection
    QData __req = false;  // Logically a bool
    return __req;
}

#ifdef VL_DEBUG
void Vddr2_axi_controller::_eval_debug_assertions() {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vddr2_axi_controller::_eval_debug_assertions\n"); );
    // Body
    if (VL_UNLIKELY((axi_aclk & 0xfeU))) {
        Verilated::overWidthError("axi_aclk");}
    if (VL_UNLIKELY((axi_aresetn & 0xfeU))) {
        Verilated::overWidthError("axi_aresetn");}
    if (VL_UNLIKELY((ddr_clk & 0xfeU))) {
        Verilated::overWidthError("ddr_clk");}
    if (VL_UNLIKELY((ddr_rst_n & 0xfeU))) {
        Verilated::overWidthError("ddr_rst_n");}
    if (VL_UNLIKELY((s_axi_awid & 0xf0U))) {
        Verilated::overWidthError("s_axi_awid");}
    if (VL_UNLIKELY((s_axi_awsize & 0xf8U))) {
        Verilated::overWidthError("s_axi_awsize");}
    if (VL_UNLIKELY((s_axi_awburst & 0xfcU))) {
        Verilated::overWidthError("s_axi_awburst");}
    if (VL_UNLIKELY((s_axi_awlock & 0xfeU))) {
        Verilated::overWidthError("s_axi_awlock");}
    if (VL_UNLIKELY((s_axi_awcache & 0xf0U))) {
        Verilated::overWidthError("s_axi_awcache");}
    if (VL_UNLIKELY((s_axi_awprot & 0xf8U))) {
        Verilated::overWidthError("s_axi_awprot");}
    if (VL_UNLIKELY((s_axi_awvalid & 0xfeU))) {
        Verilated::overWidthError("s_axi_awvalid");}
    if (VL_UNLIKELY((s_axi_wlast & 0xfeU))) {
        Verilated::overWidthError("s_axi_wlast");}
    if (VL_UNLIKELY((s_axi_wvalid & 0xfeU))) {
        Verilated::overWidthError("s_axi_wvalid");}
    if (VL_UNLIKELY((s_axi_bready & 0xfeU))) {
        Verilated::overWidthError("s_axi_bready");}
    if (VL_UNLIKELY((s_axi_arid & 0xf0U))) {
        Verilated::overWidthError("s_axi_arid");}
    if (VL_UNLIKELY((s_axi_arsize & 0xf8U))) {
        Verilated::overWidthError("s_axi_arsize");}
    if (VL_UNLIKELY((s_axi_arburst & 0xfcU))) {
        Verilated::overWidthError("s_axi_arburst");}
    if (VL_UNLIKELY((s_axi_arlock & 0xfeU))) {
        Verilated::overWidthError("s_axi_arlock");}
    if (VL_UNLIKELY((s_axi_arcache & 0xf0U))) {
        Verilated::overWidthError("s_axi_arcache");}
    if (VL_UNLIKELY((s_axi_arprot & 0xf8U))) {
        Verilated::overWidthError("s_axi_arprot");}
    if (VL_UNLIKELY((s_axi_arvalid & 0xfeU))) {
        Verilated::overWidthError("s_axi_arvalid");}
    if (VL_UNLIKELY((s_axi_rready & 0xfeU))) {
        Verilated::overWidthError("s_axi_rready");}
}
#endif  // VL_DEBUG
