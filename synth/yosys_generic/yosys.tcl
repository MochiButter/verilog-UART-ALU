yosys -import

read_verilog -sv -icells build/synth/sim.sv2v.v

prep
opt -full
stat

write_verilog -noexpr -noattr -simple-lhs build/synth/generic_synth.v
