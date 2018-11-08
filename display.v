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
                   output reg       spi_clk,
                   output reg       spi_cs,
                   output reg       spi_dc,
                   output reg       spi_rst);
  reg [4:0] divider;
  reg [7:0] data;
  reg [3:0] data_counter = 0;

  reg reset = 0;
  reg send = 0;
  assign dspi_ready = !reset && !send && dspi_cmd == `CMD_NONE;

  initial begin
    spi_clk = 0;
    spi_rst = 1;
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

    if (divider < 10) begin
      divider <= divider + 1;
    end else begin
      divider <= 0;
      spi_clk <= ~spi_clk;

      if (spi_clk) begin
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
    end
  end
endmodule // display_spi


module display(input wire clk,
               input wire dspi_ready,
               output reg [2:0] dspi_cmd,
               output reg [7:0] dspi_byte);

  localparam MAX_INIT_COMMAND = 24;
  localparam MAX_REFRESH_COMMAND = 5;
  localparam
    STATE_RESET = 0,
    STATE_INIT = 1,
    STATE_IDLE = 2,
    STATE_REFRESH_BEGIN = 3,
    STATE_REFRESH_DATA = 4;

  reg [7:0] init_commands[0:MAX_INIT_COMMAND];
  reg [7:0] refresh_commands[0:MAX_REFRESH_COMMAND];
  reg [8:0] command_idx = 0;
  reg [2:0] page_idx = 0; // 0..7
  reg [6:0] column_idx = 0; // 0..127

  reg [3:0] state = STATE_RESET;

  integer i;

  initial begin
    dspi_cmd = `CMD_RESET;

    i = -1;
    i++; init_commands[i] <= `SSD1306_DISPLAYOFF;
    i++; init_commands[i] <= `SSD1306_SETDISPLAYCLOCKDIV;
    i++; init_commands[i] <= 'h80;
    i++; init_commands[i] <= `SSD1306_SETMULTIPLEX;
    i++; init_commands[i] <= 'h3F;
    i++; init_commands[i] <= `SSD1306_SETDISPLAYOFFSET;
    i++; init_commands[i] <= 'h00;
    i++; init_commands[i] <= `SSD1306_SETSTARTLINE | 'h00;
    i++; init_commands[i] <= `SSD1306_CHARGEPUMP;
    i++; init_commands[i] <= 'h14;
    i++; init_commands[i] <= `SSD1306_MEMORYMODE;
    i++; init_commands[i] <= 'h00;
    i++; init_commands[i] <= `SSD1306_SEGREMAP | 'h01;
    i++; init_commands[i] <= `SSD1306_COMSCANDEC;
    i++; init_commands[i] <= `SSD1306_SETCOMPINS;
    i++; init_commands[i] <= 'h12;
    i++; init_commands[i] <= `SSD1306_SETCONTRAST;
    i++; init_commands[i] <= 'h70;
    i++; init_commands[i] <= `SSD1306_SETPRECHARGE;
    i++; init_commands[i] <= 'hF1;
    i++; init_commands[i] <= `SSD1306_SETVCOMDETECT;
    i++; init_commands[i] <= 'h40;
    i++; init_commands[i] <= `SSD1306_DISPLAYALLON_RESUME;
    i++; init_commands[i] <= `SSD1306_NORMALDISPLAY;
    i++; init_commands[i] <= `SSD1306_DISPLAYON;

    i = -1;
    i++; refresh_commands[i] <= `SSD1306_COLUMNADDR;
    i++; refresh_commands[i] <= 0;
    i++; refresh_commands[i] <= 127;
    i++; refresh_commands[i] <= `SSD1306_PAGEADDR;
    i++; refresh_commands[i] <= 0;
    i++; refresh_commands[i] <= 7;
  end

  always @(posedge clk) begin
    dspi_cmd <= `CMD_NONE;
    if (dspi_ready) begin
      case (state)
        STATE_RESET: begin
          state <= STATE_INIT;
        end
        STATE_INIT: begin
          dspi_cmd <= `CMD_SEND_COMMAND;
          dspi_byte <= init_commands[command_idx];

          if (command_idx < MAX_INIT_COMMAND) begin
            command_idx <= command_idx + 1;
          end else begin
            state <= STATE_REFRESH_BEGIN;
            command_idx <= 0;
          end
        end
        STATE_REFRESH_BEGIN: begin
          dspi_cmd <= `CMD_SEND_COMMAND;
          dspi_byte <= refresh_commands[command_idx];
          if (command_idx < MAX_REFRESH_COMMAND) begin
            command_idx <= command_idx + 1;
          end else begin
            state <= STATE_REFRESH_DATA;
            page_idx <= 0;
            column_idx <= 0;
          end
        end
        STATE_REFRESH_DATA: begin
          dspi_cmd <= `CMD_SEND_DATA;
          if (page_idx == 0)
            dspi_byte <= 'hFF;
          else
            dspi_byte <= 0;
          column_idx <= column_idx + 1;
          if (column_idx == 127) begin
            page_idx <= page_idx + 1;
            if (page_idx == 7) begin
              state <= STATE_REFRESH_BEGIN;
              command_idx <= 0;
            end
          end
        end
      endcase // case (state)
    end // if (dspi_ready)
  end
endmodule // display


module display_demo(input wire  iCE_CLK,
                    output wire PIO1_02,
                    output wire PIO1_03,
                    output wire PIO1_04,
                    output wire PIO1_05,
                    output wire PIO1_06,
                    output wire LED0,
	            output wire LED1,
	            output wire LED2,
	            output wire LED3,
                    output wire LED4);

  wire dspi_ready;
  wire [2:0] dspi_cmd;
  wire [7:0] dspi_byte;

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
            .dspi_byte(dspi_byte));

  assign LED0 = 0;
  assign LED1 = 0;
  assign LED2 = 0;
  assign LED3 = 0;
  assign LED4 = 0;
endmodule // keyboard
