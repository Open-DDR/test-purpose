// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table implementation internals

#include "Vddr2_axi_controller__Syms.h"
#include "Vddr2_axi_controller.h"



// FUNCTIONS
Vddr2_axi_controller__Syms::Vddr2_axi_controller__Syms(Vddr2_axi_controller* topp, const char* namep)
    // Setup locals
    : __Vm_namep(namep)
    , __Vm_didInit(false)
    // Setup submodule names
{
    // Pointer to top level
    TOPp = topp;
    // Setup each module's pointers to their submodules
    // Setup each module's pointer back to symbol table (for public functions)
    TOPp->__Vconfigure(this, true);
    // Setup scopes
    __Vscope_ddr2_axi_controller.configure(this, name(), "ddr2_axi_controller", "ddr2_axi_controller", -9, VerilatedScope::SCOPE_OTHER);
}
