SIM_TOP := alu_wrap_tb
SIM_TB := tb/alu_wrap/alu_wrap_tb.sv
SIM_SRC := rtl/alu_wrap.sv \
					 rtl/uart_alu.sv \
					 rtl/alu32.sv \
					 rtl/add32.sv \
					 third_party/alexforencich_uart/rtl/uart_rx.v \
					 third_party/alexforencich_uart/rtl/uart_tx.v
