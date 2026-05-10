# Sync FIFO Lab Makefile

ROOT      := $(abspath $(CURDIR)/..)
RTL_DIR   := $(ROOT)/rtl
TB_DIR    := $(ROOT)/tb
BUILD_DIR := $(CURDIR)/build

IVERILOG  ?= iverilog
VVP       ?= vvp
GTKWAVE   ?= gtkwave
IV_FLAGS  := -g2012 -Wall

SOURCES := \
    $(RTL_DIR)/sync_fifo.v \
    $(TB_DIR)/handshake_checker.v \
    $(TB_DIR)/tb_top.sv

SIM_BIN := $(BUILD_DIR)/sim.vvp
NUM_TESTS := 5

TC_NAMES := \
    01_reset_behavior \
    02_single_push_pop \
    03_empty_blocks_out_valid \
    04_fill_then_drain \
    05_full_blocks_in_ready

.PHONY: all test wave clean compile help
all: test

help:
	@echo "make test         - run all $(NUM_TESTS) testcases"
	@echo "make test TC=<N>  - run only testcase N"
	@echo "make wave TC=<N>  - run testcase N with VCD dump + GTKWave"
	@echo "make clean        - remove build artifacts"

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

compile: $(SIM_BIN)
$(SIM_BIN): $(SOURCES) | $(BUILD_DIR)
	@echo "[iverilog] compiling..."
	@$(IVERILOG) $(IV_FLAGS) -o $@ $(SOURCES)

test: compile
ifeq ($(strip $(TC)),)
	@pass=0; fail=0; \
	for n in $$(seq 1 $(NUM_TESTS)); do \
	    name=$$(echo "$(TC_NAMES)" | tr ' ' '\n' | sed -n "$${n}p"); \
	    out=$$($(VVP) $(SIM_BIN) +TC=$$n 2>&1); \
	    res=$$(echo "$$out" | grep "^TEST_RESULT:" | head -n1); \
	    if echo "$$res" | grep -q "PASS"; then \
	        printf "[\033[32mPASS\033[0m] %s\n" "$$name"; \
	        pass=$$((pass+1)); \
	    else \
	        reason=$$(echo "$$res" | sed 's/^TEST_RESULT: FAIL *//'); \
	        printf "[\033[31mFAIL\033[0m] %s   %s\n" "$$name" "$$reason"; \
	        fail=$$((fail+1)); \
	    fi; \
	done; \
	echo "----------------------------------------"; \
	printf "FIFO: \033[1m%d / %d passed\033[0m\n" $$pass $(NUM_TESTS); \
	echo "$$pass/$(NUM_TESTS)" > $(BUILD_DIR)/result.txt; \
	if [ "$$fail" -ne 0 ]; then exit 1; fi
else
	@$(VVP) $(SIM_BIN) +TC=$(TC)
endif

wave: compile
ifeq ($(strip $(TC)),)
	@echo "Usage: make wave TC=<N>"; exit 1
else
	@$(VVP) $(SIM_BIN) +TC=$(TC) +DUMP
	@$(GTKWAVE) $(BUILD_DIR)/wave.vcd >/dev/null 2>&1 &
endif

clean:
	rm -rf $(BUILD_DIR)
