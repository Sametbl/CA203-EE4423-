// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_vending_machine_fsm.h for the primary calling header

#include "Vtb_vending_machine_fsm__pch.h"
#include "Vtb_vending_machine_fsm__Syms.h"
#include "Vtb_vending_machine_fsm___024root.h"

VL_ATTR_COLD void Vtb_vending_machine_fsm___024root___eval_initial__TOP(Vtb_vending_machine_fsm___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtb_vending_machine_fsm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_vending_machine_fsm___024root___eval_initial__TOP\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSymsp->_vm_contextp__->dumpfile(std::string{"wave.vcd"});
    vlSymsp->_traceDumpOpen();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_vending_machine_fsm___024root___dump_triggers__stl(Vtb_vending_machine_fsm___024root* vlSelf);
#endif  // VL_DEBUG

VL_ATTR_COLD void Vtb_vending_machine_fsm___024root___eval_triggers__stl(Vtb_vending_machine_fsm___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtb_vending_machine_fsm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_vending_machine_fsm___024root___eval_triggers__stl\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VstlTriggered.set(0U, (IData)(vlSelfRef.__VstlFirstIteration));
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vtb_vending_machine_fsm___024root___dump_triggers__stl(vlSelf);
    }
#endif
}
