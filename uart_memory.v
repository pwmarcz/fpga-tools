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

  assign read_byte = read ? mem[addr] : 0;

  always @(posedge clk) begin
    if (write) begin
      $display("Storing %H at %H", write_byte, addr);
      mem[addr] <= write_byte;
    end
  end // always @ (posedge clk)
endmodule // memory


module memory_controller(input wire       clk,
                         input wire       received,
                         input wire [7:0] rx_byte,
                         output reg       transmit,
                         output reg [7:0] tx_byte);

  reg        read;
  reg        write;
  reg [1:0]  command;
  reg [7:0]  addr;
  reg [7:0]  write_byte;
  wire [7:0] read_byte;

  memory mem(clk, read, write, addr, write_byte, read_byte);

  localparam [2:0]
    STATE_IDLE = 0,
    STATE_RX_ADDR = 1,
    STATE_READ = 2,
    STATE_WRITE_RX_DATA = 3;

  reg [2:0] state = STATE_IDLE;

  always @(posedge clk)
    begin
      read <= 0;
      write <= 0;
      transmit <= 0;

      case (state)
        STATE_IDLE: begin
          if (received) begin
            case (rx_byte)
              `COMMAND_READ, `COMMAND_WRITE: begin
                command <= rx_byte;
                state <= STATE_RX_ADDR;
              end
            endcase
          end
        end

        STATE_RX_ADDR: begin
          if (received) begin
            addr <= rx_byte;
            command <= 0;
            case (command)
              `COMMAND_READ: begin
                state <= STATE_READ;
                read <= 1;
              end
              `COMMAND_WRITE: begin
                state <= STATE_WRITE_RX_DATA;
              end
            endcase
          end
        end // case: STATE_RX_ADDR

        STATE_READ: begin
          state <= STATE_IDLE;
          transmit <= 1;
          tx_byte <= read_byte;
        end

        STATE_WRITE_RX_DATA: begin
          if (received) begin
            state <= STATE_IDLE;
            write <= 1;
            write_byte <= rx_byte;
          end
        end
      endcase // case (state)
    end
endmodule // memory_controller

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

  uart #(.baud_rate(9600), .sys_clk_freq(12000000))
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

  memory_controller mc(.clk(iCE_CLK),
                       .received(received),
                       .rx_byte(rx_byte),
                       .transmit(transmit),
                       .tx_byte(tx_byte)
                       );

  reg [3:0]  count_received = 0;
  always @(posedge iCE_CLK)
    begin
      if (received)
        count_received <= count_received + 1;
    end

  assign LED0 = is_receiving;
  assign LED1 = count_received[0];
  assign LED2 = count_received[1];
  assign LED3 = count_received[2];
  assign LED4 = count_received[3];

endmodule // uart_memory
