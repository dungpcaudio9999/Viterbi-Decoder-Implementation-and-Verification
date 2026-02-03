###############################################################################
# Created by write_sdc
###############################################################################
current_design sipo
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name clk -period 12.5000 [get_ports {clk}]
set_clock_uncertainty 0.1000 clk
set_propagated_clock [get_clocks {clk}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_serial_i}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {rst_n}]
set_input_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {valid_serial_i}]
set_output_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {byte_ready_o}]
set_output_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_parallel_o[0]}]
set_output_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_parallel_o[1]}]
set_output_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_parallel_o[2]}]
set_output_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_parallel_o[3]}]
set_output_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_parallel_o[4]}]
set_output_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_parallel_o[5]}]
set_output_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_parallel_o[6]}]
set_output_delay 2.0000 -clock [get_clocks {clk}] -add_delay [get_ports {data_parallel_o[7]}]
set_false_path\
    -from [get_ports {rst_n}]
###############################################################################
# Environment
###############################################################################
set_load -pin_load 0.0500 [get_ports {byte_ready_o}]
set_load -pin_load 0.0500 [get_ports {data_parallel_o[7]}]
set_load -pin_load 0.0500 [get_ports {data_parallel_o[6]}]
set_load -pin_load 0.0500 [get_ports {data_parallel_o[5]}]
set_load -pin_load 0.0500 [get_ports {data_parallel_o[4]}]
set_load -pin_load 0.0500 [get_ports {data_parallel_o[3]}]
set_load -pin_load 0.0500 [get_ports {data_parallel_o[2]}]
set_load -pin_load 0.0500 [get_ports {data_parallel_o[1]}]
set_load -pin_load 0.0500 [get_ports {data_parallel_o[0]}]
set_driving_cell -lib_cell sky130_fd_sc_hd__buf_4 -pin {X} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {clk}]
set_driving_cell -lib_cell sky130_fd_sc_hd__buf_4 -pin {X} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {data_serial_i}]
set_driving_cell -lib_cell sky130_fd_sc_hd__buf_4 -pin {X} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {rst_n}]
set_driving_cell -lib_cell sky130_fd_sc_hd__buf_4 -pin {X} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {valid_serial_i}]
set_input_transition 0.2000 [get_ports {clk}]
set_input_transition 0.2000 [get_ports {data_serial_i}]
set_input_transition 0.2000 [get_ports {rst_n}]
set_input_transition 0.2000 [get_ports {valid_serial_i}]
###############################################################################
# Design Rules
###############################################################################
set_max_transition 1.5000 [current_design]
set_max_capacitance 0.2000 [current_design]
set_max_fanout 6.0000 [current_design]
