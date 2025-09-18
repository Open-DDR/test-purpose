# OpenDDR RTL Implementation with SystemC Interface

This directory contains the RTL implementation of the OpenDDR memory controller with interfaces designed to work with the SystemC model located in `../systemc`.

## Directory Structure

```
rtl/
├── include/
│   ├── ddr2_pkg.sv              # Original DDR2 package (legacy)
│   └── openddr_pkg.sv           # New OpenDDR package with types and parameters
├── src/
│   ├── ddr2_controller.sv       # Original DDR2 controller (legacy)
│   ├── openddr_controller.sv    # Main OpenDDR controller
│   ├── openddr_addr_decoder.sv  # Address decoder module
│   ├── openddr_axi_ctrl.sv      # AXI protocol controller
│   ├── openddr_scheduler.sv     # Command scheduler and bank FSM
│   ├── openddr_dfi_datapath.sv  # DFI data path handling
│   ├── openddr_apb_cfg.sv       # APB configuration interface
│   ├── systemc_rtl_interface.sv # SystemC-RTL bridge interface
│   └── systemc_rtl_top.sv       # Top-level integration module
├── Makefile                     # Build and simulation makefile
└── README.md                    # This file
```

## Key Features

### 1. **OpenDDR Controller (`openddr_controller.sv`)**
- **AXI4 Interface**: Full AXI4 slave interface matching SystemC model
- **APB Configuration**: APB slave for register configuration
- **DFI Interface**: DDR PHY interface with 4-phase operation
- **Modular Design**: Composed of specialized sub-modules

### 2. **SystemC-RTL Interface (`systemc_rtl_interface.sv`)**
- **Protocol Bridge**: Converts between SystemC signals and AXI4
- **Transaction Management**: Handles burst transactions and state management
- **DPI-C Ready**: Prepared for SystemC co-simulation via DPI-C

### 3. **Top-Level Integration (`systemc_rtl_top.sv`)**
- **Mode Selection**: Switch between RTL-only and SystemC-RTL modes
- **Unified Interface**: Common external interface for both modes
- **Co-simulation Ready**: Infrastructure for SystemC-RTL co-simulation

## Interface Compatibility with SystemC

The RTL implementation provides the same interfaces as the SystemC model:

### AXI4 Interface
```systemverilog
// Matches SystemC sc_in/sc_out ports
input  logic [11:0]  mc0_axi_awid      // SystemC: sc_in<sc_uint<12>>
input  logic [39:0]  mc0_axi_awaddr    // SystemC: sc_in<sc_uint<40>>
input  logic [7:0]   mc0_axi_awlen     // SystemC: sc_in<sc_uint<8>>
// ... (full AXI4 interface)
```

### APB Configuration Interface
```systemverilog
// Matches SystemC APB interface
input  logic [9:0]   mc_paddr          // SystemC: sc_in<sc_uint<10>>
input  logic [31:0]  mc_pwdata         // SystemC: sc_in<sc_uint<32>>
output logic [31:0]  mc_prdata         // SystemC: sc_out<sc_uint<32>>
```

### DFI Interface
```systemverilog
// Matches SystemC DFI interface
output logic [1:0]   dfi_cs_0_p0       // SystemC: sc_out<sc_uint<2>>
output logic [6:0]   dfi_address_0_p0  // SystemC: sc_out<sc_uint<7>>
// ... (full DFI interface)
```

## Build and Simulation

### Prerequisites
- ModelSim/QuestaSim or compatible simulator
- SystemVerilog support
- Make utility

### Basic Usage
```bash
# Compile and simulate with GUI
make

# Batch simulation
make sim_batch

# Lint check
make lint

# Clean build artifacts
make clean
```

### Advanced Options
```bash
# Check elaboration only
make elaborate

# Run coverage analysis
make coverage

# Compile SystemC model (preparation for co-simulation)
make systemc_compile
```

## SystemC-RTL Co-Simulation

The RTL is designed to work with the SystemC model through:

1. **DPI-C Interface**: SystemC can call RTL functions and vice versa
2. **Shared Memory**: Common data structures for transaction passing
3. **Clock Domain Bridging**: Proper synchronization between domains

### Setting Up Co-Simulation

1. **Compile SystemC Model**:
   ```bash
   cd ../systemc/src
   make -f Makefile_enhanced
   ```

2. **Configure DPI-C** (example):
   ```systemverilog
   import "DPI-C" function void systemc_write_transaction(
       input longint addr,
       input longint data
   );
   
   export "DPI-C" function rtl_transaction_complete;
   ```

3. **SystemC Side**:
   ```cpp
   extern "C" void systemc_write_transaction(uint64_t addr, uint64_t data) {
       // Handle transaction from RTL
   }
   ```

## Testing

The testbench (`../testbench/integration_tests/tb_systemc_rtl_integration.sv`) provides:

- **Mode Switching**: Test both RTL-only and SystemC interface modes
- **AXI Transactions**: Write/read transactions with different patterns
- **APB Configuration**: Register configuration and readback
- **Timing Verification**: Check proper timing relationships

### Running Tests
```bash
# Run integration test
make simulate

# View waveforms (generates systemc_rtl_integration.vcd)
gtkwave systemc_rtl_integration.vcd
```

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   SystemC       │    │  RTL Interface  │    │  OpenDDR        │
│   Model         │◄──►│  Bridge         │◄──►│  Controller     │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   SystemC       │    │  AXI Protocol   │    │  DDR PHY        │
│   Simulation    │    │  Handling       │    │  Interface      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Configuration

### Default Configuration Registers
- **0x000**: CTRL_REG (0x00000001) - Controller Enable
- **0x004**: DDR_CONFIG (0x00030000) - DDR mode, 64-bit, BL8
- **0x008**: VERSION_REG (0x12345678) - Version identifier
- **0x020-0x02C**: Timing parameters (tRCD, tRP, tRAS, tRC)

### DDR Timing Parameters
```systemverilog
parameter int tRCD = 18;    // RAS to CAS delay
parameter int tRP  = 18;    // Row precharge time
parameter int tRAS = 42;    // Row active time
parameter int tRC  = 60;    // Row cycle time
parameter int tREFI = 3120; // Refresh interval
```

## Future Enhancements

1. **Enhanced DPI-C Integration**: Full bidirectional communication
2. **Performance Monitoring**: Built-in performance counters
3. **Error Injection**: Controllable error injection for testing
4. **Power Management**: Clock gating and power-down modes
5. **Multi-Channel Support**: Support for multiple memory channels

## Troubleshooting

### Common Issues

1. **Compilation Errors**:
   - Check SystemVerilog support in simulator
   - Verify include paths are correct
   - Ensure all source files are present

2. **Simulation Hangs**:
   - Check clock generation
   - Verify reset sequence
   - Check for infinite loops in state machines

3. **AXI Protocol Violations**:
   - Use AXI protocol checker
   - Verify handshaking signals
   - Check burst length compliance

### Debug Tips

1. **Waveform Analysis**:
   ```bash
   make simulate
   # Open generated VCD file in waveform viewer
   ```

2. **Enable Debugging**:
   ```systemverilog
   `define DEBUG_ENABLE
   // Add debug prints in modules
   ```

3. **Protocol Monitoring**:
   - Add AXI monitor module
   - Log transaction details
   - Check timing relationships

## Related Documentation

- [SystemC Model Documentation](../systemc/README.md)
- [Integration Guide](../docs/integration_guide.md)
- [Test Results](../testbench/test_results.md)
- [Performance Analysis](../docs/performance_analysis.md)

For questions or issues, please refer to the project documentation or create an issue in the project repository.
