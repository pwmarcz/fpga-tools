`include "memory_controller.v"

module Top;
  reg clock;
  reg received = 0;
  reg [7:0] rx_byte;
  reg is_transmitting = 0;

  wire transmit;
  wire [7:0] tx_byte;

  memory_controller mc(clock, received, rx_byte, is_transmitting, transmit, tx_byte);

  initial
    begin
      $dumpfile("controller_tb.vcd");
      $dumpvars;
    end

  initial
    begin
      clock = 0;
      forever #1 clock = ~clock;
    end

  task recv_byte;
    input [7:0] b;
    begin
      #2 received = 1; rx_byte = b;
      #2 received = 0;
    end
  endtask // recv_byte

  always @(posedge clock)
    begin
      if (received)
        $display($time, " uart: recv %H", rx_byte);
      if (transmit)
        $display($time, " uart: send %H", tx_byte);
    end

  initial
    begin
      received = 0;

      recv_byte(`COMMAND_WRITE);
      recv_byte(2);
      recv_byte('h0E);
      recv_byte('hCD);
      recv_byte('h42);
      recv_byte('h43);
      recv_byte('h44);

      recv_byte(`COMMAND_WRITE);
      recv_byte(2);
      recv_byte('h0A);
      recv_byte('h10);
      recv_byte('h44);
      recv_byte('h45);
      recv_byte('h46);

      #2 recv_byte(`COMMAND_READ);
      recv_byte(2);
      recv_byte('h0E);
      recv_byte('hCD);

      #15 recv_byte(`COMMAND_READ);
      recv_byte(2);
      recv_byte('h0A);
      recv_byte('h10);

      #5 is_transmitting = 1;
      #5 is_transmitting = 0;

      #15 $finish;

    end

endmodule // Top
