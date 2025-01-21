module alu_wrap
  #(parameter Prescale = 16'b1)
  (input [0:0] clk_i
  ,input [0:0] reset_i
  ,input [0:0] rx_data_i
  ,output [0:0] tx_data_o);

  wire [7:0] data_i, data_o;
  wire [0:0] valid_i, ready_o, ready_i, valid_o;

  uart_rx #(.DATA_WIDTH(8)) uart_rx_inst(
    .clk(clk_i),
    .rst(reset_i),
    .m_axis_tdata(data_i),
    .m_axis_tvalid(valid_i),
    .m_axis_tready(ready_o),
    .rxd(rx_data_i),
    .busy(),
    .overrun_error(),
    .frame_error(),
    .prescale(Prescale)
  );

  uart_alu #() ua_inst (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .valid_i(valid_i),
    .data_i(data_i),
    .ready_o(ready_o),
    .ready_i(ready_i),
    .data_o(data_o),
    .valid_o(valid_o)
  );

  uart_tx #(.DATA_WIDTH(8)) uart_tx_inst(
    .clk(clk_i),
    .rst(reset_i),
    .s_axis_tdata(data_o),
    .s_axis_tvalid(valid_o),
    .s_axis_tready(ready_i),
    .txd(tx_data_o),
    .busy(),
    .prescale(Prescale)
  );
endmodule
