// GPU module for CHIP-8. Draws an 8-bit-wide sprite on the 64 x 32 screen.

module gpu(input wire        clk,
           input wire        draw, // begin drawing
           input wire [15:0] addr, // sprite address
           input wire [3:0]  lines, // number of lines
           input wire [7:0]  x, // X coordinate
           input wire [7:0]  y, // Y coordinate

           output wire       ready,
           output reg        collision,

           // Memory interface
           output reg        mem_read,
           output reg        mem_write,
           output reg [15:0] mem_addr,
           output reg [7:0]  mem_write_byte,
           input wire [7:0]  mem_read_byte);

  parameter screen_start = 'h100;

  localparam
    STATE_IDLE = 0,
    STATE_LOAD_SPRITE = 1,
    STATE_LOAD_LEFT = 2,
    STATE_STORE_LEFT = 3,
    STATE_LOAD_RIGHT = 4,
    STATE_STORE_RIGHT = 5;

  reg [2:0] state = STATE_IDLE;
  assign ready = (state == STATE_IDLE);

  reg [3:0]  count;
  reg [15:0] sprite_addr;
  reg [15:0] screen_addr;
  reg [2:0]  shift;
  reg        erase_right;
  reg [7:0]  left;
  reg [7:0]  right;

  always @(posedge clk)
    begin
      mem_read <= 0;
      mem_write <= 0;
      mem_addr <= 0;
      mem_write_byte <= 0;

      case (state)
        STATE_IDLE: begin
          if (draw) begin
            $display($time, " gpu: draw x %h y %h lines %h addr %h",
                     x, y, lines, addr);
            collision <= 0;
            if (x < 64 && y < 32 && lines > 0) begin
              count <= lines;
              screen_addr <= screen_start + y * 8 + x / 8;
              shift <= x % 8;
              erase_right <= x >= 56;

              sprite_addr <= addr;
              mem_addr <= addr;
              mem_read <= 1;
              state <= STATE_LOAD_SPRITE;
            end
          end
        end // case: STATE_IDLE

        STATE_LOAD_SPRITE: begin
          if (!mem_read) begin
            left <= mem_read_byte >> shift;
            right <= erase_right ? 0 : mem_read_byte << (8 - shift);
            mem_addr <= screen_addr;
            mem_read <= 1;
            state <= STATE_LOAD_LEFT;
          end
        end

        STATE_LOAD_LEFT: begin
          if (!mem_read) begin
            mem_write <= 1;
            collision <= collision | |(mem_read_byte & left);
            mem_write_byte <= mem_read_byte ^ left;
            state <= STATE_STORE_LEFT;
          end
        end

        STATE_STORE_LEFT: begin
          mem_read <= 1;
          mem_addr <= screen_addr + 1;
          screen_addr <= screen_addr + 1;
          state <= STATE_LOAD_RIGHT;
        end

        STATE_LOAD_RIGHT: begin
          if (!mem_read) begin
            mem_write <= 1;
            collision <= collision | |(mem_read_byte & right);
            mem_write_byte <= mem_read_byte ^ right;
            state <= STATE_STORE_RIGHT;
          end
        end

        STATE_STORE_RIGHT: begin
          if (count > 1) begin
            count <= count - 1;
            screen_addr <= screen_addr + 63;
            mem_addr <= sprite_addr + 1;
            sprite_addr <= sprite_addr + 1;
            mem_read <= 1;
            state <= STATE_LOAD_SPRITE;
          end else begin
            state <= STATE_IDLE;
          end;
        end
      endcase // case (state)
    end

endmodule // gpu
