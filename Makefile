YOSYS ?= yosys
PNR ?= arachne-pnr
ICEPACK ?= icepack
ICEPROG ?= iceprog
IVERILOG ?= iverilog
GTKWAVE ?= gtkwave

MAKEDEPS = ./make-deps

.PHONY: all
all:

build/display_hello.blif: font.mem text.mem

text.mem: text.txt
	hexdump -v -e '/1 "%02X "' $< > $@

.PRECIOUS: build/%.d build/%.blif build/%.bin %.d

build/%.d: %.v $(MAKEDEPS)
	$(MAKEDEPS) $(@:.d=.blif) $< > $@
	$(MAKEDEPS) $(@:.d=.out) $< >> $@

build/%.blif: %.v build/%.d
	$(YOSYS) -q -p "synth_ice40 -blif $@" $<

build/%.asc: build/%.blif icestick.pcf
	$(PNR) -p icestick.pcf $< -o $@

build/%.bin: build/%.asc
	$(ICEPACK) $< $@

build/%.vcd: build/%.out
	cd build && ./$<

build/%.out: %.v build/%.d
	$(IVERILOG) $< -o $@

.PHONY: flash
flash: check-target build/$(V:.v=.bin)
	$(ICEPROG) build/$(V:.v=.bin)

.PHONY: sim
sim: check-target build/$(V:.v=.vcd)
	$(GTKWAVE) build/$(V:.v=.vcd)

.PHONY: run
run: check-target build/$(V:.v=.out)
	cd build && ./$(V:.v=.out)

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
