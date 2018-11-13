# fpga-uart-experiments

This is a bunch of experiments trying to teach myself FPGA programming.

I'm using [iCEstick](https://www.latticesemi.com/icestick) by Lattice Semiconductor.

## Prerequisites

I'm using Ubuntu with the following installed:

- `yosys` - logic sythesis of Verilog
- `arachne-pnr` - placement and routing
- `fpga-icestorm` - transferring the design to the FPGA
- `iverilog` - for simulating circuit on my computer
- `gtkwave` - viewing the simulation results
- `gtkterm` - a serial terminal
- Python 3 and `pyserial` - serial line communication

Make sure you're in the `dialout` group to be able to access serial ports.

## Targets

### Simulation

To run a Verilog program and display results in console, run `make run V=source.v`:
- `make run V=memory_tb.v`
- `make run V=controller_tb.v`

To additionally view the results in GTKWave, use `make sim V=source.v`:
- `make sim-memory_tb`
- `make sim-controller_tb`

### Flashing

To flash the design to FPGA, use `make flash V=source.v`:
- `make flash V=uart_memory`
- `make flash V=uart_controller`

## Files

### `uart_hello` demo

- `uart_hello.v` - sends "Hello, world" continuously over serial line

This just sends character in a loop. You can view the result in `gtkterm`, by
opening the `/dev/ttyUSB1` device.

### `uart_memory` demo

- `uart_memory.v` - a memory module accessible over serial line
    - `memory_tb.v` - a test-bench for memory
    - `controller_tb.v` - a test-bench for memory controller
    - `test_memory.py` - a program for testing the memory on FPGA

This is a memory module. It handles the following commands:

- `0x01 <n> <addr_hi> <addr_lo>` - read `n+1` bytes at location `{addr_hi, addr_lo}`

- `0x02 <n> <addr_hi> <addr_lo> (...n+1 bytesof data)` - write `n+1` bytes at
  location `{addr_hi, addr_lo}`

The `test_memory.py` program verifies the memory operation.

For some reason, baud rates over 19200 cause the program to fail (?)

## UART (serial) communication

For serial communication, I'm using a module by Tim Goddard, copied here as (`uart.v`):

- [osdvu](https://opencores.org/project/osdvu) - the module page on opencores.org
- [iCEstick-UART-Demo](https://github.com/cyrozap/iCEstick-UART-Demo) - example usage

## Resources

- https://wiki.debian.org/FPGA/Lattice - describes open source toolchain for iCEstick
- [open-fpga-verilog-tutorial](https://github.com/Obijuan/open-fpga-verilog-tutorial/wiki/Chapter-0%3A-you-are-leaving-the-private-sector) - an excellent tutorial series, translated from Spanish
- *Verilog HDL* by Samir Palnitkar
- [ice40-examples](https://github.com/nesl/ice40_examples) repo

## License

You're free to use all of the code under MIT license. See `LICENSE` for
details.

Note that `uart.v` does not belong to me, as mentioned above.
