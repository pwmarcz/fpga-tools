.PHONY: all
all: flash-uart_hello

display_hello.blif: font.mem text.mem

text.mem: text.txt
	hexdump -v -e '/1 "%02X "' $< > $@

.PRECIOUS: %.bin %.vcd %.d

%.d: %.v make-deps
	./make-deps $(@:.d=.blif) $< > $@
	./make-deps $(@:.d=.out) $< >> $@

%.blif: %.v %.d
	yosys -q -p "synth_ice40 -blif $@" $<

%.asc: icestick.pcf %.blif
	arachne-pnr -p icestick.pcf $*.blif -o $@

%.bin: %.asc
	icepack $*.asc $@

%.vcd: %.out
	./$<

%.out: %.v %.d
	iverilog $< -o $@

.PHONY: flash-%
flash-%: %.bin
	iceprog $<

.PHONY: sim-%
sim-%: %.vcd
	gtkwave $<

.PHONY: run-%
run-%: %.out
	./$<

.PHONY: clean
clean:
	rm -f *.bin *.blif *.asc *.out *.d

include $(wildcard *.d)
