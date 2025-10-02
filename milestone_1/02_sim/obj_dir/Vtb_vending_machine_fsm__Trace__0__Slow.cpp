// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals
#include "verilated_fst_c.h"
#include "Vtb_vending_machine_fsm__Syms.h"


VL_ATTR_COLD void Vtb_vending_machine_fsm___024root__trace_init_sub__TOP__0(Vtb_vending_machine_fsm___024root* vlSelf, VerilatedFst* tracep) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtb_vending_machine_fsm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_vending_machine_fsm___024root__trace_init_sub__TOP__0\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
    // Init
    const int c = vlSymsp->__Vm_baseCode;
    // Body
    tracep->pushPrefix("tb_vending_machine_fsm", VerilatedTracePrefixType::SCOPE_MODULE);
    tracep->declBit(c+4,0,"clk",-1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::VAR, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+5,0,"rstn",-1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::VAR, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+6,0,"tb_nickle",-1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::VAR, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+7,0,"tb_dime",-1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::VAR, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+8,0,"tb_quarter",-1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::VAR, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+1,0,"dut_soda",-1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::VAR, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBus(c+2,0,"dut_change",-1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::VAR, VerilatedTraceSigType::LOGIC, false,-1, 2,0);
    tracep->pushPrefix("dut", VerilatedTracePrefixType::SCOPE_MODULE);
    tracep->declBit(c+4,0,"i_clk",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+5,0,"i_rstn",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+6,0,"i_nickle",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+7,0,"i_dime",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+8,0,"i_quarter",-1, VerilatedTraceSigDirection::INPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBit(c+1,0,"o_soda",-1, VerilatedTraceSigDirection::OUTPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1);
    tracep->declBus(c+2,0,"o_change",-1, VerilatedTraceSigDirection::OUTPUT, VerilatedTraceSigKind::WIRE, VerilatedTraceSigType::LOGIC, false,-1, 2,0);
    tracep->declBus(c+3,0,"current_state",1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::VAR, VerilatedTraceSigType::LOGIC, false,-1, 3,0);
    tracep->declBus(c+9,0,"next_state",1, VerilatedTraceSigDirection::NONE, VerilatedTraceSigKind::VAR, VerilatedTraceSigType::LOGIC, false,-1, 3,0);
    tracep->popPrefix();
    tracep->popPrefix();
}

VL_ATTR_COLD void Vtb_vending_machine_fsm___024root__trace_init_top(Vtb_vending_machine_fsm___024root* vlSelf, VerilatedFst* tracep) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtb_vending_machine_fsm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_vending_machine_fsm___024root__trace_init_top\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
    // Body
    Vtb_vending_machine_fsm___024root__trace_init_sub__TOP__0(vlSelf, tracep);
}

VL_ATTR_COLD void Vtb_vending_machine_fsm___024root__trace_const_0(void* voidSelf, VerilatedFst::Buffer* bufp);
VL_ATTR_COLD void Vtb_vending_machine_fsm___024root__trace_full_0(void* voidSelf, VerilatedFst::Buffer* bufp);
void Vtb_vending_machine_fsm___024root__trace_chg_0(void* voidSelf, VerilatedFst::Buffer* bufp);
void Vtb_vending_machine_fsm___024root__trace_cleanup(void* voidSelf, VerilatedFst* /*unused*/);

VL_ATTR_COLD void Vtb_vending_machine_fsm___024root__trace_register(Vtb_vending_machine_fsm___024root* vlSelf, VerilatedFst* tracep) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtb_vending_machine_fsm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_vending_machine_fsm___024root__trace_register\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
    // Body
    tracep->addConstCb(&Vtb_vending_machine_fsm___024root__trace_const_0, 0U, vlSelf);
    tracep->addFullCb(&Vtb_vending_machine_fsm___024root__trace_full_0, 0U, vlSelf);
    tracep->addChgCb(&Vtb_vending_machine_fsm___024root__trace_chg_0, 0U, vlSelf);
    tracep->addCleanupCb(&Vtb_vending_machine_fsm___024root__trace_cleanup, vlSelf);
}

VL_ATTR_COLD void Vtb_vending_machine_fsm___024root__trace_const_0(void* voidSelf, VerilatedFst::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_vending_machine_fsm___024root__trace_const_0\n"); );
    // Init
    Vtb_vending_machine_fsm___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vtb_vending_machine_fsm___024root*>(voidSelf);
    Vtb_vending_machine_fsm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
}

VL_ATTR_COLD void Vtb_vending_machine_fsm___024root__trace_full_0_sub_0(Vtb_vending_machine_fsm___024root* vlSelf, VerilatedFst::Buffer* bufp);

VL_ATTR_COLD void Vtb_vending_machine_fsm___024root__trace_full_0(void* voidSelf, VerilatedFst::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_vending_machine_fsm___024root__trace_full_0\n"); );
    // Init
    Vtb_vending_machine_fsm___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vtb_vending_machine_fsm___024root*>(voidSelf);
    Vtb_vending_machine_fsm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    // Body
    Vtb_vending_machine_fsm___024root__trace_full_0_sub_0((&vlSymsp->TOP), bufp);
}

VL_ATTR_COLD void Vtb_vending_machine_fsm___024root__trace_full_0_sub_0(Vtb_vending_machine_fsm___024root* vlSelf, VerilatedFst::Buffer* bufp) {
    (void)vlSelf;  // Prevent unused variable warning
    Vtb_vending_machine_fsm__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_vending_machine_fsm___024root__trace_full_0_sub_0\n"); );
    auto &vlSelfRef = std::ref(*vlSelf).get();
    // Init
    uint32_t* const oldp VL_ATTR_UNUSED = bufp->oldp(vlSymsp->__Vm_baseCode);
    // Body
    bufp->fullBit(oldp+1,(vlSelfRef.tb_vending_machine_fsm__DOT__dut_soda));
    bufp->fullCData(oldp+2,(vlSelfRef.tb_vending_machine_fsm__DOT__dut_change),3);
    bufp->fullCData(oldp+3,(vlSelfRef.tb_vending_machine_fsm__DOT__dut__DOT__current_state),4);
    bufp->fullBit(oldp+4,(vlSelfRef.tb_vending_machine_fsm__DOT__clk));
    bufp->fullBit(oldp+5,(vlSelfRef.tb_vending_machine_fsm__DOT__rstn));
    bufp->fullBit(oldp+6,(vlSelfRef.tb_vending_machine_fsm__DOT__tb_nickle));
    bufp->fullBit(oldp+7,(vlSelfRef.tb_vending_machine_fsm__DOT__tb_dime));
    bufp->fullBit(oldp+8,(vlSelfRef.tb_vending_machine_fsm__DOT__tb_quarter));
    bufp->fullCData(oldp+9,(vlSelfRef.tb_vending_machine_fsm__DOT__dut__DOT__next_state),4);
}
