`timescale 1ns/1ps
module top
  (input  [0:0] clk_12Mhz_i
  //,input  [0:0] reset_ni
  ,input  [0:0] rx_data_i
  ,output [0:0] tx_data_o);

  // pll 12Mhz to 25.175Mhz
  // From my vga module

  // F_PLLIN:    12.000 MHz (given)
  // F_PLLOUT:   25.175 MHz (requested)
  // F_PLLOUT:   25.125 MHz (achieved)
  //
  // FEEDBACK: SIMPLE
  // F_PFD:   12.000 MHz
  // F_VCO:  804.000 MHz
  //
  // DIVR:  0 (4'b0000)
  // DIVF: 66 (7'b1000010)
  // DIVQ:  5 (3'b101)
  //
  // FILTER_RANGE: 1 (3'b001)

  wire [0:0] clk_25Mhz_w;
  SB_PLL40_PAD #(
    .FEEDBACK_PATH("SIMPLE"),
    .PLLOUT_SELECT("GENCLK"),
    .DIVR(4'd0),
    .DIVF(7'd66),
    .DIVQ(3'd5),
    .FILTER_RANGE(3'd5)
  ) pll_inst (
    .PACKAGEPIN(clk_12Mhz_i),
    .PLLOUTGLOBAL(clk_25Mhz_w),
    .RESETB(1'b1),
    .BYPASS(1'b0)
  );

  // button synchro and active low-ification
  /*
  logic [0:0] reset_n_sync_q, reset_sync_d, reset_q;
  always_ff @(posedge clk_25Mhz_w) begin
    reset_n_sync_q <= reset_ni;
    reset_q <= reset_sync_d;
  end
  always_comb begin
    reset_sync_d = ~reset_n_sync_q;
  end
  */

  alu_wrap #(
    .Prescale(16'(25125000/(115200 * 8)))
  ) aw_inst (
    .clk_i(clk_25Mhz_w),
    .reset_i(1'b0),
    .rx_data_i(rx_data_i),
    .tx_data_o(tx_data_o)
  );
endmodule 
