`timescale 1ns/1ps
module top
  (input  [0:0] clk_12Mhz_i
  //,input  [0:0] reset_ni
  ,input  [0:0] rx_data_i
  ,output [0:0] tx_data_o);

  // pll 12Mhz to 18Mhz
  // Based on max allowed speed from nextpnr
  //
  // FILTER_RANGE: 1 (3'b001)
  //
  // F_PLLIN:    12.000 MHz (given)
  // F_PLLOUT:   18.000 MHz (requested)
  // F_PLLOUT:   18.000 MHz (achieved)
  //
  // FEEDBACK: SIMPLE                           
  // F_PFD:   12.000 MHz
  // F_VCO:  576.000 MHz                                
  //
  // DIVR:  0 (4'b0000)            
  // DIVF: 47 (7'b0101111)      
  // DIVQ:  5 (3'b101)
  //
  // FILTER_RANGE: 1 (3'b001)   

  wire [0:0] clk_18Mhz_w;
  SB_PLL40_PAD #(
    .FEEDBACK_PATH("SIMPLE"),
    .PLLOUT_SELECT("GENCLK"),
    .DIVR(4'd0),
    .DIVF(7'd47),
    .DIVQ(3'd5),
    .FILTER_RANGE(3'd1)
  ) pll_inst (
    .PACKAGEPIN(clk_12Mhz_i),
    .PLLOUTGLOBAL(clk_18Mhz_w),
    .RESETB(1'b1),
    .BYPASS(1'b0)
  );

  // button synchro and active low-ification
  /*
  logic [0:0] reset_n_sync_q, reset_sync_d, reset_q;
  always_ff @(posedge clk_18Mhz_w) begin
    reset_n_sync_q <= reset_ni;
    reset_q <= reset_sync_d;
  end
  always_comb begin
    reset_sync_d = ~reset_n_sync_q;
  end
  */

  logic [0:0] sync_rx_q1, sync_rx_q2;
  always_ff @(posedge clk_18Mhz_w) begin
    sync_rx_q1 <= rx_data_i;
    sync_rx_q2 <= sync_rx_q1;
  end

  alu_wrap #(
    //.Prescale(16'(25125000/(115200 * 8)))
    .Prescale(16'(18000000/(115200 * 8)))
  ) aw_inst (
    .clk_i(clk_18Mhz_w),
    .reset_i(1'b0),
    .rx_data_i(sync_rx_q2),
    .tx_data_o(tx_data_o)
  );
endmodule 
