`timescale 1ns / 1ps
module alu32 
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
    Nop, Add, Mul, Div
  } opcode_e;

  typedef enum {
    StIdle, StAdd, StDone
  } alu32_state_e;

  alu32_state_e alu32_state_d, alu32_state_q;

  logic [0:0] alu_ready_ol, alu_valid_ol;
  logic [0:0] adder_ready_il, adder_valid_il, result_add_en_l;
  always_comb begin
    alu32_state_d = alu32_state_q;
    alu_ready_ol = 1'b0;
    alu_valid_ol = 1'b0;

    adder_ready_il = ready_i;
    adder_valid_il = 1'b0;
    result_add_en_l = 1'b0;

    case (alu32_state_q)
      // StIdle: the alu is in an idle state and all modules are ready to take
      // an input.
      StIdle: begin
        alu_ready_ol = 1'b1;
        if (valid_i) begin
          case (opcode_i)
            Add: begin
              alu32_state_d = StAdd;
              adder_valid_il = 1'b1;
            end
            default: alu32_state_d = StIdle;
          endcase
        end
      end
      // StAdd: the adder is busy adding (1 cycle to register sum), when it is
      // done, save the sum in the alu output register
      StAdd: begin
        if (adder_valid_o) begin
          alu32_state_d = StDone;
          result_add_en_l = 1'b1;
        end
      end
      // StDone: the alu has finished calculating the operation and is waiting
      // for the result to be consumed.
      StDone: begin
        alu_valid_ol = 1'b1;
        if (ready_i) begin
          alu32_state_d = StIdle;
        end
      end
      default: alu32_state_d = StIdle;
    endcase
  end

  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      alu32_state_q <= StIdle;
    end else begin
      alu32_state_q <= alu32_state_d;
    end
  end

  wire [0:0] adder_ready_o, adder_valid_o;
  wire [31:0] sum_o;
  wire [0:0] carry_o;
  add32 #() add32_inst (
    .clk_i(clk_i),
    .reset_i(reset_i),
    
    .valid_i(adder_valid_il),
    .operand_a_i(operand_a_i),
    .operand_b_i(operand_b_i),
    .ready_o(adder_ready_o),

    .ready_i(adder_ready_il),
    .sum_o(sum_o),
    .carry_o(carry_o),
    .valid_o(adder_valid_o)
  );

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

  // Put output through a register
  logic [63:0] result_q;
  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      result_q <= '0;
    end else if (result_add_en_l) begin
      result_q <= { {32{carry_o}}, sum_o};
    end
  end
  assign result_o = result_q;
  assign ready_o = alu_ready_ol;
  assign valid_o = alu_valid_ol;
endmodule
