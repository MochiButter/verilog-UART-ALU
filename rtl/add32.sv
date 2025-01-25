// Add module created to have the same ready valid & interface as the multiply
// and divide modules
`timescale 1ns / 1ps
module add32
  (input [0:0] clk_i
  ,input [0:0] reset_i

  ,input [0:0] valid_i
  ,input [31:0] operand_a_i
  ,input [31:0] operand_b_i
  ,output [0:0] ready_o

  ,input [0:0] ready_i
  ,output [31:0] sum_o
  ,output [0:0] valid_o);

  // do the calculations
  logic [32:0] sum_l;
  always_comb begin
    sum_l = operand_a_i + operand_b_i;
  end
  wire [0:0] __unused__ = sum_l[32];

  // register outputs
  logic [31:0] sum_q;
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      sum_q <= '0;
    end else if (valid_i & ready_o) begin
      sum_q <= sum_l[31:0];
    end
  end

  logic [0:0] valid_q;
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      valid_q <= '0;
    end else if (ready_o) begin
      valid_q <= (valid_i & ready_o);
    end
  end

  assign sum_o = sum_q;
  assign ready_o = ~valid_o | ready_i;
  assign valid_o = valid_q;
endmodule 
