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
    Idle, Opcode, Reserved, LengthLSB, LengthMSB, Echo, EchoWait
  } alu_state_e;

  alu_state_e alu_state_d, alu_state_q;

  always_comb begin
    alu_state_d = alu_state_q;
    unique case (alu_state_q) 
      Idle:      alu_state_d = valid_i ? Opcode : Idle;
      Opcode: begin
        // TODO make sure to add other valid opcodes
        case (opcode_q)
          8'hec: begin
            alu_state_d = valid_i ? Reserved : Opcode;
          end
          default: alu_state_d = Idle;
        endcase
      end
      Reserved:  alu_state_d = valid_i ? LengthLSB : Reserved;
      LengthLSB: alu_state_d = valid_i ? LengthMSB : LengthLSB;
      LengthMSB: begin
        if (valid_i) begin 
          case (opcode_q)
            8'hec: alu_state_d = Echo;
            default: alu_state_d = Idle;
          endcase
        end
      end
      Echo: begin
        if (ready_i & (byte_count_q == length_q)) begin
          alu_state_d = Idle;
        end else if (ready_i) begin
          alu_state_d = EchoWait;
        end else if (valid_i) begin
          alu_state_d = Echo;
        end
      end
      EchoWait: begin
        if (byte_count_q == length_q) begin
          alu_state_d = Idle;
        end else if (valid_i) begin
          alu_state_d = Echo;
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

  logic [0:0] opcode_en_l, lsb_en_l, msb_en_l, cnt_res_l, data_en_l, data_res_l;
  always_comb begin
    opcode_en_l = (alu_state_q == Idle) & valid_i;
    lsb_en_l = (alu_state_q == Reserved) & valid_i;
    msb_en_l = (alu_state_q == LengthLSB) & valid_i;
    // TODO make it cleaner and add other opcodes
    cnt_res_l = ((alu_state_q == Echo) & ready_i & (byte_count_q == length_q)) | 
      ((alu_state_q == EchoWait) & (byte_count_q == length_q)) | 
      ((alu_state_q == Opcode) & ((opcode_q != 8'hec) | (0) | (0)));
    data_en_l = ((alu_state_q == LengthMSB) | (alu_state_q == Echo)) | (alu_state_q == EchoWait) & valid_i;
    data_res_l = cnt_res_l;
  end

  logic [0:0] valid_l, ready_l;
  always_comb begin
    valid_l = (alu_state_q == Echo);
    // TODO fix for when calcs are being done
    ready_l = 1'b1;
  end

  logic [7:0] opcode_q;
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      opcode_q <= '0;
    end else if (opcode_en_l) begin
      opcode_q <= data_i;
    end else begin
      opcode_q <= opcode_q;
    end
  end

  logic [15:0] length_q;
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      length_q <= '0;
    end else if (lsb_en_l) begin
      length_q[7:0] <= data_i;
    end else if (msb_en_l) begin
      length_q[15:8] <= data_i;
    end else begin
      length_q <= length_q;
    end
  end

  // keps track of how many bytes were received so far
  logic [15:0] byte_count_d, byte_count_q;
  always_comb begin
    if (valid_i) begin
      byte_count_d = byte_count_q + 1'b1;
    end else begin
      byte_count_d = byte_count_q;
    end
  end
  always_ff @(posedge clk_i) begin
    if (reset_i | cnt_res_l) begin
      byte_count_q <= '0;
    end else begin
      byte_count_q <= byte_count_d;
    end
  end

  logic [7:0] data_q;
  always_ff @(posedge clk_i) begin
    if (reset_i | data_res_l) begin
      data_q <= '0;
    end else if (data_en_l) begin
      data_q <= data_i;
    end else begin
      data_q <= data_q;
    end
  end

  assign ready_o = ready_l;
  assign valid_o = valid_l;
  assign data_o = data_q;
endmodule
