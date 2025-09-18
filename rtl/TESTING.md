# OpenDDR RTL Testing Instructions

## Method 1: Quick Syntax Check (No Simulator Required)

### Check basic file syntax manually:
```powershell
# Check for module/endmodule pairs
Select-String -Path "src\*.sv" -Pattern "^\s*module|^\s*endmodule"

# Check for package imports  
Select-String -Path "src\*.sv" -Pattern "import.*openddr_pkg"

# Look for interface definitions
Select-String -Path "src\*.sv" -Pattern "interface|modport"
```

## Method 2: ModelSim/QuestaSim Testing (Recommended)

### Prerequisites:
- Install ModelSim or QuestaSim
- Add to PATH: vsim, vlog, vmap

### Step 1: Compilation Test
```bash
# Create work library
vlib work
vmap work work

# Compile package first
vlog +incdir+include include/openddr_pkg.sv

# Compile modules in dependency order
vlog +incdir+include src/openddr_addr_decoder.sv
vlog +incdir+include src/openddr_axi_ctrl.sv
vlog +incdir+include src/openddr_scheduler.sv
vlog +incdir+include src/openddr_dfi_datapath.sv
vlog +incdir+include src/openddr_apb_cfg.sv
vlog +incdir+include src/openddr_controller.sv
vlog +incdir+include src/systemc_rtl_interface.sv
vlog +incdir+include src/systemc_rtl_top.sv
```

### Step 2: Elaboration Test
```bash
# Test elaboration (design check)
vsim -c -do "quit" openddr_controller
```

### Step 3: Full Simulation
```bash
# Copy testbench if not in correct location
# Then compile testbench
vlog +incdir+include tb_systemc_rtl_integration.sv

# Run simulation with GUI
vsim -gui -voptargs=+acc tb_systemc_rtl_integration

# Or batch mode
vsim -c -do "run -all; quit" tb_systemc_rtl_integration
```

## Method 3: Icarus Verilog (Open Source)

### Install Icarus Verilog:
Download from: http://iverilog.icarus.com/

### Compile and Test:
```bash
# Compile (SystemVerilog support limited)
iverilog -g2012 -I include -o test.out include/openddr_pkg.sv src/*.sv

# Simulate
vvp test.out
```

## Method 4: Vivado Simulator

### Using Vivado:
```bash
# Compile
xvlog --sv include/openddr_pkg.sv src/*.sv

# Elaborate
xelab -debug typical openddr_controller

# Simulate
xsim openddr_controller -gui
```

## Expected Results

### ✅ Successful Compilation:
- No syntax errors
- No elaboration errors  
- All modules compile cleanly
- Package imports resolve correctly

### ✅ Successful Simulation:
- Clean reset sequence
- AXI transactions complete
- APB configuration works
- DFI interface generates correct commands
- No X states or timing violations

### 🔍 What to Look For:

1. **Clean Compilation:**
   ```
   # vlog include/openddr_pkg.sv
   # Model Technology ModelSim - Intel FPGA Edition vlog 2020.1 Compiler
   # -- Compiling package openddr_pkg
   # 
   # Top level modules:
   # --none--
   ```

2. **Interface Compliance:**
   - AXI4 signals match SystemC model
   - APB protocol compliance
   - DFI timing relationships correct

3. **Testbench Results:**
   ```
   # Starting SystemC-RTL Integration Test
   # Testing RTL-only mode...
   # AXI Write Transaction: PASSED
   # AXI Read Transaction: PASSED
   # APB Configuration: PASSED
   # DFI Command Generation: PASSED
   # Test completed successfully!
   ```

## Troubleshooting Common Issues

### Issue 1: Package Import Errors
```
Error: Cannot find package 'openddr_pkg'
```
**Solution:** Ensure openddr_pkg.sv is compiled first and include path is correct.

### Issue 2: Interface Errors
```
Error: Port 'mc0_axi_awvalid' not found
```
**Solution:** Check AXI interface signal names match between modules.

### Issue 3: Timing Violations
```
Warning: Setup time violation at DFI interface
```
**Solution:** Check clock domains and delay parameters in openddr_pkg.sv.

## Performance Testing

### Test Scenarios:
1. **Basic AXI Transactions:** Single read/write
2. **Burst Transactions:** AXI burst reads/writes  
3. **Back-to-back:** Continuous transactions
4. **Configuration:** APB register access
5. **Mixed Traffic:** Combined read/write patterns

### Metrics to Monitor:
- Transaction latency
- Bandwidth utilization  
- DDR command efficiency
- Bank utilization
- Queue occupancy

## SystemC Co-simulation Setup

### Once RTL is validated:
1. Compile SystemC model
2. Set up DPI-C interface
3. Link RTL and SystemC
4. Run co-simulation tests

### Commands:
```bash
# Compile SystemC
cd ../systemc/src
make -f Makefile_enhanced

# Set up co-simulation (future enhancement)
# This requires DPI-C implementation
```

## Continuous Integration

### Automated Testing Script:
```bash
#!/bin/bash
echo "OpenDDR RTL CI Test"
vlib work
vlog +incdir+include include/openddr_pkg.sv || exit 1
vlog +incdir+include src/*.sv || exit 1
vsim -c -do "run -all; quit" tb_systemc_rtl_integration || exit 1
echo "All tests passed!"
```
