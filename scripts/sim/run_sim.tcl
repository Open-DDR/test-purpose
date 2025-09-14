#==============================================================================
# DDR2 Controller Simulation Script
# 
# Description: TCL script for running DDR2 controller simulation
# Author: Open DDR Project
# Date: 2025
#==============================================================================


# Set simulation variables for both testbenches
set TB_MODULE "tb_ddr2_controller"
set TB_AXI_MODULE "ddr2_axi_controller_tb"
set SIM_TIME "10us"

puts "Starting DDR2 Controller Simulation..."

# Change to build directory and compile if needed
cd ../build
if {![file exists "work"]} {
    puts "Work library not found. Running compilation..."
    source compile.tcl
}


# Start simulation for both testbenches
puts "Select testbench:"
puts "1. tb_ddr2_controller (default)"
puts "2. ddr2_axi_controller_tb (AXI)"
set tb_choice [gets stdin]
if {$tb_choice == "2"} {
    set TB_MODULE $TB_AXI_MODULE
}
puts "Loading simulation for $TB_MODULE..."
vsim -t ps -voptargs=+acc $TB_MODULE

# Add waves for debugging
puts "Adding waves..."


# Top-level testbench signals (support both testbenches)
if {[string match *axi* $TB_MODULE]} {
    add wave -group "Testbench" -radix hex sim:/$TB_MODULE/ACLK
    add wave -group "Testbench" -radix hex sim:/$TB_MODULE/ARESETN
} else {
    add wave -group "Testbench" -radix hex sim:/$TB_MODULE/clk
    add wave -group "Testbench" -radix hex sim:/$TB_MODULE/rst_n
}

# AXI4 Write Address Channel
add wave -group "AXI Write Addr" -radix hex sim:/$TB_MODULE/axi_awaddr
add wave -group "AXI Write Addr" -radix hex sim:/$TB_MODULE/axi_awlen
add wave -group "AXI Write Addr" -radix hex sim:/$TB_MODULE/axi_awsize
add wave -group "AXI Write Addr" -radix hex sim:/$TB_MODULE/axi_awburst
add wave -group "AXI Write Addr" -radix hex sim:/$TB_MODULE/axi_awvalid
add wave -group "AXI Write Addr" -radix hex sim:/$TB_MODULE/axi_awready

# AXI4 Write Data Channel
add wave -group "AXI Write Data" -radix hex sim:/$TB_MODULE/axi_wdata
add wave -group "AXI Write Data" -radix hex sim:/$TB_MODULE/axi_wstrb
add wave -group "AXI Write Data" -radix hex sim:/$TB_MODULE/axi_wlast
add wave -group "AXI Write Data" -radix hex sim:/$TB_MODULE/axi_wvalid
add wave -group "AXI Write Data" -radix hex sim:/$TB_MODULE/axi_wready

# AXI4 Write Response Channel
add wave -group "AXI Write Resp" -radix hex sim:/$TB_MODULE/axi_bresp
add wave -group "AXI Write Resp" -radix hex sim:/$TB_MODULE/axi_bvalid
add wave -group "AXI Write Resp" -radix hex sim:/$TB_MODULE/axi_bready

# AXI4 Read Address Channel
add wave -group "AXI Read Addr" -radix hex sim:/$TB_MODULE/axi_araddr
add wave -group "AXI Read Addr" -radix hex sim:/$TB_MODULE/axi_arlen
add wave -group "AXI Read Addr" -radix hex sim:/$TB_MODULE/axi_arsize
add wave -group "AXI Read Addr" -radix hex sim:/$TB_MODULE/axi_arburst
add wave -group "AXI Read Addr" -radix hex sim:/$TB_MODULE/axi_arvalid
add wave -group "AXI Read Addr" -radix hex sim:/$TB_MODULE/axi_arready

# AXI4 Read Data Channel
add wave -group "AXI Read Data" -radix hex sim:/$TB_MODULE/axi_rdata
add wave -group "AXI Read Data" -radix hex sim:/$TB_MODULE/axi_rresp
add wave -group "AXI Read Data" -radix hex sim:/$TB_MODULE/axi_rlast
add wave -group "AXI Read Data" -radix hex sim:/$TB_MODULE/axi_rvalid
add wave -group "AXI Read Data" -radix hex sim:/$TB_MODULE/axi_rready

# DDR2 Physical Interface
add wave -group "DDR2 Interface" -radix hex sim:/$TB_MODULE/ddr_ck_p
add wave -group "DDR2 Interface" -radix hex sim:/$TB_MODULE/ddr_ck_n
add wave -group "DDR2 Interface" -radix hex sim:/$TB_MODULE/ddr_cke
add wave -group "DDR2 Interface" -radix hex sim:/$TB_MODULE/ddr_cs_n
add wave -group "DDR2 Interface" -radix hex sim:/$TB_MODULE/ddr_ras_n
add wave -group "DDR2 Interface" -radix hex sim:/$TB_MODULE/ddr_cas_n
add wave -group "DDR2 Interface" -radix hex sim:/$TB_MODULE/ddr_we_n
add wave -group "DDR2 Interface" -radix hex sim:/$TB_MODULE/ddr_ba
add wave -group "DDR2 Interface" -radix hex sim:/$TB_MODULE/ddr_a
add wave -group "DDR2 Interface" -radix hex sim:/$TB_MODULE/ddr_odt

# DUT Internal signals (if accessible)
add wave -group "DUT Internal" -radix hex sim:/$TB_MODULE/dut/*

# Configure wave window
configure wave -namecolwidth 250
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2

# Run simulation
puts "Running simulation for $SIM_TIME..."
run $SIM_TIME

# Check if simulation completed successfully
if {[runStatus] == "finished"} {
    puts "Simulation completed successfully!"
} else {
    puts "Simulation ended with status: [runStatus]"
}

# Zoom to fit all waves
wave zoom full

puts "Simulation script completed. Use 'wave zoom full' to see all waveforms."
puts "Use 'run -all' to continue simulation or 'run <time>' for specific duration."
