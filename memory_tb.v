`include "uart_memory.v"

module Top;
  reg read, write;
  reg [7:0] addr;
  wire [7:0] read_byte;
  reg [7:0] write_byte;
  reg clock;

  memory m(clock, read, write, addr, write_byte, read_byte);

  initial
    $monitor($time, " clock = %b read = %b write = %b addr = %b read_byte = %b write_byte = %b",
             clock, read, write, addr, read_byte, write_byte);

  initial
    begin
      $dumpfile("memory_tb.vcd");
      $dumpvars;
    end

  initial
    begin
      clock = 1;
      forever #2 clock = ~clock;
    end


  initial
    begin
      #25 $finish;
    end

  initial
    begin
      read = 0; write = 0;
      #5 read = 0; write = 1; addr = 'b1010; write_byte = 'b111;
      #5 read = 1; write = 0; addr = 'b1010;
      #5 read = 0; write = 1; addr = 'b1011; write_byte = 'b110;
      #5 read = 1; write = 0; addr = 'b1011;
    end

endmodule // Top
