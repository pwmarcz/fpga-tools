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
