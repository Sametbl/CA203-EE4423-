// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_vending_machine_fsm.h for the primary calling header

#include "Vtb_vending_machine_fsm__pch.h"
#include "Vtb_vending_machine_fsm__Syms.h"
#include "Vtb_vending_machine_fsm___024root.h"

void Vtb_vending_machine_fsm___024root___ctor_var_reset(Vtb_vending_machine_fsm___024root* vlSelf);

Vtb_vending_machine_fsm___024root::Vtb_vending_machine_fsm___024root(Vtb_vending_machine_fsm__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , __VdlySched{*symsp->_vm_contextp__}
    , vlSymsp{symsp}
 {
    // Reset structure values
    Vtb_vending_machine_fsm___024root___ctor_var_reset(this);
}

void Vtb_vending_machine_fsm___024root::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

Vtb_vending_machine_fsm___024root::~Vtb_vending_machine_fsm___024root() {
}
