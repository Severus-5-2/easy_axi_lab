# Easy AXI Lab - 顶层 Makefile

ROOT       := $(abspath $(CURDIR)/..)
FIFO_DIR   := $(ROOT)/labs/fifo/sim
AXI_DIR    := $(ROOT)/labs/axi_lite/sim

.PHONY: all test test-fifo test-axi wave clean help

all: test

help:
	@echo "make test          - 跑两个 lab"
	@echo "make test-fifo     - 只跑 FIFO"
	@echo "make test-axi      - 只跑 AXI-Lite"
	@echo "make wave LAB=fifo|axi TC=<N>"
	@echo "make clean"

test-fifo:
	@$(MAKE) -s -C $(FIFO_DIR) test

test-axi:
	@$(MAKE) -s -C $(AXI_DIR) test

test:
	@echo "==================== Sync FIFO ===================="
	@$(MAKE) -s -C $(FIFO_DIR) test; fifo_rc=$$?; \
	echo ""; \
	echo "================= AXI-Lite Slave =================="; \
	$(MAKE) -s -C $(AXI_DIR) test; axi_rc=$$?; \
	echo ""; \
	fifo_res=$$(cat $(FIFO_DIR)/build/result.txt 2>/dev/null || echo "0/5"); \
	axi_res=$$(cat $(AXI_DIR)/build/result.txt 2>/dev/null || echo "0/5"); \
	echo "=========================================================="; \
	printf "FIFO     : %s passed\n" "$$fifo_res"; \
	printf "AXI-Lite : %s passed\n" "$$axi_res"

wave:
ifeq ($(strip $(LAB)),fifo)
	@$(MAKE) -s -C $(FIFO_DIR) wave TC=$(TC)
else ifeq ($(strip $(LAB)),axi)
	@$(MAKE) -s -C $(AXI_DIR) wave TC=$(TC)
else
	@echo "Usage: make wave LAB=fifo|axi TC=<N>"; exit 1
endif

clean:
	@$(MAKE) -s -C $(FIFO_DIR) clean
	@$(MAKE) -s -C $(AXI_DIR) clean
