`include "uart.v"
`include "controller.v"

// Read test fails for higher baud rates (???)
`define BAUD_RATE 19200

module uart_memory(input wire  iCE_CLK,
                   input wire  RS232_Rx_TTL,
                   output wire RS232_Tx_TTL,
                   output wire LED0,
	           output wire LED1,
	           output wire LED2,
	           output wire LED3,
                   output wire LED4);

  wire       reset = 0;
  wire       transmit;
  wire [7:0] tx_byte;
  wire       received;
  wire [7:0] rx_byte;
  wire       is_receiving;
  wire       is_transmitting;
  wire       recv_error;

  uart #(.baud_rate(`BAUD_RATE), .sys_clk_freq(12000000))
  uart0(.clk(iCE_CLK),                    // The master clock for this module
        .rst(reset),                      // Synchronous reset
        .rx(RS232_Rx_TTL),                // Incoming serial line
        .tx(RS232_Tx_TTL),                // Outgoing serial line
        .transmit(transmit),              // Signal to transmit
        .tx_byte(tx_byte),                // Byte to transmit
        .received(received),              // Indicated that a byte has been received
        .rx_byte(rx_byte),                // Byte received
        .is_receiving(is_receiving),      // Low when receive line is idle
        .is_transmitting(is_transmitting),// Low when transmit line is idle
        .recv_error(recv_error)           // Indicates error in receiving packet.
        );

  controller mc(.clk(iCE_CLK),
                .received(received),
                .rx_byte(rx_byte),
                .is_transmitting(is_transmitting),
                .transmit(transmit),
                .tx_byte(tx_byte)
                );

  reg [3:0]  count_received = 0;
  always @(posedge iCE_CLK)
    begin
      if (received)
        count_received <= count_received + 1;
    end

  assign LED0 = is_transmitting;
  assign LED1 = count_received[0];
  assign LED2 = count_received[1];
  assign LED3 = count_received[2];
  assign LED4 = count_received[3];

endmodule // uart_memory
