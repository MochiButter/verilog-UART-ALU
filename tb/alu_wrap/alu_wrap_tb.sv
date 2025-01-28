`timescale 1ns/1ps
module alu_wrap_tb();
  logic [0:0] clk_i, reset_i;
  logic [0:0] rx_data_i, tx_data_o;

  logic [7:0] m_axis_tdata;
  logic [0:0] m_axis_tvalid;

  logic [7:0] s_axis_tdata;
  logic [0:0] s_axis_tvalid, s_axis_tready;

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

  uart_tx #() uart_tx_inst(
    .clk(clk_i),
    .rst(reset_i),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .txd(rx_data_i),
    .busy(),
    .prescale(Prescale)
  );

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

  int rnd_cnt = 0;
  int rnd_num = 0;
  logic [7:0] rnd_num_bytes [4];
  logic [15:0] bytes_send;
  int rand_opcode = 0;
  longint expected = 0;
  int tmp_exp = 0;
  logic [7:0] data_task_header [4];

  task send_msg();
  begin
    expected = 0;
    while (~s_axis_tready) @(negedge clk_i);
    // randomly generate at least 2 operands, upto 4 additional
    rnd_cnt = ({$random()} % 4 + 2);
    // bytes to send are 4 (header) + 4 per operand
    bytes_send = 16'((4 * rnd_cnt) + 4);
    assert(bytes_send % 4 == 0)
    // choose randomly from opcodes
    // rand_opcode = {$random()} % 3;
    rand_opcode = 0;
    case (rand_opcode)
      0: data_task_header[0] = 8'had;
      1: data_task_header[0] = 8'h63;
      // divide special case: only two operands
      2: begin
        rnd_cnt = 2;
        data_task_header[0] = 8'h5b;
      end
      default: begin 
        $display("Bad opcode");
        $finish();
      end
    endcase
    data_task_header[1] = 8'h00;
    data_task_header[2] = bytes_send[7:0];
    data_task_header[3] = bytes_send[15:8];
    $write("Command: ");

    // send the header
    for (int i = 0; i < 4; i ++) begin
      $write("%h", data_task_header[i]);
      s_axis_tdata = data_task_header[i];
      s_axis_tvalid = 1'b1;
      while (~s_axis_tready) @(negedge clk_i);
      @(negedge s_axis_tready);
      s_axis_tvalid = 1'b0;
      @(negedge clk_i);
    end

    for (int i = 0; i < rnd_cnt; i ++) begin
      // genrate random 32 bit number and split into bytes
      rnd_num = $random();
      rnd_num_bytes[0] = rnd_num[7:0];
      rnd_num_bytes[1] = rnd_num[15:8];
      rnd_num_bytes[2] = rnd_num[23:16];
      rnd_num_bytes[3] = rnd_num[31:24];
      case (rand_opcode)
        0: expected[31:0] = expected[31:0] + rnd_num;
        1: begin
          if (i == 0) begin
            expected[31:0] = rnd_num;
          end else begin
            expected = expected[31:0] * rnd_num;
          end
        end
        2: begin
          if (i == 0) begin
            tmp_exp = rnd_num;
          end else begin
            expected[31:0] = tmp_exp / rnd_num;
            expected[63:32] = tmp_exp % rnd_num;
          end
        end
      endcase

      // send operand
      for (int j = 0; j < 4; j ++) begin
        $write("%h", rnd_num_bytes[j]);
        s_axis_tdata = rnd_num_bytes[j];
        s_axis_tvalid = 1'b1;
        while (~s_axis_tready) @(negedge clk_i);
        s_axis_tvalid = 1'b0;
        @(negedge clk_i);
      end
    end
    $display("");
  end
  endtask

  longint actual = 0;
  int read_cnt = 0;
  logic [0:0] fail = 1'b0;
  initial begin
`ifdef VERILATOR
  $dumpfile("verilator.vcd");
`else
  $dumpfile("iverilog.vcd");
`endif
  $dumpvars;

    //$urandom(42);
    reset();

    // Test arythmetic
    repeat (10) begin
      send_msg();
      actual = 0;
      
      case (rand_opcode)
        0: read_cnt = 4;
        1, 2: read_cnt = 8;
      endcase
      for (int i = 0; i < read_cnt; i ++) begin
        while (~m_axis_tvalid) @(negedge clk_i);
        actual |= m_axis_tdata << (i * 8);
        @(negedge clk_i);
      end
      case (rand_opcode) 
        0: begin
          $display("Expected: %h\nGot:\t %h", expected[31:0], actual[31:0]);
          fail = (expected[31:0] != actual[31:0]);
        end
        1, 2: begin
          $display("Expected: %h\nGot:\t %h", expected[63:0], actual[63:0]);
          fail = (expected[63:0] != actual[63:0]);
        end
      endcase
      if (fail) begin
        $display("\033[0;31mSIM FAILED\033[0m");
        $finish();
      end
      $display("");
      repeat(10) repeat (repeat_cnt) @(negedge clk_i);
    end

    $display("No bad outputs detected");
    $display("\033[0;32mSIM PASSED\033[0m");
    $finish();
  end
endmodule
