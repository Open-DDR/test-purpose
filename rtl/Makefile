#==============================================================================
# Makefile for OpenDDR RTL-SystemC Integration
# 
# Description: Build and simulation makefile for RTL components
# Author: Open DDR Project
# Date: 2025
#==============================================================================

# Project directories
RTL_DIR = src
TB_DIR  = ../testbench/integration_tests
INC_DIR = include
BUILD_DIR = build

# Tool configurations
SIMULATOR ?= vsim
VLOG_OPTS = +incdir+$(INC_DIR) -sv -work work
VSIM_OPTS = -gui -do "run -all; quit"

# Source files
RTL_SOURCES = \
	$(INC_DIR)/openddr_pkg.sv \
	$(RTL_DIR)/openddr_addr_decoder.sv \
	$(RTL_DIR)/openddr_axi_ctrl.sv \
	$(RTL_DIR)/openddr_scheduler.sv \
	$(RTL_DIR)/openddr_dfi_datapath.sv \
	$(RTL_DIR)/openddr_apb_cfg.sv \
	$(RTL_DIR)/openddr_controller.sv \
	$(RTL_DIR)/systemc_rtl_interface.sv \
	$(RTL_DIR)/systemc_rtl_top.sv

TB_SOURCES = \
	$(TB_DIR)/tb_systemc_rtl_integration.sv

# Default target
all: compile simulate

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Compile RTL and testbench
compile: $(BUILD_DIR)
	@echo "Compiling RTL sources..."
	cd $(BUILD_DIR) && vlib work
	cd $(BUILD_DIR) && vlog $(VLOG_OPTS) $(addprefix ../,$(RTL_SOURCES))
	cd $(BUILD_DIR) && vlog $(VLOG_OPTS) $(addprefix ../,$(TB_SOURCES))

# Run simulation
simulate: compile
	@echo "Running simulation..."
	cd $(BUILD_DIR) && vsim $(VSIM_OPTS) tb_systemc_rtl_integration

# Run batch simulation (no GUI)
sim_batch: compile
	@echo "Running batch simulation..."
	cd $(BUILD_DIR) && vsim -batch -do "run -all; quit" tb_systemc_rtl_integration

# Synthesis check (basic elaboration)
elaborate: $(BUILD_DIR)
	@echo "Checking elaboration..."
	cd $(BUILD_DIR) && vlib work
	cd $(BUILD_DIR) && vlog $(VLOG_OPTS) $(addprefix ../,$(RTL_SOURCES))
	cd $(BUILD_DIR) && vlog -lint $(VLOG_OPTS) ../$(RTL_DIR)/systemc_rtl_top.sv

# Lint check
lint: $(BUILD_DIR)
	@echo "Running lint checks..."
	cd $(BUILD_DIR) && vlib work
	cd $(BUILD_DIR) && vlog -lint $(VLOG_OPTS) $(addprefix ../,$(RTL_SOURCES))

# Coverage analysis
coverage: compile
	@echo "Running coverage analysis..."
	cd $(BUILD_DIR) && vsim -coverage -do "coverage save -instance /tb_systemc_rtl_integration coverage.ucdb; run -all; quit" tb_systemc_rtl_integration
	cd $(BUILD_DIR) && vcover report -html coverage.ucdb

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)
	rm -f *.vcd *.wlf *.log transcript

# Help
help:
	@echo "Available targets:"
	@echo "  all        - Compile and simulate (default)"
	@echo "  compile    - Compile RTL and testbench"
	@echo "  simulate   - Run GUI simulation"
	@echo "  sim_batch  - Run batch simulation"
	@echo "  elaborate  - Check elaboration"
	@echo "  lint       - Run lint checks"
	@echo "  coverage   - Run coverage analysis"
	@echo "  clean      - Clean build artifacts"
	@echo "  help       - Show this help"
	@echo ""
	@echo "Environment variables:"
	@echo "  SIMULATOR  - Simulator to use (default: vsim)"

# SystemC compilation (for future integration)
systemc_compile:
	@echo "Compiling SystemC model..."
	cd ../systemc/src && make -f Makefile

# Full integration test (RTL + SystemC)
integration_test: systemc_compile compile
	@echo "Running full integration test..."
	# This would require DPI-C setup and SystemC-Verilog co-simulation
	@echo "Note: Full SystemC-RTL co-simulation requires additional setup"

.PHONY: all compile simulate sim_batch elaborate lint coverage clean help systemc_compile integration_test
