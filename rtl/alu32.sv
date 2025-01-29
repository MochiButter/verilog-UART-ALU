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
    Idle, AddWait, MulWait, DivLow, DivHigh, DivWait, Done
  } alu32_state_e;

  alu32_state_e alu32_state_d, alu32_state_q;

  logic [0:0] alu_ready_ol, alu_valid_ol;
  logic [0:0] adder_valid_il, mul_valid_il, div_valid_il, result_add_en_l, result_mul_en_l, result_div_en_l;
  always_comb begin
    alu32_state_d = alu32_state_q;
    alu_ready_ol = 1'b0;
    alu_valid_ol = 1'b0;

    adder_valid_il = 1'b0;
    mul_valid_il = 1'b0;
    div_valid_il = 1'b0;
    result_add_en_l = 1'b0;
    result_mul_en_l = 1'b0;
    result_div_en_l = 1'b0;

    case (alu32_state_q)
      // Idle: the alu is in an idle state and all modules are ready to take
      // an input. Input is given to the module corresponding to the opcode
      Idle: begin
        alu_ready_ol = 1'b1;
        if (valid_i) begin
          case (opcode_i)
            Add: begin
              if (adder_ready_o) begin
                alu32_state_d = AddWait;
                adder_valid_il = 1'b1;
              end
            end
            Mul: begin
              if (mul_ready_o) begin
                alu32_state_d = MulWait;
                mul_valid_il = 1'b1;
              end
            end
            Div: begin
              if (div_ready_o) begin
                alu32_state_d = DivWait;
                div_valid_il = 1'b1;
              end
            end
            default: alu32_state_d = Idle;
          endcase
        end
      end
      // AddWait: the adder is busy adding (1 cycle to register sum), when it is
      // done, save the sum in the alu output register
      AddWait: begin
        if (adder_valid_o) begin
          alu32_state_d = Done;
          result_add_en_l = 1'b1;
        end
      end
      // MulWait: the multiplier is busy multiplying the inputs. When finished,
      // returns the lower 32 bits of the product.
      MulWait: begin
        if (mul_valid_o) begin
          alu32_state_d = Done;
          result_mul_en_l = 1'b1;
        end
      end
      // DivWait: waits for the division module to produce the result and
      // remainder. The quotient is saved to the lower 32 bits of the result,
      // and the remainder in the upper 32 bits.
      DivWait: begin
        if (div_valid_o) begin
          alu32_state_d = Done;
          result_div_en_l = 1'b1;
        end
      end
      // Done: the alu has finished calculating the operation and is waiting
      // for the result to be consumed.
      Done: begin
        alu_valid_ol = 1'b1;
        if (ready_i) begin
          alu32_state_d = Idle;
        end
      end
      default: alu32_state_d = Idle;
    endcase
  end

  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      alu32_state_q <= Idle;
    end else begin
      alu32_state_q <= alu32_state_d;
    end
  end

  // Add32 turned into a module so that it has the same interface as
  // the other modules (especially latching the inputs)
  wire [0:0] adder_ready_o, adder_valid_o;
  wire [31:0] sum_o;
  add32 #() add32_inst (
    .clk_i(clk_i),
    .reset_i(reset_i),
    
    .valid_i(adder_valid_il),
    .operand_a_i(operand_a_i),
    .operand_b_i(operand_b_i),
    .ready_o(adder_ready_o),

    .ready_i(1'b1),
    .sum_o(sum_o),
    .valid_o(adder_valid_o)
  );

  wire [0:0] mul_ready_o, mul_valid_o;
  wire [31:0] mul_result_o;
  bsg_imul_iterative #(
    .width_p(32)
  ) mult_inst (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .v_i(mul_valid_il),
    .ready_and_o(mul_ready_o),

    .opA_i(operand_a_i),
    .opB_i(operand_b_i),
    .signed_opA_i(1'b1),
    .signed_opB_i(1'b1),
    .gets_high_part_i(1'b0),

    .v_o(mul_valid_o),
    .result_o(mul_result_o),
    // yumi is ready_i
    .yumi_i(1'b1)
  );

  wire [0:0] div_ready_o, div_valid_o;
  wire [31:0] div_result_o, div_remainder_o;
  bsg_idiv_iterative #(
    .width_p(32),
    //.bitstack_p(),
    .bits_per_iter_p(2)
  ) divide_inst (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .v_i(div_valid_il),
    .ready_and_o(div_ready_o),
    .dividend_i(operand_a_i),
    .divisor_i(operand_b_i),
    .signed_div_i(1'b1),
    .v_o(div_valid_o),
    .quotient_o(div_result_o),
    .remainder_o(div_remainder_o),
    // yumi is ready_i
    .yumi_i(1'b1)
  );

  // Put output through a register
  logic [63:0] result_q;
  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      result_q <= '0;
    end else if (result_add_en_l) begin
      result_q[31:0] <= sum_o;
    end else if ((alu32_state_q == MulWait) & result_mul_en_l) begin
      result_q[31:0] <= mul_result_o;
    end else if (result_div_en_l) begin
      result_q[31:0] <= div_result_o;
      result_q[63:32] <= div_remainder_o;
    end
  end

  assign result_o = result_q;
  assign ready_o = alu_ready_ol;
  assign valid_o = alu_valid_ol;
endmodule
