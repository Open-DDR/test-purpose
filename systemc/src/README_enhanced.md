# OpenDDR DDR SystemC Model - Enhanced Version

## Overview

This enhanced SystemC model provides comprehensive verification capabilities for DDR memory controllers. It includes realistic data/address verification, timing checks, performance monitoring, and extensive test coverage.

## Features

### Enhanced Model Features
- **Realistic Address Mapping**: Bank, row, column address decoding
- **Timing Verification**: tRCD, tRP, tRAS, tWR timing checks
- **Data Integrity**: Write/read data verification with pattern checking
- **Performance Monitoring**: Bandwidth, latency, and efficiency metrics
- **Error Detection**: Address range, timing violation, and data error detection
- **Bank Management**: Page hit/miss tracking and bank state management
- **Refresh Handling**: Automatic and manual refresh operations
- **Power Management**: Clock gating and power state tracking

### Test Suite Features
- **Basic Write/Read Tests**: Fundamental memory operations
- **Address Pattern Tests**: Sequential, random, and boundary address testing
- **Data Pattern Tests**: Walking 1s/0s, alternating patterns, and stress patterns
- **Burst Transaction Tests**: Multi-beat read/write operations
- **Bank Interleaving Tests**: Concurrent access to different banks
- **Refresh Tests**: Refresh operation verification during active traffic
- **Timing Tests**: Stress testing of timing constraints
- **Error Injection Tests**: Out-of-range and invalid operation testing
- **Performance Tests**: Sustained traffic and bandwidth measurement

## File Structure

```
systemc/src/
├── OpenDDR_systemc_model_enhanced.h     # Enhanced model header
├── OpenDDR_systemc_model_enhanced.cpp   # Enhanced model implementation
├── OpenDDR_testbench_enhanced.cpp       # Comprehensive testbench
├── Makefile_enhanced                    # Enhanced build system
├── README_enhanced.md                   # This documentation
├── OpenDDR_systemc_model.h              # Original model header
├── OpenDDR_systemc_model.cpp            # Original model implementation
├── OpenDDR_testbench.cpp                # Original testbench
└── Makefile                            # Original Makefile
```

## Building the Model

### Prerequisites
- SystemC 2.3.3 or later
- GCC 4.8+ or Clang 3.4+ with C++11 support
- Make utility

### Build Commands

```bash
# Build enhanced version
make -f Makefile_enhanced OpenDDR_simulation_enhanced

# Build both original and enhanced versions
make -f Makefile_enhanced all

# Build with debug information
make -f Makefile_enhanced debug

# Build optimized release version
make -f Makefile_enhanced release
```

### Environment Setup

Set the SystemC installation path:
```bash
export SYSTEMC_HOME=/path/to/systemc-2.3.3
```

Or modify the Makefile_enhanced to point to your SystemC installation.

## Running Tests

### Basic Test Execution

```bash
# Run enhanced verification suite
make -f Makefile_enhanced test-enhanced

# Run both original and enhanced tests
make -f Makefile_enhanced test-all

# Run comprehensive verification
make -f Makefile_enhanced verify
```

### Advanced Testing

```bash
# Performance testing
make -f Makefile_enhanced perf-test

# Memory leak testing (requires valgrind)
make -f Makefile_enhanced mem-test

# Code coverage analysis (requires gcov)
make -f Makefile_enhanced coverage

# Static analysis (requires cppcheck)
make -f Makefile_enhanced lint
```

## Test Results Analysis

### Waveform Analysis
The simulation generates VCD trace files:
- `OpenDDR_trace_enhanced.vcd` - Enhanced model waveforms
- `OpenDDR_trace.vcd` - Original model waveforms

View with any VCD viewer (GTKWave, ModelSim, etc.):
```bash
gtkwave OpenDDR_trace_enhanced.vcd
```

### Performance Metrics
The enhanced model provides detailed statistics:
- **Transaction Counts**: Total reads, writes, and commands
- **Timing Metrics**: Average latency, bandwidth utilization
- **Efficiency Metrics**: Page hit ratio, bank utilization
- **Error Counts**: Address errors, timing violations, data mismatches

### Test Coverage
The test suite covers:
- ✅ Basic read/write operations
- ✅ Address boundary conditions
- ✅ Data pattern verification
- ✅ Burst transaction handling
- ✅ Bank interleaving scenarios
- ✅ Refresh operation timing
- ✅ Error condition handling
- ✅ Performance stress testing

## Model Architecture

### Address Mapping
```
DDR Address Format (40-bit):
[39:32] - Reserved
[31:16] - Row Address
[15:6]  - Column Address
[5:3]   - Bank Address
[2:0]   - Byte Select
```

