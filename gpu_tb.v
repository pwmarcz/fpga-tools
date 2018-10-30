`include "memory.v"
`include "gpu.v"

module Top;
  reg clk;
  reg draw = 0;
  reg [15:0] addr;
  reg [3:0] lines;
  reg [7:0] x;
  reg [7:0] y;
  wire      collision;
  wire      ready;

  memory #(.initialize(1)) mem(.clk(clk));

  gpu g(.clk(clk),
        .draw(draw),
        .lines(lines),
        .addr(addr),
        .x(x),
        .y(y),
        .ready(ready),
        .collision(collision),
        .mem_read(mem.read),
        .mem_write(mem.write),
        .mem_addr(mem.addr),
        .mem_write_byte(mem.write_byte),
        .mem_read_byte(mem.read_byte));

  initial
    begin
      clk = 0;
      forever #1 clk = ~clk;
    end

  initial
    begin
      $dumpfile("controller_tb.vcd");
      $dumpvars;
    end
  initial
    begin
      force mem.write = 1; force mem.addr = 2; force mem.write_byte = 8'b10101010; #2;
      force mem.write = 1; force mem.addr = 3; force mem.write_byte = 8'b01010101; #2;
      release mem.write; release mem.addr; release mem.write_byte;

      draw = 1; addr = 2; lines = 2; x = 4; y = 1; #2; draw = 0;
      @(posedge ready);
      $display(collision);

      #2;

      draw = 1; addr = 2; lines = 2; x = 2; y = 1; #2; draw = 0;
      @(posedge ready);
      $display(collision);

      $finish;
    end
endmodule // Top
