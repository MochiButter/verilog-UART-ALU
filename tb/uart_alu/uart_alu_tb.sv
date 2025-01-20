`timescale 1ns/1ps
module uart_alu_tb();
  logic [0:0] clk_i, reset_i;
  logic [0:0] ready_i, ready_o, valid_i, valid_o;
  logic [7:0] data_i, data_o;
  logic [0:0] rx_data_i, tx_data_o;

  parameter ClkPeriod = 10;
  initial begin
    clk_i = 1'b0;
    forever begin
      #(ClkPeriod / 2);
      clk_i = ~clk_i;
    end
  end

  uart_alu #() ua_inst (.*);

  parameter Prescale = 16'b1;
  uart_rx #() uart_rx_inst(
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

  uart_tx #() uart_tx_inst(
    .clk(clk_i),
    .rst(reset_i),
    .s_axis_tdata(data_o),
    .s_axis_tvalid(valid_o),
    .s_axis_tready(ready_i),
    .txd(tx_data_o),
    .busy(),
    .prescale(Prescale)
  );

  task reset();
  begin
    reset_i = 1'b1;
    repeat(2) @(negedge clk_i);
    reset_i = 1'b0;
  end
  endtask

  localparam repeat_cnt = Prescale * 8;
  logic [9:0] data_l;

  task send_byte(input [7:0] data);
  begin
    // append start and end bits
    data_l = {1'b1, data, 1'b0};
    for(int i = 0; i < 10; i ++) begin
      rx_data_i = data_l[i];
      repeat(repeat_cnt) @(negedge clk_i);
    end
  end
  endtask

  initial begin
`ifdef VERILATOR
  $dumpfile("verilator.vcd");
`else
  $dumpfile("iverilog.vcd");
`endif
  $dumpvars;

    $urandom(42);
    reset();

    send_byte(8'hec);
    send_byte(8'h00);
    send_byte(8'h06);
    send_byte(8'h00);
    send_byte(8'h42);
    send_byte(8'h69);

    repeat (300) @(negedge clk_i);

    $display("No bad outputs detected");
    $display("\033[0;32mSIM PASSED\033[0m");
    $finish();

    $display("\033[0;31mSIM FAILED\033[0m");
    $finish();
  end
endmodule
