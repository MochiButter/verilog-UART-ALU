`timescale 1ns/1ps
module alu_wrap_tb();
  logic [0:0] clk_i, reset_i;
  logic [0:0] rx_data_i, tx_data_o;

  logic [7:0] m_axis_tdata;
  logic [0:0] m_axis_tvalid;

`ifdef ICE40_GLS
  parameter Prescale = 16'(25125000/(115200 * 8));

  logic [0:0] clk_12Mhz_i;
  initial begin
    clk_12Mhz_i= 1'b0;
    forever begin
      #41.667ns;
      clk_12Mhz_i = ~clk_12Mhz_i;
    end
  end

  initial begin
    clk_i = 1'b0;
    forever begin
      #19.9ns;
      clk_i = ~clk_i;
    end
  end
  assign top_inst.pll_inst.PLLOUTGLOBAL = clk_i;

  top #() top_inst (
    .clk_12Mhz_i(clk_12Mhz_i),
    .rx_data_i(rx_data_i),
    .tx_data_o(tx_data_o)
  );
`else
  parameter ClkPeriod = 10;
  initial begin
    clk_i = 1'b0;
    forever begin
      #(ClkPeriod / 2);
      clk_i = ~clk_i;
    end
  end
  parameter Prescale = 16'b1;
  `ifdef GLS
  alu_wrap #() aw_inst (.*);
  `else
  alu_wrap #(.Prescale(Prescale)) aw_inst (.*);
  `endif
`endif

  uart_rx #() uart_rx_inst(
    .clk(clk_i),
    .rst(reset_i),
    .m_axis_tdata(m_axis_tdata),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(1'b1),
    .rxd(tx_data_o),
    .busy(),
    .overrun_error(),
    .frame_error(),
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

  integer count = 0;
  initial begin
`ifdef VERILATOR
  $dumpfile("verilator.vcd");
`else
  $dumpfile("iverilog.vcd");
`endif
  $dumpvars;

    $urandom(42);
    reset();

    repeat (2) begin
      send_byte(8'hec);
      send_byte(8'h00);
      send_byte(8'h06);
      send_byte(8'h00);
      send_byte(8'h48);
      if (count == 1) begin
        repeat (20) repeat (repeat_cnt) @(negedge clk_i);
      end
      send_byte(8'h69);

      if (m_axis_tdata != 8'h48) begin
        $display("\033[0;31mSIM FAILED\033[0m");
        $display("1st bit incorrect: %h", m_axis_tdata);
        $finish();
      end

      @(posedge m_axis_tvalid);
      #1;
      if (m_axis_tdata != 8'h69) begin
        $display("\033[0;31mSIM FAILED\033[0m");
        $display("2nd bit incorrect: %h", m_axis_tdata);
        $finish();
      end

      repeat (10) begin
        repeat (repeat_cnt) @(negedge clk_i);
      end
      count = 1;
    end

    send_byte(8'h00);
    send_byte(8'h48);
    send_byte(8'hec);
    send_byte(8'h00);
    send_byte(8'h07);
    send_byte(8'h00);
    send_byte(8'h61);
    send_byte(8'h62);
    send_byte(8'h63);

    repeat (30) begin
      repeat (repeat_cnt) @(negedge clk_i);
    end


    $display("No bad outputs detected");
    $display("\033[0;32mSIM PASSED\033[0m");
    $finish();
  end
endmodule
