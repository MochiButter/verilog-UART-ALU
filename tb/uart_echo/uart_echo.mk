SIM_TOP := uart_echo_tb
SIM_TB := tb/uart_echo/uart_echo_tb.sv
SIM_SRC := rtl/uart_echo.sv \
					 third_party/alexforencich_uart/rtl/uart_rx.v \
					 third_party/alexforencich_uart/rtl/uart_tx.v
