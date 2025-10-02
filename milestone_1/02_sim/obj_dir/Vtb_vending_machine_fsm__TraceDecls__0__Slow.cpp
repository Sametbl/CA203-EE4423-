// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing declarations
#include "verilated_fst_c.h"


void Vtb_vending_machine_fsm___024root__traceDeclTypesSub0(VerilatedFst* tracep) {
    {
        const char* __VenumItemNames[]
        = {"ZERO", "FIVE", "TEN", "FIFTEEN", "TWENTY", 
                                "TWENTY_FIVE", "THIRTY", 
                                "THIRTY_FIVE", "FORTY"};
        const char* __VenumItemValues[]
        = {"0", "1", "10", "11", "100", "101", "110", 
                                "111", "1000"};
        tracep->declDTypeEnum(1, "vending_machine_fsm.state_t", 9, 4, __VenumItemNames, __VenumItemValues);
    }
}

void Vtb_vending_machine_fsm___024root__trace_decl_types(VerilatedFst* tracep) {
    Vtb_vending_machine_fsm___024root__traceDeclTypesSub0(tracep);
}
