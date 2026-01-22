###############################################################################
# Created by write_sdc
# Tue Jan 20 20:41:56 2026
###############################################################################
current_design system_top
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name clk -period 20.0000 [get_ports {clk}]
set_clock_transition 0.1500 [get_clocks {clk}]
set_clock_uncertainty 0.2500 clk
set_propagated_clock [get_clocks {clk}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_i[0]}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_i[10]}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_i[11]}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_i[12]}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_i[13]}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_i[14]}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_i[15]}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_i[1]}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_i[2]}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_i[3]}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_i[4]}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_i[5]}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_i[6]}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_i[7]}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_i[8]}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_i[9]}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {dvalid_i}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {rst_n}]
set_output_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {busy_o}]
set_output_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_o[0]}]
set_output_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_o[1]}]
set_output_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_o[2]}]
set_output_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_o[3]}]
set_output_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_o[4]}]
set_output_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_o[5]}]
set_output_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_o[6]}]
set_output_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_o[7]}]
set_output_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {valid_o}]
set_false_path\
    -from [get_ports {rst_n}]
###############################################################################
# Environment
###############################################################################
###############################################################################
# Design Rules
###############################################################################
set_max_transition 0.5000 [current_design]
set_max_fanout 10.0000 [current_design]
