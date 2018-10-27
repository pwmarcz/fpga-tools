.PHONY: all
all: flash-uart_hello

.PRECIOUS: %.bin %.vcd

%.blif: %.v
	yosys -q -p "synth_ice40 -blif $@" $<

%.txt: icestick.pcf %.blif
	arachne-pnr -p icestick.pcf $*.blif -o $@

%.bin: %.txt
	icepack $*.txt $@

%.vcd: %.out
	./$<

%.out: %.v
	iverilog $< -o $@

.PHONY: prog-%
flash-%: %.bin
	iceprog $<

.PHONY: sim-%
sim-%: %.vcd
	gtkwave $<

.PHONY: clean
clean:
	rm *.bin *.blif *.txt
