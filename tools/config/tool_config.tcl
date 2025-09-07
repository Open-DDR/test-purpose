#==============================================================================
# DDR2 Controller Tool Configuration
# 
# Description: Configuration file for EDA tools (synthesis, P&R, simulation)
# Author: Open DDR Project
# Date: 2025
#==============================================================================

# Project configuration
set PROJECT_NAME "ddr2_controller"
set TOP_MODULE "ddr2_controller"
set PROJECT_DIR [pwd]

# Source file configuration
set RTL_DIR "${PROJECT_DIR}/../../rtl"
set TB_DIR "${PROJECT_DIR}/../../testbench"
set SCRIPTS_DIR "${PROJECT_DIR}/../../scripts"
set CONSTRAINTS_DIR "${PROJECT_DIR}/../../constraints"

# RTL source files (in compilation order)
set RTL_FILES [list \
    "${RTL_DIR}/include/ddr2_pkg.sv" \
    "${RTL_DIR}/src/ddr2_controller.sv" \
]

# Testbench files
set TB_FILES [list \
    "${TB_DIR}/unit_tests/tb_ddr2_controller.sv" \
]

# Constraint files
set CONSTRAINT_FILES [list \
    "${CONSTRAINTS_DIR}/ddr2_timing.sdc" \
]

# Synthesis configuration
set SYNTH_CONFIG [dict create \
    target_library "typical.db" \
    link_library "* typical.db" \
    symbol_library "typical.sdb" \
    clock_period 10.0 \
    clock_uncertainty 0.1 \
    input_delay 2.0 \
    output_delay 2.0 \
    max_area 0 \
    max_fanout 16 \
    max_transition 0.5 \
]

# Place and Route configuration
set PNR_CONFIG [dict create \
    floorplan_utilization 0.7 \
    core_utilization 0.8 \
    aspect_ratio 1.0 \
    core_margin 10.0 \
    placement_effort medium \
    routing_effort medium \
    timing_effort high \
]

# Simulation configuration
set SIM_CONFIG [dict create \
    simulator "modelsim" \
    time_resolution "1ps" \
    time_unit "1ns" \
    coverage_enable true \
    wave_format "vcd" \
    simulation_time "10us" \
]

# Verification configuration
set VERIF_CONFIG [dict create \
    formal_tools [list "jasper" "vcformal"] \
    coverage_metrics [list "line" "branch" "toggle" "fsm"] \
    assertion_checking true \
    protocol_checking true \
]

# Technology configuration
set TECH_CONFIG [dict create \
    process_node "28nm" \
    voltage "1.0V" \
    temperature "25C" \
    corner "typical" \
    metal_layers 8 \
]

# Memory configuration for DDR2
set DDR2_CONFIG [dict create \
    data_width 64 \
    address_width 32 \
    bank_width 3 \
    row_width 14 \
    column_width 10 \
    burst_length 4 \
    cas_latency 5 \
    frequency "400MHz" \
]

# Tool-specific configurations

# ModelSim/QuestaSim configuration
proc configure_modelsim {} {
    global SIM_CONFIG RTL_FILES TB_FILES
    
    # Create work library
    vlib work
    vmap work work
    
    # Set compiler options
    set vlog_opts "+incdir+../../rtl/include -sv -work work"
    set vsim_opts "-t ps -voptargs=+acc"
    
    return [dict create vlog_opts $vlog_opts vsim_opts $vsim_opts]
}

# Synopsys Design Compiler configuration
proc configure_dc {} {
    global SYNTH_CONFIG CONSTRAINT_FILES
    
    # Set search paths
    set search_path [list "." "/path/to/libraries"]
    
    # Set design constraints
    set sdc_files $CONSTRAINT_FILES
    
    # Optimization settings
    set compile_opts "-map_effort medium -area_effort medium"
    
    return [dict create \
        search_path $search_path \
        sdc_files $sdc_files \
        compile_opts $compile_opts \
    ]
}

