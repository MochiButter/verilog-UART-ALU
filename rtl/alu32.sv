`timescale 1ns / 1ps
module alu32 
  #(parameter [0:0] ResultReg = 1'b1)
  (input [0:0] clk_i
  ,input [0:0] reset_i

  ,input [0:0] valid_i
  ,input [1:0] opcode_i
  ,input [31:0] operand_a_i
  ,input [31:0] operand_b_i
  ,output [0:0] ready_o

  ,input [0:0] ready_i
  ,output [63:0] result_o
  ,output [0:0] valid_o);

  typedef enum logic [1:0] {
    Nop, Add, Multiply, Divide
  } opcode_e;

  logic [63:0] result_d;
  logic [32:0] sum_l;
  always_comb begin
    case (opcode_i)
      Add: begin
        sum_l = operand_a_i + operand_b_i;
        // sign extend
        if(sum_l[32] == 1'b1) begin
          result_d = { {31{1'b1}}, sum_l};
        end else begin
          result_d = { {31{1'b0}}, sum_l};
        end
        //result_d = { {31{sum_l[32]}}, sum_l};
      end
      Multiply: result_d = '0;
      Divide: result_d = '0;
      // NOP: when the uart alu gets an opcode that isn't add/mul/div
      Nop: result_d = '0;
    endcase
  end

  /*
  bsg_imul_iterative #(
    .width_p(32)
  ) mult_inst (
    .clk_i(clk_i),
    .reset_i(reset_i)
    .v_i(),
    .ready_and_o()

    .opA_i(),
    .opB_i(),
    .signed_opA_i(),
    .signed_opA_i(),
    .gets_high_part_i(),

    .v_o(),
    .result_o(),
    .yumi_i()
  );

  bsg_idiv_iterative #(
    .width_p(32),
    .bitstack_p(),
    .bits_per_iter_p()
  ) divide_inst (
    .clk_i(),
    .reset_i(),
    .v_i(),
    .ready_and_o(),
    .divident_i(),
    .divisor_i(),
    .signed_div_i(),
    .v_o(),
    .quotient_o(),
    .remainder_o(),
    .yumi_i()
  );
  */

  // Put output through a register if parameter is set.
  if (ResultReg == 1'b1) begin
    logic [63:0] result_q;
    always_ff @(posedge clk_i) begin
      if(reset_i) begin
        result_q <= '0;
      end else begin
        result_q <= result_d;
      end
    end
    assign result_o = result_q;
  end else begin
    assign result_o = result_d;
  end
endmodule
