`include "uart.v"

`define COMMAND_READ 1
`define COMMAND_WRITE 2

module memory(input wire        clk,
              input wire        read,
              input wire        write,
              input wire [7:0]  addr,
              input wire [7:0]  write_byte,
              output wire [7:0] read_byte);

  reg [7:0] mem[0:255];
  reg [7:0] rb;

  always @(posedge clk) begin
    if (read) begin
      rb <= mem[addr];
    end else begin
      rb <= 0;
    end

    if (write) begin
      mem[addr] <= write_byte;
    end
  end // always @ (posedge clk)

  assign read_byte = rb;
endmodule // memory
