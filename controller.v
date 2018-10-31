`include "memory.v"

`define COMMAND_READ 1
`define COMMAND_WRITE 2

module controller(input wire       clk,
                  input wire       received,
                  input wire [7:0] rx_byte,
                  input wire       is_transmitting,
                  output reg       transmit,
                  output reg [7:0] tx_byte);

  reg         read;
  reg         write;
  reg [7:0]   command_bytes[0:3];
  reg [1:0]   command_idx;

  wire [1:0]  command = command_bytes[0][1:0];
  reg [15:0]  addr;
  reg [7:0]   count;

  reg [7:0]   write_byte;
  wire [7:0]  read_byte;

  memory mem(clk, read, write, addr, write_byte, read_byte);

  localparam [3:0]
    STATE_IDLE = 0,
    STATE_RX_COMMAND = 1,
    STATE_READ_WAIT = 2,
    STATE_READ = 3,
    STATE_READ_ADVANCE = 4,
    STATE_WRITE_RX_DATA = 5,
    STATE_WRITE_ADVANCE = 6;

  reg [2:0] state = STATE_IDLE;

  always @(posedge clk)
    begin
      read <= 0;
      write <= 0;
      transmit <= 0;

      case (state)
        STATE_IDLE: begin
          if (received) begin
            command_idx <= 1;
            command_bytes[0] <= rx_byte;
            state = STATE_RX_COMMAND;
          end
        end

        STATE_RX_COMMAND: begin
          if (received) begin
            command_bytes[command_idx] = rx_byte;

            if (command_idx < 3) begin
              command_idx <= command_idx + 1;
            end else begin
              addr <= {command_bytes[2], command_bytes[3]};
              count <= command_bytes[1];
              case (command)
                `COMMAND_READ: begin
                  state <= STATE_READ_WAIT;
                end
                `COMMAND_WRITE: begin
                  state <= STATE_WRITE_RX_DATA;
                end
              endcase
            end // else: !if(command_idx < 3)
          end
        end

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
