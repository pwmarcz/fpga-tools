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
flash: $(V:.v=.bin)
	$(ICEPROG) $<

.PHONY: sim
sim: $(V:.v=.vcd)
	$(GTKWAVE) $<

.PHONY: run
run: $(V:.v=.out)
	./$<

.PHONY: clean
clean:
	rm -f *.bin *.blif *.asc *.out *.d *.vcd

include $(wildcard *.d)
