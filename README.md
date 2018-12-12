# FPGA tools

This is some shared code for building FPGA projects using the Icestorm
toolchain.

## Prerequisites

- `yosys` - logic sythesis of Verilog
- `arachne-pnr` - placement and routing
- `fpga-icestorm` - transferring the design to the FPGA
- `iverilog` - simulation and running test benches
- `gtkwave` - viewing the simulation results
- `tinyprog` - for TinyFPGA BX

The build system uses GNU make, bash and sed.

## Build system

Just include the following in your Makefile:

    include .../fpga.mk

The Makefile supports the following variables:

- `BOARD=board`, - select board to build for (supported: `icestick`, `bx`)
- `V=source.v` - use `source.v` as main file
- `TOP=topmod` - use `topmod` as top-level module for synthesis
- `VERBOSE=1` - don't suppress output
- `USE_SUDO=1` - use `sudo` when uploading the project

There are following targets:

- `make blif V=...`, `make bin V=...` - synthesize / place and route a project
- `make flash V=...` - upload your project to the board
- `make run V=...` - run in Icarus Verilog
- `make sim V=...` - run and open `.vcd` file in GTKWave
- `make test` - run all `*_tb.v` files

## Components

The `components` directory contains some useful Verilog modules:

### `oled.v`

Support for WaveShare monochrome and color displays (include with `.color(1)` or
`.color(0)` parameter).

### `uart.v`

This is a module for UART communication by Tim Goddard, copied here:

- [osdvu](https://opencores.org/project/osdvu) - the module page on opencores.org
- [iCEstick-UART-Demo](https://github.com/cyrozap/iCEstick-UART-Demo) - example usage

## License

You're free to use all of the code under MIT license. See `LICENSE` for
details.

Note that `uart.v` does not belong to me, as mentioned above.
