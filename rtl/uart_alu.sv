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
    Idle, Opcode, Reserved, LengthLSB, LengthMSB, Echo, EchoWait, AddLoad
  } alu_state_e;

  alu_state_e alu_state_d, alu_state_q;

  logic [0:0] opcode_en_l, lsb_en_l, msb_en_l, data_en_l, reg_reset_l;
  always_comb begin
    alu_state_d = alu_state_q;
    opcode_en_l = 1'b0;
    lsb_en_l = 1'b0;
    msb_en_l = 1'b0;
    data_en_l = 1'b0;
    reg_reset_l = 1'b0;

    unique case (alu_state_q) 
      // Idle: wait for a valid input that matches available opcodes
      Idle: begin
        if (valid_i) begin
          case (data_i)
            8'hec, 8'had, 8'h63, 8'h5b: begin
              alu_state_d = Opcode;
              opcode_en_l = 1'b1;
            end
            default: begin
              alu_state_d = Idle;
              reg_reset_l = 1'b1;
            end
          endcase
        end
      end
      // Opcode: wait for a valid input and move to the next state
      // (can be anything, generally 0x00)
      Opcode: begin
        if (valid_i) begin
          alu_state_d = Reserved;
        end
      end
      // Reserved: wait for a valid input and save the lsb of length in
      // a register
      Reserved: begin
        if (valid_i) begin
          alu_state_d = LengthLSB;
          lsb_en_l = 1'b1;
        end
      end
      // LengthLSB: wait for a valid input and save the msb of a length in
      // a register
      LengthLSB: begin
        if (valid_i) begin
          alu_state_d = LengthMSB;
          msb_en_l = 1'b1;
        end
      end
      // LengthMSB: wait for a valid input. Depending on the opcode saved, the
      // next state and the destinatin register of the data is changed.
      LengthMSB: begin
        if (valid_i) begin 
          case (opcode_q)
            8'hec: begin
              alu_state_d = Echo;
              data_en_l = 1'b1;
            end
            8'had: begin
              alu_state_d = AddLoad;
              // TODO alu registers
            end
            default: begin
              alu_state_d = Idle;
              reg_reset_l = 1'b1;
            end
          endcase
        end
      end
      // Echo: hold the valid echo byte until the consumer is ready. After the
      // data has been transmitted, lower the valid bit and wait for the next
      // valid input in the EchoWait state. If all bytes has been exausted,
      // then go to the idle state
      Echo: begin
        if (ready_i & (byte_count_q == length_q)) begin
          alu_state_d = Idle;
          reg_reset_l = 1'b1;
        end else if (ready_i) begin
          alu_state_d = EchoWait;
        end else if (valid_i) begin
          alu_state_d = Echo;
          data_en_l = 1'b1;
        end
      end
      // EchoWait: after the valid output has been consumed, wait for the next
      // valud input, unless there are no more bytes to be expected
      EchoWait: begin
        if (byte_count_q == length_q) begin
          alu_state_d = Idle;
          reg_reset_l = 1'b1;
        end else if (valid_i) begin
          alu_state_d = Echo;
          data_en_l = 1'b1;
        end
      end
      AddLoad: begin
        // TODO sequentially add to registers per byte in 32bit operand
      end
      // default: catch all for failed states
      default: begin
        alu_state_d = Idle;
        reg_reset_l = 1'b1;
      end
    endcase
  end

  always_ff @(posedge clk_i) begin
    if(reset_i) begin
      alu_state_q <= Idle;
    end else begin
      alu_state_q <= alu_state_d;
    end
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

  typedef enum logic [1:0] {
    Nop, Add, Mul, Div
  } opcode_e;
  opcode_e curr_opcode;
  // opcodes were chosen to have no repeating hex digits
  always_comb begin
    case (opcode_q)
      8'had: curr_opcode = Add;
      8'h63: curr_opcode = Mul;
      8'h5b: curr_opcode = Div;
      default: curr_opcode = Nop;
    endcase
  end
  wire [1:0] __unused__ = curr_opcode;

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
    if (reset_i | reg_reset_l) begin
      byte_count_q <= '0;
    end else begin
      byte_count_q <= byte_count_d;
    end
  end

  logic [7:0] data_q;
  always_ff @(posedge clk_i) begin
    if (reset_i | reg_reset_l) begin
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
