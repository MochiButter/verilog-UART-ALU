SIM_TOP := uart_alu_tb
SIM_TB := tb/uart_alu/uart_alu_tb.sv
SIM_SRC := rtl/uart_alu.sv \
					 third_party/alexforencich_uart/rtl/uart_rx.v \
					 third_party/alexforencich_uart/rtl/uart_tx.v
