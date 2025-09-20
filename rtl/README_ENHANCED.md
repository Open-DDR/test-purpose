# DDR2 Controller RTL - Enhanced with Timing Violation Detection

This RTL implementation has been enhanced with comprehensive timing violation detection and Verilator linting integration for use with the VS Code OpenDDR Extension.

## 📁 Enhanced File Structure

### Core SystemVerilog Files
- `ddr2_axi_controller.sv` - Original DDR2 controller (preserved)
- `ddr2_axi_controller_enhanced.sv` - Full-featured controller with advanced SystemVerilog
- `ddr2_axi_controller_verilator_clean.sv` - **Verilator-compatible controller for violation injection**

### Package Definitions
- `include/ddr2_pkg.sv` - Enhanced DDR2 timing parameters and violation detection functions
- `include/openddr_pkg.sv` - Extension-specific utilities and test generation

### Timing Verification Modules
- `src/ddr2_timing_checker.sv` - Full SystemVerilog timing violation checker
- `src/ddr2_timing_checker_verilator.sv` - Verilator-compatible timing checker
- `src/ddr2_test_utils.sv` - Test generation utilities
- `src/ddr2_test_utils_verilator.sv` - Verilator-compatible test utilities

### Test Infrastructure
- `ddr2_testbench.cpp` - C++ testbench for Verilator simulation
- `test_violation_injection.sh` - Comprehensive test script for violation detection

## 🔧 Key Enhancements

### 1. **Timing Violation Detection**
The enhanced controllers include real-time timing violation detection for:
- **tFAW**: Four-activate window violations
- **tRCD**: RAS-to-CAS delay violations
- **tRP**: RAS precharge time violations  
- **tRAS**: RAS pulse width violations
- **tRRD**: Row-to-row delay violations
- **tWR**: Write recovery time violations

### 2. **Verilator Compatibility**
- Clean synthesis with `verilator --lint-only`
- Proper handling of real/integer conversions
- Lint pragmas for warning suppression
- Compatible with Verilator build system

### 3. **AXI4 Interface**
- Full AXI4 master/slave implementation
- Burst transaction support
- Response generation with proper timing
- Error handling and status reporting

### 4. **Configurable Violation Injection**
Using preprocessor flags:
```systemverilog
`ifdef TIMING_VIOLATION_TEST
  // Violation injection enabled
  `ifdef TFAW_VIOLATION
    // tFAW specific violation
  `endif
`endif
```

## 🧪 Testing and Verification

### Quick Verification Test
```bash
# Run the comprehensive test script
./test_violation_injection.sh
```

### Manual Verilator Testing
```bash
# Basic lint check
verilator --lint-only -Iinclude ddr2_axi_controller_verilator_clean.sv

# Build with violation detection
verilator --cc --exe --build --top-module ddr2_axi_controller \
  -Iinclude \
  --Mdir obj_dir_violation \
  -CFLAGS "-DTIMING_VIOLATION_TEST -DTFAW_VIOLATION -O2" \
  --trace --trace-depth 3 --trace-structs \
  --assert \
  ddr2_axi_controller_verilator_clean.sv \
  ddr2_testbench.cpp \
  -o violation_test

# Run violation test
./obj_dir_violation/violation_test
```

### Expected Output
```
========================================
DDR2 AXI Controller - Timing Violation Test
========================================
TFAW violation test enabled
Starting write transaction at cycle 20
[0] %Error: ddr2_axi_controller_verilator_clean.sv:289: Assertion failed in TOP.ddr2_axi_controller: tRP violation: RAS precharge time 15.0 ns not met at time 0
```

## 🎯 VS Code Extension Integration

This RTL is designed to work seamlessly with the VS Code OpenDDR Extension's enhanced "Inject Violation" button:

1. **Lint Check**: Pre-flight Verilator linting validation
2. **Build**: Automated violation-specific builds with timing parameters
3. **Execute**: C++ testbench with AXI transaction generation
4. **Detect**: Real-time timing violation reporting with precise timestamps
5. **Visualize**: VCD waveform generation for debugging

### Extension Button Workflow
1. Click "Inject Violation" in the extension sidebar
2. Extension runs `verilator --lint-only` on the clean controller
3. If lint passes, builds with violation flags (`-DTIMING_VIOLATION_TEST`)
4. Executes testbench to generate AXI transactions
5. Reports timing violations with detailed messages
6. Optionally generates VCD files for waveform analysis

## 📊 Timing Parameters

### DDR2 Timing Constraints (ns)
- **tRC**: 60.0 ns - RAS cycle time
- **tRAS**: 45.0 ns - RAS active time  
- **tRP**: 15.0 ns - RAS precharge time
- **tRCD**: 15.0 ns - RAS to CAS delay
- **tRRD**: 10.0 ns - RAS to RAS delay
- **tFAW**: 50.0 ns - Four activate window
- **tWR**: 15.0 ns - Write recovery time
- **tREFI**: 7800.0 ns - Refresh interval

### Violation Detection
Real-time monitoring with `$error` assertions:
```systemverilog
if (($realtime - last_activate_time) < tRCD) begin
    $error("tRCD violation: RAS to CAS delay %0.1f ns not met at time %0t", tRCD, $realtime);
end
```

## 🔧 Build System Integration

### Makefile Support
The enhanced RTL integrates with existing Makefile infrastructure while adding new targets for violation testing.

### Cross-Platform
- **Linux**: Bash scripts with comprehensive error handling
- **Windows**: PowerShell scripts with colored output (via extension)
- **Verilator**: Cross-platform C++ compilation and execution

## 📝 Notes

- Original files are preserved for compatibility
- Enhanced files use `_enhanced` or `_clean` suffixes
- Verilator-compatible versions remove advanced SystemVerilog features not supported by Verilator
- All timing calculations use precise real arithmetic for accurate violation detection
- VCD output can be enabled with `+dump` command line argument

## 🚀 Getting Started

1. Ensure Verilator is installed and in your PATH
2. Run `./test_violation_injection.sh` to verify the setup
3. Use the VS Code OpenDDR Extension's "Inject Violation" button
4. View timing violation reports in the extension output
5. Analyze waveforms with your preferred VCD viewer

This enhanced RTL provides a complete foundation for DDR2 timing violation detection and analysis within the VS Code development environment.