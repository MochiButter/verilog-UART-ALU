`timescale 1ns / 1ps
module uart_alu 
  (input [0:0] clk_i
  ,input [0:0] reset_i

  ,input [0:0] valid_i
  ,input [7:0] data_i
  ,output [0:0] ready_o

  ,input [0:0] ready_i
  ,output [7:0] data_o
  ,output [0:0] valid_o);

  typedef enum {
    Idle, Reserved, LengthLSB, LengthMSB, Data, Done
  } alu_state_e;

  alu_state_e alu_state_d, alu_state_q;

  always_comb begin
    alu_state_d = alu_state_q;
    unique case (alu_state_q) 
      Idle: begin
        if (valid_i) begin
          alu_state_d = Reserved;
        end
      end
      Reserved: begin
        if (valid_i) begin
          alu_state_d = LengthLSB;
        end
      end
      LengthLSB: begin
        if (valid_i) begin
          alu_state_d = LengthMSB;
        end
      end
      LengthMSB: begin
        if (valid_i) begin
          alu_state_d = Data;
        end
      end
      Data: begin
        if (byte_count_q == length_q) begin
          alu_state_d = Done;
        end
      end
      Done: begin
        if (ready_i) begin
          alu_state_d = Idle;
        end
      end
      default:
        alu_state_d = Idle;
    endcase
  end

  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      alu_state_q <= Idle;
    end else begin
      alu_state_q <= alu_state_d;
    end
  end

  logic [7:0] opcode_q;
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      opcode_q <= '0;
    end else if (alu_state_q == Idle && valid_i) begin
      opcode_q <= data_i;
    end else begin
      opcode_q <= opcode_q;
    end
  end

  logic [15:0] length_q;
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      length_q <= '0;
    end else if (alu_state_q == LengthLSB && valid_i) begin
      length_q[7:0] <= data_i;
    end else if (alu_state_q == LengthMSB && valid_i) begin
      length_q[15:8] <= data_i;
    end else begin
      length_q <= length_q;
    end
  end

  // keeps track of how many bytes were received so far
  logic [15:0] byte_count_d, byte_count_q;
  always_comb begin
    if (valid_i) begin
      byte_count_d = byte_count_q + 1'b1;
    end else begin
      byte_count_d = byte_count_q;
    end
  end
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      byte_count_q <= '0;
    end else begin
      byte_count_q <= byte_count_d;
    end
  end

  logic [7:0] data_ol;
  always_comb begin
    if ((alu_state_q == Data) && (opcode_q == 8'hec)) begin
      data_ol = data_i;
    end else begin
      data_ol = '0;
    end
  end

  assign data_o = data_ol;

  assign ready_o = (alu_state_q != Done);
  assign valid_o = (alu_state_q == Done) | (alu_state_q == Data && opcode_q == 8'hec);
endmodule
