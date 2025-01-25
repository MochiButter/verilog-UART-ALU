SIM_TOP := alu32_tb
SIM_TB := tb/alu32/alu32_tb.sv
SIM_SRC := rtl/alu32.sv \
					 rtl/add32.sv \
					 third_party/basejump_stl/bsg_misc/bsg_defines.sv \
					 third_party/basejump_stl/bsg_misc/bsg_adder_cin.sv \
					 third_party/basejump_stl/bsg_misc/bsg_counter_clear_up.sv \
					 third_party/basejump_stl/bsg_misc/bsg_dff_en.sv \
					 third_party/basejump_stl/bsg_misc/bsg_mux_one_hot.sv \
					 third_party/basejump_stl/bsg_misc/bsg_idiv_iterative_controller.sv \
					 third_party/basejump_stl/bsg_misc/bsg_imul_iterative.sv \
					 third_party/basejump_stl/bsg_misc/bsg_idiv_iterative.sv
