// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_vending_machine_fsm.h for the primary calling header

#include "Vtb_vending_machine_fsm__pch.h"
#include "Vtb_vending_machine_fsm___024root.h"

VL_ATTR_COLD void Vtb_vending_machine_fsm___024root___eval_static(Vtb_vending_machine_fsm___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtb_vending_machine_fsm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_vending_machine_fsm___024root___eval_static\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
}

VL_ATTR_COLD void Vtb_vending_machine_fsm___024root___eval_final(Vtb_vending_machine_fsm___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtb_vending_machine_fsm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_vending_machine_fsm___024root___eval_final\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_vending_machine_fsm___024root___dump_triggers__stl(Vtb_vending_machine_fsm___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vtb_vending_machine_fsm___024root___eval_phase__stl(Vtb_vending_machine_fsm___024root* vlSelf);

VL_ATTR_COLD void Vtb_vending_machine_fsm___024root___eval_settle(Vtb_vending_machine_fsm___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtb_vending_machine_fsm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_vending_machine_fsm___024root___eval_settle\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*31:0*/ __VstlIterCount;
    CData/*0:0*/ __VstlContinue;
    // Body
    __VstlIterCount = 0U;
    vlSelfRef.__VstlFirstIteration = 1U;
    __VstlContinue = 1U;
    while (__VstlContinue) {
        if (VL_UNLIKELY((0x64U < __VstlIterCount))) {
#ifdef VL_DEBUG
            Vtb_vending_machine_fsm___024root___dump_triggers__stl(vlSelf);
#endif
            VL_FATAL_MT("../01_bench/tb_vending_machine_fsm.sv", 10, "", "Settle region did not converge.");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        __VstlContinue = 0U;
        if (Vtb_vending_machine_fsm___024root___eval_phase__stl(vlSelf)) {
            __VstlContinue = 1U;
        }
        vlSelfRef.__VstlFirstIteration = 0U;
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_vending_machine_fsm___024root___dump_triggers__stl(Vtb_vending_machine_fsm___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtb_vending_machine_fsm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_vending_machine_fsm___024root___dump_triggers__stl\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VstlTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VstlTriggered.word(0U))) {
        VL_DBG_MSGF("         'stl' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vtb_vending_machine_fsm___024root___stl_sequent__TOP__0(Vtb_vending_machine_fsm___024root* vlSelf);
VL_ATTR_COLD void Vtb_vending_machine_fsm___024root____Vm_traceActivitySetAll(Vtb_vending_machine_fsm___024root* vlSelf);

VL_ATTR_COLD void Vtb_vending_machine_fsm___024root___eval_stl(Vtb_vending_machine_fsm___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtb_vending_machine_fsm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_vending_machine_fsm___024root___eval_stl\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VstlTriggered.word(0U))) {
        Vtb_vending_machine_fsm___024root___stl_sequent__TOP__0(vlSelf);
        Vtb_vending_machine_fsm___024root____Vm_traceActivitySetAll(vlSelf);
    }
}

extern const VlUnpacked<CData/*0:0*/, 16> Vtb_vending_machine_fsm__ConstPool__TABLE_hff1c52be_0;
extern const VlUnpacked<CData/*2:0*/, 16> Vtb_vending_machine_fsm__ConstPool__TABLE_h97924eb4_0;
extern const VlUnpacked<CData/*3:0*/, 128> Vtb_vending_machine_fsm__ConstPool__TABLE_h6e15b7fd_0;

VL_ATTR_COLD void Vtb_vending_machine_fsm___024root___stl_sequent__TOP__0(Vtb_vending_machine_fsm___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtb_vending_machine_fsm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_vending_machine_fsm___024root___stl_sequent__TOP__0\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*6:0*/ __Vtableidx1;
    __Vtableidx1 = 0;
    CData/*3:0*/ __Vtableidx2;
    __Vtableidx2 = 0;
    CData/*3:0*/ __Vtableidx3;
    __Vtableidx3 = 0;
    // Body
    __Vtableidx2 = vlSelfRef.tb_vending_machine_fsm__DOT__dut__DOT__current_state;
    vlSelfRef.tb_vending_machine_fsm__DOT__dut_soda 
        = Vtb_vending_machine_fsm__ConstPool__TABLE_hff1c52be_0
        [__Vtableidx2];
    __Vtableidx3 = vlSelfRef.tb_vending_machine_fsm__DOT__dut__DOT__current_state;
    vlSelfRef.tb_vending_machine_fsm__DOT__dut_change 
        = Vtb_vending_machine_fsm__ConstPool__TABLE_h97924eb4_0
        [__Vtableidx3];
    __Vtableidx1 = (((IData)(vlSelfRef.tb_vending_machine_fsm__DOT__tb_quarter) 
                     << 6U) | (((IData)(vlSelfRef.tb_vending_machine_fsm__DOT__tb_dime) 
                                << 5U) | (((IData)(vlSelfRef.tb_vending_machine_fsm__DOT__tb_nickle) 
                                           << 4U) | (IData)(vlSelfRef.tb_vending_machine_fsm__DOT__dut__DOT__current_state))));
    vlSelfRef.tb_vending_machine_fsm__DOT__dut__DOT__next_state 
        = Vtb_vending_machine_fsm__ConstPool__TABLE_h6e15b7fd_0
        [__Vtableidx1];
}

VL_ATTR_COLD void Vtb_vending_machine_fsm___024root___eval_triggers__stl(Vtb_vending_machine_fsm___024root* vlSelf);

VL_ATTR_COLD bool Vtb_vending_machine_fsm___024root___eval_phase__stl(Vtb_vending_machine_fsm___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtb_vending_machine_fsm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_vending_machine_fsm___024root___eval_phase__stl\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VstlExecute;
    // Body
    Vtb_vending_machine_fsm___024root___eval_triggers__stl(vlSelf);
    __VstlExecute = vlSelfRef.__VstlTriggered.any();
    if (__VstlExecute) {
        Vtb_vending_machine_fsm___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_vending_machine_fsm___024root___dump_triggers__act(Vtb_vending_machine_fsm___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtb_vending_machine_fsm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_vending_machine_fsm___024root___dump_triggers__act\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VactTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 0 is active: @(posedge tb_vending_machine_fsm.clk)\n");
    }
    if ((2ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 1 is active: @(negedge tb_vending_machine_fsm.rstn)\n");
    }
    if ((4ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 2 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_vending_machine_fsm___024root___dump_triggers__nba(Vtb_vending_machine_fsm___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtb_vending_machine_fsm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_vending_machine_fsm___024root___dump_triggers__nba\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VnbaTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 0 is active: @(posedge tb_vending_machine_fsm.clk)\n");
    }
    if ((2ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 1 is active: @(negedge tb_vending_machine_fsm.rstn)\n");
    }
    if ((4ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 2 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vtb_vending_machine_fsm___024root____Vm_traceActivitySetAll(Vtb_vending_machine_fsm___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtb_vending_machine_fsm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_vending_machine_fsm___024root____Vm_traceActivitySetAll\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__Vm_traceActivity[0U] = 1U;
    vlSelfRef.__Vm_traceActivity[1U] = 1U;
}

VL_ATTR_COLD void Vtb_vending_machine_fsm___024root___ctor_var_reset(Vtb_vending_machine_fsm___024root* vlSelf) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtb_vending_machine_fsm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_vending_machine_fsm___024root___ctor_var_reset\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelf->tb_vending_machine_fsm__DOT__clk = VL_RAND_RESET_I(1);
    vlSelf->tb_vending_machine_fsm__DOT__rstn = VL_RAND_RESET_I(1);
    vlSelf->tb_vending_machine_fsm__DOT__tb_nickle = VL_RAND_RESET_I(1);
    vlSelf->tb_vending_machine_fsm__DOT__tb_dime = VL_RAND_RESET_I(1);
    vlSelf->tb_vending_machine_fsm__DOT__tb_quarter = VL_RAND_RESET_I(1);
    vlSelf->tb_vending_machine_fsm__DOT__dut_soda = VL_RAND_RESET_I(1);
    vlSelf->tb_vending_machine_fsm__DOT__dut_change = VL_RAND_RESET_I(3);
    vlSelf->tb_vending_machine_fsm__DOT__dut__DOT__current_state = VL_RAND_RESET_I(4);
    vlSelf->tb_vending_machine_fsm__DOT__dut__DOT__next_state = VL_RAND_RESET_I(4);
    vlSelf->__Vtrigprevexpr___TOP__tb_vending_machine_fsm__DOT__clk__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigprevexpr___TOP__tb_vending_machine_fsm__DOT__rstn__0 = VL_RAND_RESET_I(1);
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        vlSelf->__Vm_traceActivity[__Vi0] = 0;
    }
}
