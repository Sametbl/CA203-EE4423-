BENCHMARK := coremark

ARCH    := rv32im
ABI     := ilp32
PADSIZE := 256k

TOOLCHAIN_PREFIX := riscv32-unknown-elf-
CC               := $(TOOLCHAIN_PREFIX)gcc
OBJDUMP          := $(TOOLCHAIN_PREFIX)objdump
OBJCOPY          := $(TOOLCHAIN_PREFIX)objcopy
READELF          := $(TOOLCHAIN_PREFIX)readelf
STRIPELF         := $(TOOLCHAIN_PREFIX)strip

LOG := build.log

ROOT_DIR  := .
SRC_DIR   := $(ROOT_DIR)/src
BUILD_DIR := $(ROOT_DIR)/build

INC_DIRS  := $(ROOT_DIR)/
INC_DIRS  += $(shell find $(SRC_DIR) -type d)
INC_FLAGS := $(addprefix -I,$(INC_DIRS))

SRCS = $(shell find ./src -name '*.c' -or -name '*.S')
OBJS = $(patsubst .%.c, $(BUILD_DIR)%.o, \
	   $(patsubst .%.S, $(BUILD_DIR)%.o, $(SRCS)))
LDS  = $(shell find ./src -name '*.lds')


ifeq ("$(ITERATIONS)","")
	ITERATIONS=10
endif

ASM_MACRO ?= -D__ASSEMBLY__=1

COMMON_FLAGS := -O2 -funroll-loops -fpeel-loops -fgcse-sm -fgcse-las
FLAGS_STR = "$(COMMON_FLAGS)"

CFLAGS += $(COMMON_FLAGS) -g -fverbose-asm
CFLAGS += -static -std=gnu99 -fno-common -fno-builtin-printf -DTCM=$(TCM)
CFLAGS += -Wa,-march=$(ARCH) -march=$(ARCH) -mabi=$(ABI)
CFLAGS += -DFLAGS_STR=\"$(FLAGS_STR)\"
CFLAGS += -DITERATIONS=$(ITERATIONS) -DPERFORMANCE_RUN=1 -DBARE_METAL=1 #-DCORE_DEBUG=1
CFLAGS += $(ADD_FLAGS)

LDFLAGS ?= -nostartfiles -nostdlib -lc -lgcc -march=$(ARCH) -mabi=$(ABI)

VPATH += $(ROOT_DIR) $(SRC_DIR) $(INC_DIRS)

.PHONY: all
all:
	@(\
		$(MAKE) clean; \
		$(MAKE) check; \
		echo '[BUILD]'; \
		$(MAKE) build; \
		# $(MAKE) dump; \
	) 2>&1 | tee $(LOG)

.PHONY: check
check:
	@echo '[INFO]'
	@echo 'Root dir    :' $(ROOT_DIR)
	@echo 'Source dir  :' $(SRC_DIR)
	@echo 'Build dir   :' $(BUILD_DIR)
	@echo 'Include dir :' $(INC_DIRS)
	@echo 'Source files:' $(SRCS)
	@echo 'Object files:' $(OBJS)
	@echo 'Link script :' $(LDS)
	@echo '[TOOL]'
	@$(CC) --version | head -n 1
	@$(OBJDUMP) --version | head -n 1
	@$(OBJCOPY) --version | head -n 1
	@$(READELF) --version | head -n 1
	@$(STRIPELF) --version | head -n 1
	@od --version | head -n1
	@hexdump --version | head -n1

.PHONY: build
build: $(BUILD_DIR)/$(BENCHMARK).dump   \
       $(BUILD_DIR)/$(BENCHMARK).vhex   \
       $(BUILD_DIR)/$(BENCHMARK).hex    \
       $(BUILD_DIR)/$(BENCHMARK)_1b.hex \
       $(BUILD_DIR)/$(BENCHMARK)_4b.hex

.PHONY: dump
dump:
	$(OBJDUMP) -D $(BUILD_DIR)/$(BENCHMARK).elf > $(BUILD_DIR)/$(BENCHMARK).dump:

.PHONY: clean
clean:
	@rm -rvf $(BUILD_DIR)

$(BUILD_DIR)/%.o : %.S
	@mkdir -pv $(dir $@)
	$(CC) $(CFLAGS) $(ASM_MACRO) $(INC_FLAGS) -c $< -o $@

$(BUILD_DIR)/%.o : %.c
	@mkdir -pv $(dir $@)
	$(CC) $(CFLAGS) $(INC_FLAGS) -c $< -o $@

$(BUILD_DIR)/$(BENCHMARK).elf : $(LDS) $(OBJS)
	$(CC) -o $@ -T $^ $(LDFLAGS)
	$(STRIPELF) $(BUILD_DIR)/$(BENCHMARK).elf

$(BUILD_DIR)/$(BENCHMARK).dump: $(BUILD_DIR)/$(BENCHMARK).elf
	$(OBJDUMP) -t -D -S -l -C -M no-aliases -M numeric $^ > $@

$(BUILD_DIR)/$(BENCHMARK).bin: $(BUILD_DIR)/$(BENCHMARK).elf
	$(OBJCOPY) -O binary $^ $@

$(BUILD_DIR)/$(BENCHMARK).vhex: $(BUILD_DIR)/$(BENCHMARK).elf
	$(OBJCOPY) -O verilog  $^ $@

$(BUILD_DIR)/$(BENCHMARK).hex: $(BUILD_DIR)/$(BENCHMARK).bin
	od -t x4 -An -w4 -v $^ > $@

$(BUILD_DIR)/$(BENCHMARK)_padded.bin: $(BUILD_DIR)/$(BENCHMARK).bin
	cp $< $(BUILD_DIR)/tmp.bin
	cp $< $@
	dd if=/dev/zero bs=$(PADSIZE) count=1 >> $(BUILD_DIR)/tmp.bin
	dd if=$(BUILD_DIR)/tmp.bin bs=$(PADSIZE) count=1 > $@
	rm -f $(BUILD_DIR)/tmp.bin

$(BUILD_DIR)/$(BENCHMARK)_1b.hex: $(BUILD_DIR)/$(BENCHMARK)_padded.bin
	hexdump -v -e '1/1 "%02x" "\n"' $< > $@

$(BUILD_DIR)/$(BENCHMARK)_4b.hex: $(BUILD_DIR)/$(BENCHMARK)_padded.bin
	hexdump -v -e '1/4 "%08x" "\n"' $< > $@
