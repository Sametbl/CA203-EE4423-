// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtb_vending_machine_fsm.h for the primary calling header

#ifndef VERILATED_VTB_VENDING_MACHINE_FSM___024UNIT_H_
#define VERILATED_VTB_VENDING_MACHINE_FSM___024UNIT_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"


class Vtb_vending_machine_fsm__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vtb_vending_machine_fsm___024unit final : public VerilatedModule {
  public:

    // INTERNAL VARIABLES
    Vtb_vending_machine_fsm__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vtb_vending_machine_fsm___024unit(Vtb_vending_machine_fsm__Syms* symsp, const char* v__name);
    ~Vtb_vending_machine_fsm___024unit();
    VL_UNCOPYABLE(Vtb_vending_machine_fsm___024unit);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
