flist   := ./flist.f
seed    := 1
top      = tb_core


wave_vcd   := ./wave.vcd
wave_fsdb  := ./wave.fsdb
wave_state := ./wave.ron

# Verilator
# Update .ron file name
VERI_FLAGS   = --binary -Wall --trace --sv --timing
VERI_FLAGS   += -O3 --compiler gcc -CFLAGS -std=gnu++20
VERI_FLAGS   += -x-initial unique
VERI_FLAGS   += -x-assign unique
VERI_FLAGS   += --assert
VERI_FLAGS   += --build -j 0 --quiet --trace-fst
VERI_FLAGS   += --Wno-PINCONNECTEMPTY -Wno-IMPORTSTAR
VERI_FLAGS   += -Wno-UNUSEDSIGNAL -Wno-DECLFILENAME -Wno-UNDRIVEN
VERI_LFLAGS  = --lint-only --sv --timing
VERI_RFLAGS  =  +verilator+seed+$(seed)
VERI_RFLAGS += +verilator+quiet

# tb_file := ./../../01_bench/tb_core_alu.sv

.PHONY: xrun
xrun:
	xrun $(GUI) +xm64bit -sv \
	-vlogext .sv \
	-f $(flist) \
	+define+FSDB +fsdb+delta \
	-timescale 1ns/1ps \
	+access+rcw

sdf_diag := +sdfverbose -nonbaudpsched
sdf_anno := -sdf min:synth_wrapper:05_sta/synth_wrapper.sdf 
#delay_mode := +nolibcell
sdf_diag := +sdfverbose -nonbaudpsched
sdf_anno := -sdf min:synth_wrapper:05_sta/synth_wrapper.sdf 

.PHONY: lint
lint: run_lint.tcl
	$(MAKE) clean
	@rm -f report_lint.txt 
	vc_static_shell -f $^
	nvim report_lint.txt


.PHONY: vcs
vcs:
	vcs -sverilog \
	$(RAD) \
	$(test_file) \
	-f $(flist) \
	-timescale=1ns/1ps \
	+define+FSDB \
	-debug_access+all \
	-debug_region+cell | tee vcs.log
	./simv | tee sim.log




.PHONY: verdi
verdi:
	verdi -lca -sv \
	-f $(flist) &

.PHONY: fsdb2vcd
fsdb2vcd:
	fsdb2vcd -compacttree -vcs -keep_last_time $(wave_fsdb) -o $(wave_vcd)

work_dir := qts_work

vlog_flag := -sv -svinputport=var -work $(work_dir) +define+VCD

vsim_flag := -c -t 1ps -sv_seed $(seed) -sva
vsim_flag += -suppress vsim-8630 -suppress vsim-8604
vsim_flag += +define+VCD
vsim_flag += -assertfile asrt.log +dumpports+direction
vsim_flag += -L $(work_dir) -voptargs="+acc"

.PHONY: vlib
vlib:
	@if [ -d "$(work_dir)" ]; then vdel -lib $(work_dir) -all; fi
	vlib $(work_dir)

# .PHONY: vmap
# vmap:
# 	vmap work $(work_dir)

.PHONY: vlog
vlog:
	vlog $(vlog_flag) -f $(flist) 2>&1 -logfile vlog.log

.PHONY: vsim
vsim: $(work_dir)
	vsim $(vsim_flag) $(top) -do "run -all" 2>&1 -logfile vsim.log

.PHONY: qts
qts: vlib vlog vsim

.PHONY: surfer
surfer:
	@if [ -f "$(wave_state)" ]; then surfer -s $(wave_state) $(wave_vcd); else surfer $(wave_vcd); fi


.PHONY: clean
clean:
	@echo "-> CLEAN"
	@rm -f *.log
	@rm -f *.txt
	@rm -f xrun.*
	@rm -f wave.*
	@rm -f *.hex
	@rm -f report_lint.txt
	@rm -rf fsdb2vcdLog
	@rm -rf csrc
	@rm -rf simv.daidir
	@rm -f  ucli.key
	@rm -f  simv
	@rm -rf genus.cmd genus.log xrun.history xrun.key xcelium.d *.shm flex* $(work_dir) work vcst*
	@rm -rf ./obj_dir *.vcd




.PHONY: veri_lint
veri_lint:
	clear
	@echo "-> LINT"
	verilator $(VERI_LFLAGS) -f $(flist) --top-module $(top)

.PHONY: veri_sim
veri_sim:
	clear
	@echo "-> SIMULATION"
	verilator $(VERI_FLAGS) -f $(flist) --top-module $(top) 2>&1 | tee log

.PHONY: veri_run
veri_run:
	@echo "-> RUN"
	./obj_dir/V$(top) $(VERI_RFLAGS)

.PHONY: wave
wave:
	surfer wave.vcd &

.PHONY: veri
veri: 
	@echo "-> Build all"
	$(MAKE) clean
	$(MAKE) veri_lint
	$(MAKE) veri_sim
	$(MAKE) veri_run
	$(MAKE) surfer &