### Timing Parameters
```cpp
// DDR-6400 Timing (example)
tCK     = 0.625ns   // Clock period
tRCD    = 18ns      // RAS to CAS delay
tRP     = 21ns      // Row precharge time
tRAS    = 42ns      // Row active time
tWR     = 18ns      // Write recovery time
tRFC    = 280ns     // Refresh cycle time
```

### DFI Interface
The model implements a complete DFI (DDR PHY Interface) including:
- Command interface (CS, Address, Control)
- Write data interface (Data, Mask, Enable)
- Read data interface (Data, Valid, Enable)
- WCK (Write Clock) control interface

## Verification Methodology

### Test Scenarios

1. **Functional Verification**
   - Basic memory operations
   - Address decoding accuracy
   - Data integrity checks
   - Protocol compliance

2. **Timing Verification**
   - Setup/hold time checks
   - Command spacing verification
   - Refresh timing compliance
   - Bank timing constraints

3. **Performance Verification**
   - Bandwidth measurement
   - Latency analysis
   - Efficiency optimization
   - Stress testing

4. **Error Handling**
   - Invalid address detection
   - Timing violation handling
   - Data corruption detection
   - Recovery mechanisms

### Coverage Metrics

The verification tracks:
- **Functional Coverage**: All commands, addresses, data patterns
- **Code Coverage**: All model code paths exercised
- **Assertion Coverage**: All timing and protocol checks
- **Toggle Coverage**: All signal transitions verified

## Customization

### Adding New Tests

1. Add test function to `OpenDDRTestbenchEnhanced` class:
```cpp
void run_custom_test() {
    std::cout << "Running Custom Test..." << std::endl;
    // Test implementation
    test_passed++;
}
```

2. Call from `stimulus_process()`:
```cpp
run_custom_test();
```

### Modifying Timing Parameters

Edit the timing constants in `OpenDDR_systemc_model_enhanced.cpp`:
```cpp
// Modify these values for different DDR speeds
static const sc_time T_RCD = sc_time(18, SC_NS);
static const sc_time T_RP  = sc_time(21, SC_NS);
static const sc_time T_RAS = sc_time(42, SC_NS);
```

### Adding New Interfaces

1. Add signals to the model header
2. Implement interface logic in the model
3. Connect signals in the testbench
4. Add verification checks

## Debugging

### Common Issues

1. **Compilation Errors**
   - Check SystemC installation path
   - Verify C++11 compiler support
   - Ensure all dependencies are met

2. **Runtime Errors**
   - Check signal connections
   - Verify timing constraints
   - Review test parameters

3. **Simulation Hangs**
   - Check for infinite loops
   - Verify clock generation
   - Review wait conditions

### Debug Features

Enable debug output:
```cpp
#define DEBUG_ENABLED 1
```

Add debug prints:
```cpp
#ifdef DEBUG_ENABLED
std::cout << "@" << sc_time_stamp() << " Debug: " << message << std::endl;
#endif
```

## Performance Optimization

### Simulation Speed
- Use optimized compiler flags (`-O3`)
- Minimize debug output in release builds
- Reduce trace file size by selective signal tracing
- Use appropriate simulation time units

### Memory Usage
- Limit transaction history depth
- Use efficient data structures
- Clean up temporary objects
- Monitor memory usage with valgrind

## Integration

### With Other Models
The enhanced model can be integrated with:
- CPU models (ARM, RISC-V, etc.)
- Cache models (L1, L2, L3)
- Interconnect models (AXI, CHI, etc.)
- System-level platforms

### With Verification Tools
Compatible with:
- UVM-SystemC verification environments
- Formal verification tools
- Coverage analysis tools
- Performance analysis tools

## Future Enhancements

### Planned Features
- [ ] DDRX support
- [ ] Advanced power modeling
- [ ] Temperature effects simulation
- [ ] Wear leveling algorithms
- [ ] Advanced error correction
- [ ] Machine learning-based optimization

### Contribution Guidelines
1. Follow existing code style
2. Add comprehensive tests for new features
3. Update documentation
4. Ensure backward compatibility
5. Submit pull requests with detailed descriptions

## Support

### Documentation
- SystemC User Guide
- DDR JEDEC Standard (JESD209-5)
- DFI Specification
- AXI Protocol Specification

### Community
- SystemC Community Forums
- GitHub Issues and Discussions
- Technical Support Channels

## License

This enhanced SystemC model is provided under the same license terms as the original OpenDDR DDR model. Please refer to the license file for detailed terms and conditions.

## Changelog

### Version 2.0 (Enhanced)
- Added comprehensive verification suite
- Implemented realistic timing checks
- Added performance monitoring
- Enhanced error detection and reporting
- Improved documentation and examples

### Version 1.0 (Original)
- Basic DDR functionality
- Simple testbench
- Basic AXI and DFI interfaces

---

For questions, issues, or contributions, please refer to the project repository or contact the development team.
