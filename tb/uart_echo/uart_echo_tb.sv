`timescale 1ns/1ps
module uart_echo_tb();
  logic [0:0] clk_i, reset_i;
  logic [0:0] rx_data_i, tx_data_o; 
  parameter DataWidth = 8;
  parameter Prescale = 1;

  uart_echo #(.DataWidth(DataWidth), .Prescale(Prescale[15:0])) ue_inst(
    .clk_i(clk_i),
    .reset_i(reset_i),
    .rx_data_i(rx_data_i),
    .tx_data_o(tx_data_o)
  );

  parameter ClkPeriod = 10;
  initial begin
    clk_i = 1'b0;
    #(ClkPeriod / 2);
    clk_i = 1'b1;
    forever begin
      #(ClkPeriod / 2);
      clk_i = ~clk_i;
    end
  end

  int repeat_cnt = Prescale * 8;
  logic [9:0] data_l = '0;

  task send_byte(input [7:0] data_i);
  begin
    // append start and end bits
    data_l = {1'b1, data_i, 1'b0};
    for(int i = 0; i < 10; i ++) begin
      rx_data_i = data_l[i];
      repeat(repeat_cnt) @(negedge clk_i);
    end
  end
  endtask

  int cnt = 0;

  task check_byte(input [7:0] data_i);
  begin
    // append start and end bits
    data_l = {1'b1, data_i, 1'b0};
    for(int i = 0; i < 10; i ++) begin
      cnt = 0;
      // sample multiple times based on the prescale input
      // if more than half are the correct values, allow
      repeat(repeat_cnt) begin
        if(tx_data_o == data_l[i]) begin
          cnt ++;
        end
        @(negedge clk_i);
      end
      if(cnt < (repeat_cnt / 2)) begin
        $display("\033[0;31mSIM FAILED\033[0m");
        $display("[tx] Bad output at bit %d of data 0x%h", i, data_i);
        $finish();
      end
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

    reset_i = 1'b1;
    rx_data_i = 1'b1;
    repeat(2) @(negedge clk_i);
    reset_i = 1'b0;

    for(int itervar_data = 0; itervar_data < (1 << DataWidth); itervar_data ++) begin
      send_byte(itervar_data[7:0]);
      check_byte(itervar_data[7:0]);
    end
    
    $display("No bad outputs detected");
    $display("\033[0;32mSIM PASSED\033[0m");
    $finish();
  end
endmodule
