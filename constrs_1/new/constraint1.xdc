create_clock -period 10.000 -name clk [get_ports clk]

## Input Delay Constraints
set_input_delay -clock clk -max 1.000 [all_inputs]
set_input_delay -clock clk -min 0.500 [all_inputs]