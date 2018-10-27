`include "uart_memory.v"

module Top;
  reg clock;
  reg received = 0;
  reg [7:0] rx_byte;

  wire transmit;
  wire [7:0] tx_byte;

  memory_controller mc(clock, received, rx_byte, transmit, tx_byte);

  initial
    begin
      $monitor($time,
               " clock = %d, received = %H, rx_byte = %H, transmit = %H, tx_byte = %H",
               clock, received, rx_byte, transmit, tx_byte);

      $dumpfile("controller_tb.vcd");
      $dumpvars;
    end

  initial
    begin
      clock = 0;
      forever #1 clock = ~clock;
    end


  initial
    begin
      #55 $finish;
    end

  initial
    begin
      received = 0;

      #2 received = 1; rx_byte = `COMMAND_WRITE;
      #2 received = 0;
      #2 received = 1; rx_byte = 'hFE;
      #2 received = 0;
      #2 received = 1; rx_byte = 'h42;
      #2 received = 0;

      #2 received = 1; rx_byte = `COMMAND_WRITE;
      #2 received = 0;
      #2 received = 1; rx_byte = 'hAB;
      #2 received = 0;
      #2 received = 1; rx_byte = 'h44;
      #2 received = 0;

      #4 received = 1; rx_byte = `COMMAND_READ;
      #2 received = 0;
      #2 received = 1; rx_byte = 'hFE;
      #2 received = 0;

      #4 received = 1; rx_byte = `COMMAND_READ;
      #2 received = 0;
      #2 received = 1; rx_byte = 'hAB;
      #2 received = 0;

    end

endmodule // Top
