###############################################################################
# Created by write_sdc
###############################################################################
current_design bmu
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name vclk -period 12.5000 
set_input_delay 2.0000 -clock [get_clocks {vclk}] -add_delay [get_ports {piso_data_i[0]}]
set_input_delay 2.0000 -clock [get_clocks {vclk}] -add_delay [get_ports {piso_data_i[1]}]
set_output_delay 2.0000 -clock [get_clocks {vclk}] -add_delay [get_ports {bm_s0_s0_o[0]}]
set_output_delay 2.0000 -clock [get_clocks {vclk}] -add_delay [get_ports {bm_s0_s0_o[1]}]
set_output_delay 2.0000 -clock [get_clocks {vclk}] -add_delay [get_ports {bm_s0_s2_o[0]}]
set_output_delay 2.0000 -clock [get_clocks {vclk}] -add_delay [get_ports {bm_s0_s2_o[1]}]
set_output_delay 2.0000 -clock [get_clocks {vclk}] -add_delay [get_ports {bm_s1_s0_o[0]}]
set_output_delay 2.0000 -clock [get_clocks {vclk}] -add_delay [get_ports {bm_s1_s0_o[1]}]
set_output_delay 2.0000 -clock [get_clocks {vclk}] -add_delay [get_ports {bm_s1_s2_o[0]}]
set_output_delay 2.0000 -clock [get_clocks {vclk}] -add_delay [get_ports {bm_s1_s2_o[1]}]
set_output_delay 2.0000 -clock [get_clocks {vclk}] -add_delay [get_ports {bm_s2_s1_o[0]}]
set_output_delay 2.0000 -clock [get_clocks {vclk}] -add_delay [get_ports {bm_s2_s1_o[1]}]
set_output_delay 2.0000 -clock [get_clocks {vclk}] -add_delay [get_ports {bm_s2_s3_o[0]}]
set_output_delay 2.0000 -clock [get_clocks {vclk}] -add_delay [get_ports {bm_s2_s3_o[1]}]
set_output_delay 2.0000 -clock [get_clocks {vclk}] -add_delay [get_ports {bm_s3_s1_o[0]}]
set_output_delay 2.0000 -clock [get_clocks {vclk}] -add_delay [get_ports {bm_s3_s1_o[1]}]
set_output_delay 2.0000 -clock [get_clocks {vclk}] -add_delay [get_ports {bm_s3_s3_o[0]}]
set_output_delay 2.0000 -clock [get_clocks {vclk}] -add_delay [get_ports {bm_s3_s3_o[1]}]
###############################################################################
# Environment
###############################################################################
set_load -pin_load 0.0500 [get_ports {bm_s0_s0_o[1]}]
set_load -pin_load 0.0500 [get_ports {bm_s0_s0_o[0]}]
set_load -pin_load 0.0500 [get_ports {bm_s0_s2_o[1]}]
set_load -pin_load 0.0500 [get_ports {bm_s0_s2_o[0]}]
set_load -pin_load 0.0500 [get_ports {bm_s1_s0_o[1]}]
set_load -pin_load 0.0500 [get_ports {bm_s1_s0_o[0]}]
set_load -pin_load 0.0500 [get_ports {bm_s1_s2_o[1]}]
set_load -pin_load 0.0500 [get_ports {bm_s1_s2_o[0]}]
set_load -pin_load 0.0500 [get_ports {bm_s2_s1_o[1]}]
set_load -pin_load 0.0500 [get_ports {bm_s2_s1_o[0]}]
set_load -pin_load 0.0500 [get_ports {bm_s2_s3_o[1]}]
set_load -pin_load 0.0500 [get_ports {bm_s2_s3_o[0]}]
set_load -pin_load 0.0500 [get_ports {bm_s3_s1_o[1]}]
set_load -pin_load 0.0500 [get_ports {bm_s3_s1_o[0]}]
set_load -pin_load 0.0500 [get_ports {bm_s3_s3_o[1]}]
set_load -pin_load 0.0500 [get_ports {bm_s3_s3_o[0]}]
set_driving_cell -lib_cell sky130_fd_sc_hd__buf_4 -pin {X} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {piso_data_i[1]}]
set_driving_cell -lib_cell sky130_fd_sc_hd__buf_4 -pin {X} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {piso_data_i[0]}]
###############################################################################
# Design Rules
###############################################################################
set_max_transition 1.5000 [current_design]
