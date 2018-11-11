`include "display.v"


module text_display(input wire       clk,
                    input wire       d_read,
                    input wire [2:0] d_page_idx,
                    input wire [6:0] d_column_idx,
                    output reg [7:0] d_data,
                    output reg       d_data_ready);

  reg [7:0]  font[0:128*8-1];
  reg [10:0] font_idx;
  reg        font_idx_ready = 0;

  reg [7:0]  text[0:16*8-1];
  reg [6:0]  text_idx;
  reg        text_idx_ready = 0;

  initial begin
    $readmemh("font.mem", font);
    $readmemh("text.mem", text);
    d_data_ready <= 0;
  end

  always @(posedge clk) begin
    d_data_ready <= 0;
    text_idx_ready <= 0;
    font_idx_ready <= 0;
    if (d_read) begin
      text_idx <= d_page_idx * 16 + d_column_idx / 8;
      text_idx_ready <= 1;
    end else if (text_idx_ready) begin
      font_idx <= (text[text_idx] - 'h20) * 8 + d_column_idx % 8;
      font_idx_ready <= 1;
    end else if (font_idx_ready) begin
      d_data <= font[font_idx];
      d_data_ready <= 1;
    end
  end
endmodule

module display_demo(input wire  iCE_CLK,
                    output wire PIO1_02,
                    output wire PIO1_03,
                    output wire PIO1_04,
                    output wire PIO1_05,
                    output wire PIO1_06);

  wire dspi_ready;
  wire [2:0] dspi_cmd;
  wire [7:0] dspi_byte;

  wire       d_read;
  wire [2:0] d_page_idx;
  wire [6:0] d_column_idx;
  wire [7:0] d_data;
  wire       d_data_ready;

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
            .d_page_idx(d_page_idx),
            .d_column_idx(d_column_idx),
            .d_data(d_data),
            .d_data_ready(d_data_ready));

  text_display td(.clk(iCE_CLK),
                  .d_read(d_read),
                  .d_page_idx(d_page_idx),
                  .d_column_idx(d_column_idx),
                  .d_data(d_data),
                  .d_data_ready(d_data_ready));
endmodule
