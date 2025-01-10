`timescale 1ns/1ps
module top
  (input  [0:0] clk_12Mhz_i
  ,input  [0:0] reset_i
  ,input  [0:0] rx_data_i
  ,output [0:0] tx_data_o);

  // PLL
  // figure out pll, clk and baud rate

  wire [0:0] __unused__;
  uart_echo #(.DataWidth(8), .Prescale(16'b1)) ue_inst(
    // TODO fix clkin
    .clk_i(clk_12Mhz_i),
    .reset_i(reset_i),
    .rx_data_i(rx_data_i),
    .rx_ready_i(1'b1),
    .tx_data_o(tx_data_o),
    .tx_ready_o(__unused__)
  );
endmodule 
