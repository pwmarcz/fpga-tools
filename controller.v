`include "memory.v"
`include "gpu.v"

// 1, count-1, addr_hi, addr_lo
`define COMMAND_READ 1

// 2, count-1, addr_hi, addr_lo, {count bytes}
`define COMMAND_WRITE 2

// {4'lines, 4'3}, {4'x, 4'y}, addr_hi, addr_lo
`define COMMAND_DRAW 3

module controller(input wire       clk,
                  input wire       received,
                  input wire [7:0] rx_byte,
                  input wire       is_transmitting,
                  output reg       transmit,
                  output reg [7:0] tx_byte);

  localparam [3:0]
    STATE_IDLE = 0,
    STATE_RX_COMMAND = 1,
    STATE_READ_WAIT = 2,
    STATE_READ = 3,
    STATE_READ_ADVANCE = 4,
    STATE_WRITE_RX_DATA = 5,
    STATE_WRITE_ADVANCE = 6,
    STATE_DRAW = 7;

  reg [2:0] state = STATE_IDLE;
  reg [7:0]   command_bytes[0:3];
  reg [2:0]   command_idx;

  wire [1:0]  command = command_bytes[0][2:0];
  reg [15:0]  addr;
  reg [7:0]   count;

  reg         gpu_draw;
  reg [15:0]  gpu_addr;
  reg [3:0]   gpu_lines;
  reg [7:0]   gpu_x;
  reg [7:0]   gpu_y;
  wire        gpu_ready;
  wire [7:0]  read_byte;

  wire        gpu_mem_read;
  wire        gpu_mem_write;
  wire [15:0] gpu_mem_addr;
  wire [7:0]  gpu_mem_write_byte;

  gpu gpu(.clk(clk),
          .draw(gpu_draw),
          .addr(gpu_addr),
          .lines(gpu_lines),
          .x(gpu_x),
          .y(gpu_y),
          .ready(gpu_ready),
          .mem_read(gpu_mem_read),
          .mem_write(gpu_mem_write),
          .mem_addr(gpu_mem_addr),
          .mem_write_byte(gpu_mem_write_byte),
          .mem_read_byte(read_byte));

  reg         read;
  reg         write;
  reg [7:0]   write_byte;

  memory mem(.clk(clk),
             .read(gpu_mem_read | read),
             .write(gpu_mem_write | write),
             .addr(gpu_mem_addr | addr),
             .write_byte(gpu_mem_write_byte | write_byte),
             .read_byte(read_byte));

  always @(posedge clk)
    begin
      read <= 0;
      write <= 0;
      transmit <= 0;
      gpu_draw <= 0;

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
              $display($time, " controller: command %h %h %h %h",
                       command_bytes[0], command_bytes[1], command_bytes[2], command_bytes[3]);
              case (command)
                `COMMAND_READ: begin
                  addr <= {command_bytes[2], command_bytes[3]};
                  count <= command_bytes[1];
                  state <= STATE_READ_WAIT;
                end
                `COMMAND_WRITE: begin
                  addr <= {command_bytes[2], command_bytes[3]};
                  count <= command_bytes[1];
                  state <= STATE_WRITE_RX_DATA;
                end
                `COMMAND_DRAW: begin
                  addr <= 0;
                  gpu_addr <= {command_bytes[2], command_bytes[3]};
                  gpu_x <= command_bytes[1][7:4];
                  gpu_y <= command_bytes[1][3:0];
                  gpu_lines <= command_bytes[0][7:4];
                  gpu_draw <= 1;
                  state <= STATE_DRAW;
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
          if (!read) begin
            transmit <= 1;
            tx_byte <= read_byte;
            state <= (count == 0 ? STATE_IDLE : STATE_READ_ADVANCE);
          end
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

        STATE_DRAW: begin
          if (!gpu_draw && gpu_ready) begin
            state <= STATE_IDLE;
          end
        end
      endcase // case (state)
    end
endmodule // memory_controller
