
# Don't run anything by default
.PHONY: all
all:

SELF_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

# Don't delete these
.PRECIOUS: build/%.d build/%.blif build/%.bin build/%.asc

# Top module
TOP ?= top

# Tool paths

# Use apio toolchain
TOOLCHAIN = $(HOME)/.apio/packages/toolchain-icestorm/bin
export PATH := $(TOOLCHAIN):$(PATH)

YOSYS ?= yosys
PNR ?= arachne-pnr
ICEPACK ?= icepack
ICEPROG ?= iceprog
TINYPROG ?= tinyprog
ICETIME ?= icetime
IVERILOG ?= iverilog
GTKWAVE ?= gtkwave

SHARE_ICEBOX = $$(dirname $$(which $(ICETIME)))/../share/icebox

ifeq ($(USE_SUDO),1)
ICEPROG := sudo $$(which $(ICEPROG))
TINYPROG := sudo $$(which $(TINYPROG))
endif

# Board-specific configuration

BOARD ?= icestick
PCF := $(SELF_DIR)/pcf/$(BOARD).pcf

YOSYS_OPTS =

ifeq ($(BOARD),icestick)
PNR_OPTS = -d 1k -P tq144
DEVICE = hx1k
CHIPDB = 1k
PROG = $(ICEPROG)
endif

ifeq ($(BOARD),bx)
PNR_OPTS = -d 8k -P cm81
DEVICE = lp8k
CHIPDB = 8k
PROG = $(TINYPROG) -p
endif

# To use install 'moreutils'

CHRONIC =
ifndef VERBOSE
PNR_OPTS := -q $(PNR_OPTS)
YOSYS_OPTS := -q $(YOSYS_OPTS)
CHRONIC = $(shell which chronic)
endif

# Dependencies

build/%.d: %.v
	@mkdir -p $(dir $@)
	@$(SELF_DIR)/make-deps $(@:.d=.bx.blif) $< > $@
	@$(SELF_DIR)/make-deps $(@:.d=.icestick.blif) $< >> $@
	@$(SELF_DIR)/make-deps $(@:.d=.out) $< >> $@

# Synthesis

build/%.$(BOARD).blif: %.v build/%.d
	$(YOSYS) $(YOSYS_OPTS) \
		-p "verilog_defines -DBOARD_$(BOARD) -DBOARD=$(BOARD)" \
		-p "read_verilog -noautowire $<" \
		-p "synth_ice40 -top $(TOP) -blif $@"

build/%.$(BOARD).asc: build/%.$(BOARD).blif $(PCF)
	$(PNR) -p $(PCF) $(PNR_OPTS) $< -o $@

ifdef RAM_FILE
# Use icebram to replace memory contents.
build/%.bin: build/%.asc $(RAM_FILE)
	icebram random.hex build/default.hex < $< > $<.replaced
	$(ICEPACK) $<.replaced $@
else
build/%.bin: build/%.asc
	$(ICEPACK) $< $@
endif

# Simulation

build/%.out: %.v build/%.d
	$(IVERILOG) -grelative-include -DVCD_FILE=\"build/$(<:.v=.vcd)\" -o $@ $<

# Top-level goals (flash, sim, run, time)

TESTS = $(shell find -name '*_tb.v')

flash sim run time::
ifeq ($(V),)
	$(error Define target name first, e.g.: make run V=myfile.v)
endif

.PHONY: flash
flash:: build/$(V:.v=.$(BOARD).bin)
	$(PROG) $<

.PHONY: sim
sim:: run
	$(GTKWAVE) build/$(V:.v=.vcd)

.PHONY: run
run:: build/$(V:.v=.out)
	./$<

.PHONY: time
time:: build/$(V:.v=.$(BOARD).asc)
	$(ICETIME) -d $(DEVICE) -C $(SHARE_ICEBOX)/chipdb-$(CHIPDB).txt $<

.PHONY: test
test::
	@set -e; \
	for v in $(TESTS); do \
		echo $(MAKE) run V=$$v; \
		$(CHRONIC) $(MAKE) run V=$$v; \
	done; \
	echo "All OK"

# Cleanup

.PHONY: clean
clean:
	rm -f build/*

include $(find build -name '*.d')
