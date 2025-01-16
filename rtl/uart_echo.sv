`timescale 1ns/1ps
module uart_echo
  #(parameter DataWidth = 8
   ,parameter Prescale = 16'b1)
  (input  [0:0] clk_i
  ,input  [0:0] reset_i
  ,input  [0:0] rx_data_i
  ,output [0:0] tx_data_o);

  wire [DataWidth - 1:0] echo_data_w;
  wire [0:0] echo_valid_w, echo_ready_w;
  wire [0:0] rx_busy_w, rx_oe_w, rx_fe_w, tx_busy_w;

  uart_rx #(.DATA_WIDTH(DataWidth)) uart_rx_inst(
    .clk(clk_i),
    .rst(reset_i),
    .m_axis_tdata(echo_data_w),
    .m_axis_tvalid(echo_valid_w),
    .m_axis_tready(echo_ready_w),
    .rxd(rx_data_i),
    .busy(rx_busy_w),
    .overrun_error(rx_oe_w),
    .frame_error(rx_fe_w),
    .prescale(Prescale)
  );

  uart_tx #(.DATA_WIDTH(DataWidth)) uart_tx_inst(
    .clk(clk_i),
    .rst(reset_i),
    .s_axis_tdata(echo_data_w),
    .s_axis_tvalid(echo_valid_w),
    .s_axis_tready(echo_ready_w),
    .txd(tx_data_o),
    .busy(tx_busy_w),
    .prescale(Prescale)
  );
  
  wire [3:0] __unused_state__ = {rx_busy_w, rx_oe_w, rx_fe_w, tx_busy_w};
endmodule
