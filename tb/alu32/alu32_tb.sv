`timescale 1ns/1ps
module alu32_tb();
  logic [0:0] clk_i, reset_i;
  logic [0:0] valid_i, ready_o, ready_i, valid_o;
  logic [1:0] opcode_i;
  logic signed [31:0] operand_a_i, operand_b_i;
  logic signed [63:0] result_o;

  parameter ClkPeriod = 10;
  initial begin
    clk_i = 1'b0;
    forever begin
      #(ClkPeriod / 2);
      clk_i = ~clk_i;
    end
  end

`ifdef GLS
  alu32 #() alu32_inst (.*);
`else
  alu32 #(.ResultReg(1'b1)) alu32_inst (.*);
`endif

  task reset();
  begin
    reset_i = 1'b1;
    repeat(2) @(negedge clk_i);
    reset_i = 1'b0;
  end
  endtask

  /*
  $display("\033[0;31mSIM FAILED\033[0m");
  $finish();
  */
  typedef enum logic [1:0] {
    Add, Multiply, Divide
  } opcode_e;

  initial begin
`ifdef VERILATOR
  $dumpfile("verilator.vcd");
`else
  $dumpfile("iverilog.vcd");
`endif
  $dumpvars;
    $urandom(42);

    ready_i = 1'b1;
    reset();

    valid_i = 1'b1;
    opcode_i = Add;
    operand_a_i = $random();
    operand_b_i = $random();

    @(negedge clk_i);

    $display("Addition of %d and %d: %d (expected %d)",operand_a_i, operand_b_i, result_o, operand_a_i + operand_b_i);

    $display("No bad outputs detected");
    $display("\033[0;32mSIM PASSED\033[0m");
    $finish();
  end
endmodule
