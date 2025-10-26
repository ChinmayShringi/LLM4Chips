# Base SDC constraints for Microwatt-LL
# Clock constraint for ext_clk at 40MHz (25ns period) - relaxed for area optimization

create_clock [get_ports ext_clk] -name core_clock -period 25.0

# Input delays (assume signals arrive mid-cycle)
set_input_delay -clock core_clock -max 12.5 [all_inputs]
set_input_delay -clock core_clock -min 6.0 [all_inputs]

# Output delays (assume signals need to be stable mid-cycle)
set_output_delay -clock core_clock -max 12.5 [all_outputs]
set_output_delay -clock core_clock -min 6.0 [all_outputs]

# Remove constraints from clock port itself
set_input_delay 0 [get_ports ext_clk]

