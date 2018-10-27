`include "uart.v"

// Read test fails for higher baud rates (???)
`define BAUD_RATE 19200

`define COMMAND_READ 1
`define COMMAND_WRITE 2

module memory(input wire        clk,
              input wire        read,
              input wire        write,
              input wire [15:0]  addr,
              input wire [7:0]  write_byte,
              output wire [7:0] read_byte);

  parameter size = 'h1000;

  reg [7:0] mem[0:size-1];

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
                         input wire       is_transmitting,
                         output reg       transmit,
                         output reg [7:0] tx_byte);

  reg         read;
  reg         write;
  reg [1:0]   command;
  reg [15:0]  addr;
  reg [7:0]   count;
  reg [7:0]   write_byte;
  wire [7:0]  read_byte;

  memory mem(clk, read, write, addr, write_byte, read_byte);

  localparam [4:0]
    STATE_IDLE = 0,
    STATE_RX_COUNT = 1,
    STATE_RX_ADDR_HI = 2,
    STATE_RX_ADDR_LO = 3,
    STATE_READ_WAIT = 4,
    STATE_READ = 5,
    STATE_READ_ADVANCE = 6,
    STATE_WRITE_RX_DATA = 7,
    STATE_WRITE_ADVANCE = 8;

  reg [4:0] state = STATE_IDLE;

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
                state <= STATE_RX_COUNT;
              end
            endcase
          end
        end

        STATE_RX_COUNT: begin
          if (received) begin
            count <= rx_byte;
            state <= STATE_RX_ADDR_HI;
          end
        end

        STATE_RX_ADDR_HI: begin
          if (received) begin
            addr[15:8] <= rx_byte;
            state <= STATE_RX_ADDR_LO;
          end
        end

        STATE_RX_ADDR_LO: begin
          if (received) begin
            addr[7:0] <= rx_byte;
            command <= 0;
            case (command)
              `COMMAND_READ: begin
                state <= STATE_READ_WAIT;
              end
              `COMMAND_WRITE: begin
                state <= STATE_WRITE_RX_DATA;
              end
            endcase
          end
        end // case: STATE_RX_ADDR

        STATE_READ_WAIT: begin
          if (!is_transmitting) begin
            read <= 1;
            state <= STATE_READ;
          end
        end

        STATE_READ: begin
          transmit <= 1;
          tx_byte <= read_byte;
          state <= (count == 0 ? STATE_IDLE : STATE_READ_ADVANCE);
        end

        STATE_WRITE_RX_DATA: begin
          if (received) begin
            write <= 1;
            write_byte <= rx_byte;
            state <= (count == 0 ? STATE_IDLE : STATE_WRITE_ADVANCE);
          end
        end // case: STATE_WRITE_RX_DATA_ADVANCE

        STATE_READ_ADVANCE: begin
          addr <= addr + 1;
          count <= count - 1;
          state <= STATE_READ_WAIT;
        end

        STATE_WRITE_ADVANCE: begin
          addr <= addr + 1;
          count <= count - 1;
          state <= STATE_WRITE_RX_DATA;
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

  memory_controller mc(.clk(iCE_CLK),
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
