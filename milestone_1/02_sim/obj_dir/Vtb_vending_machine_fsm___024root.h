// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtb_vending_machine_fsm.h for the primary calling header

#ifndef VERILATED_VTB_VENDING_MACHINE_FSM___024ROOT_H_
#define VERILATED_VTB_VENDING_MACHINE_FSM___024ROOT_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"


class Vtb_vending_machine_fsm__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vtb_vending_machine_fsm___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    CData/*0:0*/ tb_vending_machine_fsm__DOT__clk;
    CData/*0:0*/ tb_vending_machine_fsm__DOT__rstn;
    CData/*0:0*/ tb_vending_machine_fsm__DOT__tb_nickle;
    CData/*0:0*/ tb_vending_machine_fsm__DOT__tb_dime;
    CData/*0:0*/ tb_vending_machine_fsm__DOT__tb_quarter;
    CData/*0:0*/ tb_vending_machine_fsm__DOT__dut_soda;
    CData/*2:0*/ tb_vending_machine_fsm__DOT__dut_change;
    CData/*3:0*/ tb_vending_machine_fsm__DOT__dut__DOT__current_state;
    CData/*3:0*/ tb_vending_machine_fsm__DOT__dut__DOT__next_state;
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __Vtrigprevexpr___TOP__tb_vending_machine_fsm__DOT__clk__0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__tb_vending_machine_fsm__DOT__rstn__0;
    CData/*0:0*/ __VactContinue;
    IData/*31:0*/ __VactIterCount;
    VlUnpacked<CData/*0:0*/, 2> __Vm_traceActivity;
    VlDelayScheduler __VdlySched;
    VlTriggerScheduler __VtrigSched_had9e2268__0;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<3> __VactTriggered;
    VlTriggerVec<3> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vtb_vending_machine_fsm__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vtb_vending_machine_fsm___024root(Vtb_vending_machine_fsm__Syms* symsp, const char* v__name);
    ~Vtb_vending_machine_fsm___024root();
    VL_UNCOPYABLE(Vtb_vending_machine_fsm___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
