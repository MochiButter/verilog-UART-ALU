`timescale 1ns / 1ps
module alu_state
  (input [0:0] clk_i
  ,input [0:0] reset_i
  ,input [7:0] data_i
  );

  typedef enum {
    Idle, Done
  } alu_state_e;

  alu_state_e alu_state_d, alu_state_q;

  always_comb begin
    unique case (alu_state_q) 
      Idle:
      Done:
        alu_state_d = Done;
      default:
        alu_state_d = Idle;
    endcase
  end

  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      alu_state_q <= Idle;
    end
    else begin
      alu_state_q <= alu_state_d;
    end
  end
endmodule
