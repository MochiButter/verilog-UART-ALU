yosys -import

read_verilog -sv -icells build/synth/rtl.sv2v.v

synth_ice40 -top top

write_verilog -noexpr -noattr -simple-lhs build/synth/ice40_synth.v
write_json build/synth/ice40.json
