`include "uart.v"
`include "display.v"

`define BAUD_RATE 19200

module uart_display(input wire       clk,
                    input wire       d_read,
                    // input wire [2:0] d_page_idx,
                    // input wire [6:0] d_column_idx,
                    output reg [7:0] d_data,
                    output reg       d_data_ready,
                    input wire       uart_received,
                    input wire [7:0] uart_rx_byte);

  localparam DISPLAY_SIZE = 128*8;

  reg [7:0] data[0:DISPLAY_SIZE-1];
  reg [9:0] data_write_idx = 0;
  reg [9:0] data_read_idx = 0;

  always @(posedge clk) begin
    if (uart_received) begin
      data[data_write_idx] <= uart_rx_byte;
      data_write_idx <= (data_write_idx + 1) % DISPLAY_SIZE;
    end
    if (d_read) begin
      d_data <= data[data_read_idx];
      d_data_ready <= 1;
      data_read_idx <= (data_read_idx + 1) % DISPLAY_SIZE;
    end else begin
      d_data_ready <= 0;
    end
  end
endmodule

module display_demo(input wire  iCE_CLK,
                    input wire  RS232_Rx_TTL,
                    output wire PIO1_02,
                    output wire PIO1_03,
                    output wire PIO1_04,
                    output wire PIO1_05,
                    output wire PIO1_06);

  wire dspi_ready;
  wire [2:0] dspi_cmd;
  wire [7:0] dspi_byte;

  wire       d_read;
  // wire [2:0] d_page_idx;
  // wire [6:0] d_column_idx;
  wire [7:0] d_data;
  wire       d_data_ready;

  wire       uart_received;
  wire [7:0] uart_rx_byte;

  display_spi dspi(.clk(iCE_CLK),
                   .dspi_ready(dspi_ready),
                   .dspi_cmd(dspi_cmd),
                   .dspi_byte(dspi_byte),
                   .spi_din(PIO1_02),
                   .spi_clk(PIO1_03),
                   .spi_cs(PIO1_04),
                   .spi_dc(PIO1_05),
                   .spi_rst(PIO1_06));

  display d(.clk(iCE_CLK),
            .dspi_ready(dspi_ready),
            .dspi_cmd(dspi_cmd),
            .dspi_byte(dspi_byte),
            .d_read(d_read),
            // .d_page_idx(d_page_idx),
            // .d_column_idx(d_column_idx),
            .d_data(d_data),
            .d_data_ready(d_data_ready));

  uart #(.baud_rate(`BAUD_RATE), .sys_clk_freq(12000000))
  uart0(.clk(iCE_CLK),                    // The master clock for this module
        .rst(1'b0),                      // Synchronous reset
        .rx(RS232_Rx_TTL),                // Incoming serial line
        // .tx(RS232_Tx_TTL),                // Outgoing serial line
        .transmit(1'b0),              // Signal to transmit
        // .tx_byte(tx_byte),                // Byte to transmit
        .received(uart_received),              // Indicated that a byte has been received
        .rx_byte(uart_rx_byte)                // Byte received
        // .is_receiving(is_receiving),      // Low when receive line is idle
        // .is_transmitting(is_transmitting),// Low when transmit line is idle
        // .recv_error(recv_error)           // Indicates error in receiving packet.
        );

  uart_display ud(.clk(iCE_CLK),
                  .d_read(d_read),
                  .d_data(d_data),
                  .d_data_ready(d_data_ready),
                  .uart_received(uart_received),
                  .uart_rx_byte(uart_rx_byte));
endmodule
