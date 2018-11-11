`include "display_commands.v"

`define CMD_NONE          2'b00
`define CMD_RESET         2'b01
`define CMD_SEND_COMMAND  2'b10
`define CMD_SEND_DATA     2'b11

module display_spi(input wire clk,
                   input wire [2:0] dspi_cmd,
                   input wire [7:0] dspi_byte,

                   output wire      dspi_ready,
                   output reg       spi_din,
                   output wire      spi_clk,
                   output reg       spi_cs,
                   output reg       spi_dc,
                   output reg       spi_rst);
  assign spi_clk = clk;

  reg [7:0] data;
  reg [3:0] data_counter = 0;

  reg reset = 0;
  reg send = 0;
  assign dspi_ready = !reset && !send && dspi_cmd == `CMD_NONE;

  initial begin
    spi_rst = 0;
    spi_cs = 1;
  end

  always @(posedge clk) begin
    if (!reset && !send) begin
      case (dspi_cmd)
        `CMD_RESET: begin
          reset <= 1;
          spi_rst <= 0;
        end
        `CMD_SEND_COMMAND, `CMD_SEND_DATA: begin
          send <= 1;
          spi_dc <= (dspi_cmd == `CMD_SEND_DATA);
          data <= dspi_byte;
          data_counter <= 8;
        end
      endcase
    end // if (!reset && !send)

    if (reset) begin
      spi_rst <= 1;
      if (spi_rst == 1) begin
        reset <= 0;
      end
    end

    if (send) begin
      if (data_counter > 0) begin
        spi_cs <= 0;
        spi_din <= data[7];
        data <= data << 1;
        data_counter <= data_counter - 1;
      end else begin
        spi_cs <= 1;
        send <= 0;
      end
    end
  end
endmodule // display_spi

module display(input wire clk,
               input wire       dspi_ready,
               output reg [2:0] dspi_cmd,
               output reg [7:0] dspi_byte,
               output reg       d_read,
               output reg [2:0] d_page_idx,
               output reg [6:0] d_column_idx,
               input wire [7:0] d_data,
               input wire       d_data_ready);

  localparam N_INIT_COMMANDS = 25;
  localparam N_REFRESH_COMMANDS = 6;

  localparam
    STATE_RESET = 0,
    STATE_INIT = 1,
    STATE_IDLE = 2,
    STATE_REFRESH_BEGIN = 3,
    STATE_REFRESH_DATA = 4,
    STATE_ADVANCE = 5;

  reg [7:0] commands[0:N_INIT_COMMANDS+N_REFRESH_COMMANDS-1];
  reg [8:0] command_idx = 0;
  reg [7:0] command;
  reg       send_command = 0;

  reg [3:0] state = STATE_RESET;

  integer i;

  initial begin
    dspi_cmd = `CMD_RESET;

    i = -1;

    // Init commands
    i++; commands[i] <= `SSD1306_DISPLAYOFF;
    i++; commands[i] <= `SSD1306_SETDISPLAYCLOCKDIV;
    i++; commands[i] <= 'h80;
    i++; commands[i] <= `SSD1306_SETMULTIPLEX;
    i++; commands[i] <= 'h3F;
    i++; commands[i] <= `SSD1306_SETDISPLAYOFFSET;
    i++; commands[i] <= 'h00;
    i++; commands[i] <= `SSD1306_SETSTARTLINE | 'h00;
    i++; commands[i] <= `SSD1306_CHARGEPUMP;
    i++; commands[i] <= 'h14;
    i++; commands[i] <= `SSD1306_MEMORYMODE;
    i++; commands[i] <= 'h00;
    i++; commands[i] <= `SSD1306_SEGREMAP | 'h01;
    i++; commands[i] <= `SSD1306_COMSCANDEC;
    i++; commands[i] <= `SSD1306_SETCOMPINS;
    i++; commands[i] <= 'h12;
    i++; commands[i] <= `SSD1306_SETCONTRAST;
    i++; commands[i] <= 'h70;
    i++; commands[i] <= `SSD1306_SETPRECHARGE;
    i++; commands[i] <= 'hF1;
    i++; commands[i] <= `SSD1306_SETVCOMDETECT;
    i++; commands[i] <= 'h40;
    i++; commands[i] <= `SSD1306_DISPLAYALLON_RESUME;
    i++; commands[i] <= `SSD1306_NORMALDISPLAY;
    i++; commands[i] <= `SSD1306_DISPLAYON;

    // Refresh commands
    i++; commands[i] <= `SSD1306_COLUMNADDR;
    i++; commands[i] <= 0;
    i++; commands[i] <= 127;
    i++; commands[i] <= `SSD1306_PAGEADDR;
    i++; commands[i] <= 0;
    i++; commands[i] <= 7;
  end

  always @(posedge clk) begin
    command <= commands[command_idx];
    if (send_command) begin
      send_command <= 0;
      dspi_cmd <= `CMD_SEND_COMMAND;
      dspi_byte <= command;
    end else begin
      dspi_cmd <= `CMD_NONE;
      case (state)
        STATE_RESET: begin
          if (dspi_ready) begin
            dspi_cmd <= `CMD_RESET;
            state <= STATE_INIT;
            command_idx <= 0;
          end
        end
        STATE_INIT: begin
          if (dspi_ready) begin
            send_command <= 1;

            command_idx <= command_idx + 1;
            if (command_idx+1 == N_INIT_COMMANDS) begin
              state <= STATE_REFRESH_BEGIN;
            end
          end
        end
        STATE_REFRESH_BEGIN: begin
          if (dspi_ready) begin
            if (command_idx < N_INIT_COMMANDS + N_REFRESH_COMMANDS) begin
              send_command <= 1;
              command_idx <= command_idx + 1;
            end else begin
              state <= STATE_REFRESH_DATA;
              d_page_idx <= 0;
              d_column_idx <= 0;
              d_read <= 1;
            end
          end
        end
        STATE_REFRESH_DATA: begin
          d_read <= 0;
          if (d_data_ready) begin
            dspi_cmd <= `CMD_SEND_DATA;
            dspi_byte <= d_data;
            state <= STATE_ADVANCE;
          end
        end
        STATE_ADVANCE: begin
          if (dspi_ready) begin
            d_read <= 1;
            state <= STATE_REFRESH_DATA;
            d_column_idx <= d_column_idx + 1;
            if (d_column_idx == 127) begin
              d_page_idx <= d_page_idx + 1;
              if (d_page_idx == 7) begin
                d_read <= 0;
                state <= STATE_REFRESH_BEGIN;
                command_idx <= N_INIT_COMMANDS;
              end
            end
          end // if (dspi_ready)
        end
      endcase // case (state)
    end
  end
endmodule // display
