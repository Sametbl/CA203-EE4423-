-f ./../../00_src/primitive_cell/primitive_cell_flist.f

./../../00_src/core/include/pipeline_pkg.sv
./../../01_bench/ansi_pkg.sv

./../../01_bench/tb_core.sv
./../../01_bench/tlib.svh
./../../01_bench/tb_icache_model.sv
./../../01_bench/tb_dcache_model.sv
./../../00_src/core/processor.sv
./../../00_src/core/writeback_arbiter.sv
./../../00_src/core/alu.sv
./../../00_src/core/bru.sv
./../../00_src/core/lsu.sv
./../../00_src/core/mul_unit.sv
./../../00_src/core/div_unit.sv
./../../00_src/core/arbitrator.sv
./../../00_src/core/forwarding_cell.sv
./../../00_src/core/forwarding_unit.sv
./../../00_src/core/int_regfile.sv
./../../00_src/core/hazard_detection.sv
./../../00_src/core/instruction_decoder.sv
./../../00_src/core/fetch_unit.sv
./../../00_src/core/branch_prediction/branch_prediction_unit.sv
./../../00_src/core/branch_prediction/btb.sv
./../../00_src/core/branch_prediction/saturation_adder_2bit.sv