# Cadence Innovus configuration
proc configure_innovus {} {
    global PNR_CONFIG TECH_CONFIG
    
    # Technology files
    set lef_files [list "/path/to/tech.lef" "/path/to/cells.lef"]
    set lib_files [list "/path/to/typical.lib"]
    
    # Floorplan settings
    set fp_settings [dict get $PNR_CONFIG]
    
    return [dict create \
        lef_files $lef_files \
        lib_files $lib_files \
        fp_settings $fp_settings \
    ]
}

# Xilinx Vivado configuration
proc configure_vivado {} {
    global PROJECT_NAME RTL_FILES CONSTRAINT_FILES
    
    # Project settings
    set part "xc7k325tffg900-2"
    set board_part ""
    
    # Synthesis settings
    set synth_opts "-flatten_hierarchy rebuilt -gated_clock_conversion off"
    
    # Implementation settings
    set impl_opts "-directive Explore"
    
    return [dict create \
        part $part \
        board_part $board_part \
        synth_opts $synth_opts \
        impl_opts $impl_opts \
    ]
}

# Intel Quartus configuration
proc configure_quartus {} {
    global PROJECT_NAME RTL_FILES
    
    # Device settings
    set family "Stratix V"
    set device "5SGXEA7N2F45C2"
    
    # Compilation settings
    set fitter_opts "--effort=standard"
    set timing_opts "--multicorner"
    
    return [dict create \
        family $family \
        device $device \
        fitter_opts $fitter_opts \
        timing_opts $timing_opts \
    ]
}

# Utility functions

# Get all source files in compilation order
proc get_source_files {} {
    global RTL_FILES TB_FILES
    return [concat $RTL_FILES $TB_FILES]
}

# Get synthesis files only
proc get_synth_files {} {
    global RTL_FILES
    return $RTL_FILES
}

# Get constraint files
proc get_constraint_files {} {
    global CONSTRAINT_FILES
    return $CONSTRAINT_FILES
}

# Print configuration summary
proc print_config {} {
    global PROJECT_NAME DDR2_CONFIG TECH_CONFIG
    
    puts "=== DDR2 Controller Configuration ==="
    puts "Project: $PROJECT_NAME"
    puts "DDR2 Configuration:"
    dict for {key value} $DDR2_CONFIG {
        puts "  $key: $value"
    }
    puts "Technology Configuration:"
    dict for {key value} $TECH_CONFIG {
        puts "  $key: $value"
    }
    puts "=================================="
}

# Validate configuration
proc validate_config {} {
    global RTL_FILES TB_FILES CONSTRAINT_FILES
    
    set errors 0
    
    # Check if source files exist
    foreach file $RTL_FILES {
        if {![file exists $file]} {
            puts "ERROR: RTL file not found: $file"
            incr errors
        }
    }
    
    foreach file $TB_FILES {
        if {![file exists $file]} {
            puts "ERROR: Testbench file not found: $file"
            incr errors
        }
    }
    
    foreach file $CONSTRAINT_FILES {
        if {![file exists $file]} {
            puts "ERROR: Constraint file not found: $file"
            incr errors
        }
    }
    
    if {$errors == 0} {
        puts "Configuration validation passed"
        return true
    } else {
        puts "Configuration validation failed with $errors errors"
        return false
    }
}

# Initialize configuration
proc init_config {} {
    print_config
    return [validate_config]
}

# Export environment variables for scripts
proc export_env {} {
    global PROJECT_NAME RTL_DIR TB_DIR SCRIPTS_DIR CONSTRAINTS_DIR
    
    set ::env(PROJECT_NAME) $PROJECT_NAME
    set ::env(RTL_DIR) $RTL_DIR
    set ::env(TB_DIR) $TB_DIR
    set ::env(SCRIPTS_DIR) $SCRIPTS_DIR
    set ::env(CONSTRAINTS_DIR) $CONSTRAINTS_DIR
}

# Main configuration initialization
if {[info exists ::argv0] && [file tail $::argv0] eq [file tail [info script]]} {
    # Script is being run directly
    init_config
    export_env
}
