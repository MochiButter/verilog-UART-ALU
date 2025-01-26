RTL_TOP := top 
RTL_SRC := synth/icesugar/top.sv \
					 third_party/alexforencich_uart/rtl/uart_rx.v \
					 third_party/alexforencich_uart/rtl/uart_tx.v \
					 rtl/uart_alu.sv \
					 rtl/alu_wrap.sv \
					 rtl/alu32.sv \
					 rtl/add32.sv \
					 third_party/basejump_stl/bsg_misc/bsg_defines.sv \
					 third_party/basejump_stl/bsg_misc/bsg_adder_cin.sv \
					 third_party/basejump_stl/bsg_misc/bsg_counter_clear_up.sv \
					 third_party/basejump_stl/bsg_misc/bsg_dff_en.sv \
					 third_party/basejump_stl/bsg_misc/bsg_mux_one_hot.sv \
					 third_party/basejump_stl/bsg_misc/bsg_idiv_iterative_controller.sv \
					 third_party/basejump_stl/bsg_misc/bsg_imul_iterative.sv \
					 third_party/basejump_stl/bsg_misc/bsg_idiv_iterative.sv
