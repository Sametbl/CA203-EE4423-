// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_vending_machine_fsm.h for the primary calling header

#include "Vtb_vending_machine_fsm__pch.h"
#include "Vtb_vending_machine_fsm__Syms.h"
#include "Vtb_vending_machine_fsm___024root.h"

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_vending_machine_fsm___024root___dump_triggers__act(Vtb_vending_machine_fsm___024root* vlSelf);
#endif  // VL_DEBUG

void Vtb_vending_machine_fsm___024root___eval_triggers__act(Vtb_vending_machine_fsm___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtb_vending_machine_fsm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_vending_machine_fsm___024root___eval_triggers__act\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VactTriggered.set(0U, ((IData)(vlSelfRef.tb_vending_machine_fsm__DOT__clk) 
                                       & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__tb_vending_machine_fsm__DOT__clk__0))));
    vlSelfRef.__VactTriggered.set(1U, ((~ (IData)(vlSelfRef.tb_vending_machine_fsm__DOT__rstn)) 
                                       & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__tb_vending_machine_fsm__DOT__rstn__0)));
    vlSelfRef.__VactTriggered.set(2U, vlSelfRef.__VdlySched.awaitingCurrentTime());
    vlSelfRef.__Vtrigprevexpr___TOP__tb_vending_machine_fsm__DOT__clk__0 
        = vlSelfRef.tb_vending_machine_fsm__DOT__clk;
    vlSelfRef.__Vtrigprevexpr___TOP__tb_vending_machine_fsm__DOT__rstn__0 
        = vlSelfRef.tb_vending_machine_fsm__DOT__rstn;
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vtb_vending_machine_fsm___024root___dump_triggers__act(vlSelf);
    }
#endif
}
