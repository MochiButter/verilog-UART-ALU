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
    Idle, Opcode, Reserved, LengthLSB, LengthMSB, Echo, EchoWait, RegALoad, RegBLoad, ALUWait, ALUSend
  } alu_state_e;

  alu_state_e alu_state_d, alu_state_q;

  logic [7:0] alu_data_l;
  logic [0:0] opcode_en_l, lsb_en_l, msb_en_l, data_en_l, reg_reset_l, op_a_en_l, op_b_en_l, op_valid_l, alu_res_en_l, alu_ready_l, send_cnt_up_l;
  always_comb begin
    alu_state_d = alu_state_q;
    opcode_en_l = 1'b0;
    lsb_en_l = 1'b0;
    msb_en_l = 1'b0;
    data_en_l = 1'b0;
    reg_reset_l = 1'b0;
    op_a_en_l = 1'b0;
    op_b_en_l = 1'b0;
    op_valid_l = 1'b0;
    alu_res_en_l = 1'b0;
    alu_ready_l = 1'b1;
    send_cnt_up_l = 1'b0;
    alu_data_l = '0;

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
              alu_state_d = RegALoad;
              op_a_en_l = 1'b1;
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
      // RegALoad: Reads the next four bytes into a 32bit register for use
      // with the ALU. Based on the packet format, the last two bits are
      // always aligned with when each operand starts.
      RegALoad: begin
        if (valid_i) begin
          if (byte_count_q[1:0] != 2'b00) begin
            op_a_en_l = 1'b1;
          // TODO catch a case where the length is shorter than at least to
          // operands
          end else begin
            alu_state_d = RegBLoad; 
            op_b_en_l = 1'b1;
          end
        end
      end
      // RegBLoad: Same function as the pevious, but outputs the enable signal
      // for the operand b registers. After four bytes are read, goes to the
      // wait state
      RegBLoad: begin
        if (valid_i) begin
          op_b_en_l = 1'b1;
          if (byte_count_q[1:0] == 2'b11) begin
            alu_state_d = ALUWait;
          end
        end
      end
      ALUWait: begin
        op_valid_l = 1'b1;
        // TODO depending on if operands are exausted, go to done or load more
        if (alu32_valid_o) begin
          // TODO go to load more regs if length is done
          alu_state_d = ALUSend;
          alu_res_en_l = 1'b1;
        end
      end
      ALUSend: begin
        // ready may always be high
        alu_ready_l = 1'b0;
        send_cnt_up_l = ready_i;
        case (send_count_q) 
          3'h0: alu_data_l = alu_res_q[7:0];
          3'h1: alu_data_l = alu_res_q[15:8];
          3'h2: alu_data_l = alu_res_q[23:16];
          3'h3: alu_data_l = alu_res_q[31:24];

          3'h4: alu_data_l = alu_res_q[39:32];
          3'h5: alu_data_l = alu_res_q[47:40];
          3'h6: alu_data_l = alu_res_q[55:48];
          3'h7: alu_data_l = alu_res_q[63:56];
        endcase
        if (ready_i & (send_count_q == 3'h7)) begin
          alu_state_d = Idle;
        end
        // TODO fill the b register with the next 32 bits and the a register
        // with the result until no more iperands are left
        // TODO if length - counter >= 4 then load again
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
    valid_l = (alu_state_q == Echo) | (alu_state_q == ALUSend);
    // TODO fix for when calcs are being done
    ready_l = (alu_state_q != Echo);
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

  logic [2:0] send_count_d, send_count_q;
  always_comb begin
    if (send_cnt_up_l) begin
      send_count_d = send_count_q + 1'b1;
    end else begin
      send_count_d = send_count_q;
    end
  end
  always_ff @(posedge clk_i) begin
    if (reset_i | reg_reset_l) begin
      send_count_q <= '0;
    end else begin
      send_count_q <= send_count_d;
    end
  end

  logic [31:0] operand_a_q;
  always_ff @(posedge clk_i) begin
    if (reset_i | reg_reset_l) begin
      operand_a_q <= '0;
    end else if (op_a_en_l & (byte_count_q[1:0] == 2'b00)) begin
      operand_a_q[7:0] <= data_i;
    end else if (op_a_en_l & (byte_count_q[1:0] == 2'b01)) begin
      operand_a_q[15:8] <= data_i;
    end else if (op_a_en_l & (byte_count_q[1:0] == 2'b10)) begin
      operand_a_q[23:16] <= data_i;
    end else if (op_a_en_l & (byte_count_q[1:0] == 2'b11)) begin
      operand_a_q[31:24] <= data_i;
    end
  end

  logic [31:0] operand_b_q;
  always_ff @(posedge clk_i) begin
    if (reset_i | reg_reset_l) begin
      operand_b_q <= '0;
    end else if (op_b_en_l & (byte_count_q[1:0] == 2'b00)) begin
      operand_b_q[7:0] <= data_i;
    end else if (op_b_en_l & (byte_count_q[1:0] == 2'b01)) begin
      operand_b_q[15:8] <= data_i;
    end else if (op_b_en_l & (byte_count_q[1:0] == 2'b10)) begin
      operand_b_q[23:16] <= data_i;
    end else if (op_b_en_l & (byte_count_q[1:0] == 2'b11)) begin
      operand_b_q[31:24] <= data_i;
    end
  end

  wire [0:0] alu32_ready_o, alu32_valid_o;
  wire [63:0] alu_res_o;
  alu32 #() alu32_inst (
    .clk_i(clk_i),
    .reset_i(reset_i),

    .valid_i(op_valid_l),
    .opcode_i(curr_opcode),
    .operand_a_i(operand_a_q),
    .operand_b_i(operand_b_q),
    .ready_o(alu32_ready_o),

    .ready_i(alu_ready_l),
    .result_o(alu_res_o),
    .valid_o(alu32_valid_o)
  );

  logic [63:0] alu_res_q;
  always_ff @(posedge clk_i) begin
    if (reset_i | reg_reset_l) begin
      alu_res_q <= '0;
    end else if (alu_res_en_l) begin
      alu_res_q <= alu_res_o;
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
  assign data_o = ({8{alu_state_q == Echo}} & data_q) | ({8{alu_state_q == ALUSend}} & alu_data_l);
endmodule
