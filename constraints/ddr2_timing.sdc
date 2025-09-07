#==============================================================================
# DDR2 Controller Timing Constraints
# 
# Description: SDC timing constraints for DDR2 memory controller
# Author: Open DDR Project
# Date: 2025
#==============================================================================

# Clock definitions
create_clock -name sys_clk -period 10.0 [get_ports clk]
create_clock -name ddr_clk -period 5.0 [get_ports ddr_ck_p]

# Clock groups (asynchronous)
set_clock_groups -asynchronous -group [get_clocks sys_clk] -group [get_clocks ddr_clk]

# Input delays for AXI interface
set_input_delay -clock sys_clk -max 2.0 [get_ports axi_*]
set_input_delay -clock sys_clk -min 0.5 [get_ports axi_*]

# Output delays for AXI interface
set_output_delay -clock sys_clk -max 2.0 [get_ports axi_*]
set_output_delay -clock sys_clk -min 0.5 [get_ports axi_*]

# DDR2 interface timing constraints
# Clock outputs
set_output_delay -clock ddr_clk -max 0.5 [get_ports {ddr_ck_p ddr_ck_n}]
set_output_delay -clock ddr_clk -min -0.5 [get_ports {ddr_ck_p ddr_ck_n}]

# Command and address outputs
set_output_delay -clock ddr_clk -max 1.5 [get_ports {ddr_cke ddr_cs_n ddr_ras_n ddr_cas_n ddr_we_n}]
set_output_delay -clock ddr_clk -min 0.5 [get_ports {ddr_cke ddr_cs_n ddr_ras_n ddr_cas_n ddr_we_n}]

set_output_delay -clock ddr_clk -max 1.5 [get_ports {ddr_ba[*] ddr_a[*]}]
set_output_delay -clock ddr_clk -min 0.5 [get_ports {ddr_ba[*] ddr_a[*]}]

# ODT output
set_output_delay -clock ddr_clk -max 1.5 [get_ports ddr_odt]
set_output_delay -clock ddr_clk -min 0.5 [get_ports ddr_odt]

# Data mask outputs
set_output_delay -clock ddr_clk -max 1.0 [get_ports ddr_dm[*]]
set_output_delay -clock ddr_clk -min -0.5 [get_ports ddr_dm[*]]

# Data strobe constraints (bidirectional)
# Write data strobe
set_output_delay -clock ddr_clk -max 0.5 [get_ports {ddr_dqs_p[*] ddr_dqs_n[*]}]
set_output_delay -clock ddr_clk -min -0.5 [get_ports {ddr_dqs_p[*] ddr_dqs_n[*]}]

# Read data strobe (input timing)
create_clock -name ddr_dqs_read -period 5.0 [get_ports ddr_dqs_p[0]]
set_input_delay -clock ddr_dqs_read -max 0.5 [get_ports ddr_dq[*]]
set_input_delay -clock ddr_dqs_read -min -0.5 [get_ports ddr_dq[*]]

# Data bus constraints (bidirectional)
# Write data
set_output_delay -clock ddr_clk -max 1.0 [get_ports ddr_dq[*]]
set_output_delay -clock ddr_clk -min -0.5 [get_ports ddr_dq[*]]

# Maximum delay constraints for internal paths
set_max_delay -from [get_clocks sys_clk] -to [get_clocks ddr_clk] 8.0
set_max_delay -from [get_clocks ddr_clk] -to [get_clocks sys_clk] 8.0

# Minimum delay constraints
set_min_delay -from [get_clocks sys_clk] -to [get_clocks ddr_clk] 1.0
set_min_delay -from [get_clocks ddr_clk] -to [get_clocks sys_clk] 1.0

# False paths for reset
set_false_path -from [get_ports rst_n]
set_false_path -to [get_ports rst_n]

# Multicycle paths for configuration registers
set_multicycle_path -setup 2 -from [get_cells *config_reg*] -to [get_cells *]
set_multicycle_path -hold 1 -from [get_cells *config_reg*] -to [get_cells *]

# Case analysis for mode pins (if any)
# set_case_analysis 0 [get_ports mode_pin]

# Load constraints for outputs
set_load 5.0 [get_ports ddr_*]

# Drive strength for inputs
set_driving_cell -lib_cell BUFX4 [get_ports axi_*]

# Clock uncertainty
set_clock_uncertainty 0.1 [get_clocks sys_clk]
set_clock_uncertainty 0.05 [get_clocks ddr_clk]

# Clock latency (if needed for specific implementations)
# set_clock_latency -source 1.0 [get_clocks sys_clk]
# set_clock_latency -source 0.5 [get_clocks ddr_clk]

# Timing exceptions for specific paths
# Example: Relax timing on debug signals
# set_false_path -from [get_ports debug_*]
# set_false_path -to [get_ports debug_*]

# Group related signals for better placement
# set_property GROUP ddr_cmd [get_ports {ddr_cke ddr_cs_n ddr_ras_n ddr_cas_n ddr_we_n}]
# set_property GROUP ddr_addr [get_ports {ddr_ba[*] ddr_a[*]}]
# set_property GROUP ddr_data [get_ports {ddr_dq[*] ddr_dqs_p[*] ddr_dqs_n[*] ddr_dm[*]}]

# Report timing requirements
# report_timing -setup -max_paths 10
# report_timing -hold -max_paths 10
