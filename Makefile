YOSYS ?= yosys
PNR ?= arachne-pnr
ICEPACK ?= icepack
ICEPROG ?= iceprog
IVERILOG ?= iverilog
GTKWAVE ?= gtkwave

MAKEDEPS = ./make-deps

.PHONY: all
all:

display_hello.blif: font.mem text.mem

text.mem: text.txt
	hexdump -v -e '/1 "%02X "' $< > $@

.PRECIOUS: %.bin %.vcd %.d

%.d: %.v $(MAKEDEPS)
	$(MAKEDEPS) $(@:.d=.blif) $< > $@
	$(MAKEDEPS) $(@:.d=.out) $< >> $@

%.blif: %.v %.d
	$(YOSYS) -q -p "synth_ice40 -blif $@" $<

%.asc: icestick.pcf %.blif
	$(PNR) -p icestick.pcf $*.blif -o $@

%.bin: %.asc
	$(ICEPACK) $*.asc $@

%.vcd: %.out
	./$<

%.out: %.v %.d
	$(IVERILOG) $< -o $@

.PHONY: flash
flash: check-target $(V:.v=.bin)
	$(ICEPROG) $(V:.v=.bin)

.PHONY: sim
sim: check-target $(V:.v=.vcd)
	$(GTKWAVE) $(V:.v=.vcd)

.PHONY: run
run: check-target $(V:.v=.out)
	./$(V:.v=.out)

.PHONY: check-target
check-target:
ifeq ($(V),)
	@echo "Define target name first, e.g.: make run V=myfile.v"
	@echo
	@exit 1
endif

.PHONY: clean
clean:
	rm -f *.bin *.blif *.asc *.out *.d *.vcd

include $(wildcard *.d)
