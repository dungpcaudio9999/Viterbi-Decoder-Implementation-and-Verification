###############################################################################
# Created by write_sdc
###############################################################################
current_design viterbi_core
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name clk -period 12.5000 [get_ports {clk}]
set_clock_transition 0.1500 [get_clocks {clk}]
set_clock_uncertainty 0.2500 clk
set_propagated_clock [get_clocks {clk}]
set_input_delay 2.5000 -clock [get_clocks {clk}] -add_delay [get_ports {piso_data_i[0]}]
set_input_delay 2.5000 -clock [get_clocks {clk}] -add_delay [get_ports {piso_data_i[1]}]
set_input_delay 2.5000 -clock [get_clocks {clk}] -add_delay [get_ports {rst_n}]
set_input_delay 2.5000 -clock [get_clocks {clk}] -add_delay [get_ports {valid_i}]
set_output_delay 2.5000 -clock [get_clocks {clk}] -add_delay [get_ports {core_data_o}]
set_output_delay 2.5000 -clock [get_clocks {clk}] -add_delay [get_ports {core_valid_o}]
###############################################################################
# Environment
###############################################################################
set_load -pin_load 0.0334 [get_ports {core_data_o}]
set_load -pin_load 0.0334 [get_ports {core_valid_o}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {clk}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {rst_n}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {valid_i}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {piso_data_i[1]}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {piso_data_i[0]}]
###############################################################################
# Design Rules
###############################################################################
set_max_transition 1.5000 [current_design]
set_max_capacitance 0.2000 [current_design]
set_max_fanout 10.0000 [current_design]
