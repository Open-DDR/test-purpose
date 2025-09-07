#==============================================================================
# DDR2 Controller Compilation Script
# 
# Description: TCL script for compiling DDR2 controller and testbench
# Author: Open DDR Project
# Date: 2025
#==============================================================================

# Set project variables
set PROJECT_NAME "ddr2_controller"
set TOP_MODULE "ddr2_controller"
set TB_MODULE "tb_ddr2_controller"

# Create work library
vlib work
vmap work work

# Compile source files
puts "Compiling DDR2 controller source files..."

# Compile package first
vlog -sv +incdir+../../rtl/include ../../rtl/include/ddr2_pkg.sv

# Compile RTL source files
vlog -sv +incdir+../../rtl/include ../../rtl/src/ddr2_controller.sv

# Compile sub-modules (these would be implemented separately)
# vlog -sv +incdir+../../rtl/include ../../rtl/src/ddr2_cmd_decoder.sv
# vlog -sv +incdir+../../rtl/include ../../rtl/src/ddr2_bank_fsm.sv
# vlog -sv +incdir+../../rtl/include ../../rtl/src/ddr2_phy.sv
# vlog -sv +incdir+../../rtl/include ../../rtl/src/ddr2_refresh_ctrl.sv

# Compile testbench
puts "Compiling testbench..."
vlog -sv +incdir+../../rtl/include ../../testbench/unit_tests/tb_ddr2_controller.sv

puts "Compilation completed successfully!"

# Optional: Create a simple simulation script
puts "Creating simulation script..."
set sim_script [open "run_sim.do" w]
puts $sim_script "# Auto-generated simulation script"
puts $sim_script "vsim -t ps $TB_MODULE"
puts $sim_script "add wave -radix hex sim:/$TB_MODULE/*"
puts $sim_script "add wave -radix hex sim:/$TB_MODULE/dut/*"
puts $sim_script "run -all"
close $sim_script

puts "Build script completed. Use 'do run_sim.do' to run simulation."
