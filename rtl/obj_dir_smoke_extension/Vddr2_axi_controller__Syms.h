// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef _VDDR2_AXI_CONTROLLER__SYMS_H_
#define _VDDR2_AXI_CONTROLLER__SYMS_H_  // guard

#include "verilated_heavy.h"

// INCLUDE MODULE CLASSES
#include "Vddr2_axi_controller.h"

// SYMS CLASS
class Vddr2_axi_controller__Syms : public VerilatedSyms {
  public:
    
    // LOCAL STATE
    const char* __Vm_namep;
    bool __Vm_didInit;
    
    // SUBCELL STATE
    Vddr2_axi_controller*          TOPp;
    
    // SCOPE NAMES
    VerilatedScope __Vscope_ddr2_axi_controller;
    
    // CREATORS
    Vddr2_axi_controller__Syms(Vddr2_axi_controller* topp, const char* namep);
    ~Vddr2_axi_controller__Syms() {}
    
    // METHODS
    inline const char* name() { return __Vm_namep; }
    
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);

#endif  // guard
