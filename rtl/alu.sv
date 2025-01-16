`timescale 1ns / 1ps
module alu
  (input [0:0] clk_i
  ,input [0:0] reset_i
    
  /* Data in interface
   * Recieves data from uart_rx to process through the state machine
   */
  ,input [0:0] valid_i
  ,input [7:0] data_i
  ,output [0:0] ready_o

  /* Data out interface
   * Once the calculation is done, sends data out to uart_tx
   * Where the data comes from depends on the operation
   */
  ,input [0:0] ready_i
  ,output [0:0] valid_o
  ,output [7:0] data_o
  ,output [0:0] overflow_o);

  // 32 bit alu supporting add sub mul div and echo
  // after opcode and length are received, do the operation for each new
  // valid_i, then when the message ends (length is recieved) then set valid_o
  // after data is set

  // the first time rx gives a valid in the idle state is the opcode
  // the next byte is reserved
  // the next two are length (16bit)
  // the rest are data bits (32 per operand)

  // use length as a counter max value and count down per byte
  // for every four bytes do an operation (unless it is the very first operand)
  // then save the result in data_o
  // if length < 0 then move data_o to the first operand and wait
endmodule
