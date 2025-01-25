`timescale 1ns/1ps
module alu32_tb();
  logic [0:0] clk_i, reset_i;
  logic [0:0] valid_i, ready_o, ready_i, valid_o;
  logic [1:0] opcode_i;
  logic signed [31:0] operand_a_i, operand_b_i;
  logic signed [63:0] result_o;

  typedef enum logic [1:0] {
    Nop, Add, Multiply, Divide
  } opcode_e;

  parameter ClkPeriod = 10;
  initial begin
    clk_i = 1'b0;
    forever begin
      #(ClkPeriod / 2);
      clk_i = ~clk_i;
    end
  end

  alu32 #() alu32_inst (.*);

  task reset();
  begin
    reset_i = 1'b1;
    repeat(5) @(negedge clk_i);
    reset_i = 1'b0;
    @(negedge clk_i);
  end
  endtask

  logic signed [63:0] result_tb;
  int tmp, tmp2;
  logic [0:0] correct_l;
  task test_op(input opcode_e opcode, input logic signed [31:0] a_i, input logic signed [31:0] b_i); 
  begin
    valid_i = 1'b1;
    opcode_i = opcode;
    operand_a_i = a_i;
    operand_b_i = b_i;
    @(negedge clk_i);
    valid_i = 1'b0;
    @(posedge valid_o);
    correct_l = 1'b1;
    case (opcode)
      Add: begin
        // cut off at 32 bits
        tmp = operand_a_i + operand_b_i;
        result_tb = '0;
        result_tb[31:0] = tmp[31:0];
        if (result_o[31:0] != result_tb[31:0]) begin
          correct_l = 1'b0;
          $display("%s of %h and %h %h (expected %h)", opcode.name(), operand_a_i, operand_b_i, result_o[31:0], result_tb[31:0]);
        end
      end
      
      Multiply: begin
        result_tb = operand_a_i * operand_b_i;
        if (result_o != result_tb) begin
          correct_l = 1'b0;
          $display("%s of %h and %h %h (expected %h)", opcode.name(), operand_a_i, operand_b_i, result_o, result_tb);
        end
      end

      Divide: begin
        tmp = operand_a_i / operand_b_i;
        tmp2 = operand_a_i % operand_b_i;
        result_tb[31:0] = tmp[31:0];
        result_tb[63:32] = tmp2[31:0];
        if (result_o != result_tb) begin
          correct_l = 1'b0;
          $display("%s of %h and %h %h rem %h (expected %h rem %h)", opcode.name(), operand_a_i, operand_b_i, result_o[31:0], result_o[63:32], result_tb[31:0], result_tb[63:32]);
        end
      end

      default: begin
        $display("bad opcde");
        $finish();
      end
    endcase
    if (~correct_l) begin
      $display("\033[0;31mSIM FAILED\033[0m");
      $finish();
    end
    @(posedge ready_o);
    @(negedge clk_i);
  end
  endtask

  opcode_e opcode_tb;
  logic signed [31:0] op_a_tb, op_b_tb;
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

    repeat (100) begin
      // randomly select from enum index 1-3
      opcode_tb = opcode_e'({$random()} % 3 + 1);
      op_a_tb = $random();
      op_b_tb = $random();
      test_op(opcode_tb, op_a_tb, op_b_tb);
    end

    $display("No bad outputs detected");
    $display("\033[0;32mSIM PASSED\033[0m");
    $finish();
  end
endmodule
