YOSYS ?= yosys
PNR ?= arachne-pnr
ICEPACK ?= icepack
ICEPROG ?= iceprog
TINYPROG ?= tinyprog
ICETIME ?= icetime
IVERILOG ?= iverilog
GTKWAVE ?= gtkwave

MAKEDEPS = ./make-deps

BOARD ?= icestick

ifeq ($(BOARD),icestick)
PNR_OPTS = -d 1k -P tq144
DEVICE = hx1k
endif

ifeq ($(BOARD),bx)
PNR_OPTS = -d 8k -P cm81
DEVICE = lp8k
endif

.PHONY: all
all:

build/display_hello.blif: font.mem text.mem

text.mem: text.txt
	hexdump -v -e '/1 "%02X "' $< > $@

.PRECIOUS: build/%.d build/%.blif build/%.bin %.d

build/%.d: %.v $(MAKEDEPS)
	$(MAKEDEPS) $(@:.d=.bx.blif) $< > $@
	$(MAKEDEPS) $(@:.d=.icestick.blif) $< > $@
	$(MAKEDEPS) $(@:.d=.out) $< >> $@

build/%.$(BOARD).blif: %.v build/%.d
	$(YOSYS) -q -p "verilog_defines -DBOARD_$(BOARD) -DBOARD=$(BOARD); read_verilog $<; synth_ice40 -blif $@"

build/%.$(BOARD).asc: build/%.$(BOARD).blif $(BOARD).pcf
	$(PNR) -p $(BOARD).pcf $(PNR_OPTS) $< -o $@

build/%.$(BOARD).bin: build/%.$(BOARD).asc
	$(ICEPACK) $< $@

build/%.vcd: build/%.out
	cd build && ./$<

build/%.out: %.v build/%.d
	$(IVERILOG) $< -o $@

.PHONY: flash
flash: check-target build/$(V:.v=.$(BOARD).bin)
ifeq ($(BOARD),icestick)
	$(ICEPROG) build/$(V:.v=.$(BOARD).bin)
endif
ifeq ($(BOARD),bx)
	$(TINYPROG) -p build/$(V:.v=.$(BOARD).bin)
endif

.PHONY: sim
sim: check-target build/$(V:.v=.vcd)
	$(GTKWAVE) build/$(V:.v=.vcd)

.PHONY: run
run: check-target build/$(V:.v=.out)
	cd build && ./$(V:.v=.out)

.PHONY: time
time: check-target build/$(V:.v=.$(BOARD).asc)
	$(ICETIME) -d $(DEVICE) build/$(V:.v=.$(BOARD).asc)

.PHONY: check-target
check-target:
ifeq ($(V),)
	@echo "Define target name first, e.g.: make run V=myfile.v"
	@echo
	@exit 1
endif

.PHONY: clean
clean:
	rm -f build/*

include $(wildcard build/*.d)
