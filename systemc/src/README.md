# OpenDDR DDR Memory Controller SystemC Model

This repository contains a SystemC behavioral model of the OpenDDR DDR Memory Controller for standalone verification and system-level simulation.

## Overview

The OpenDDR SystemC model provides a cycle-accurate behavioral representation of the DDR memory controller, including:

- **AXI4 Slave Interface**: Full AXI4 protocol support with configurable data width
- **APB Register Interface**: Configuration and status register access
- **DFI (DDR PHY Interface)**: DDR-specific command and data interfaces
- **Memory Scheduling**: Bank scheduling with page hit/miss tracking
- **Command Sequencing**: DDR command generation and timing management
- **Refresh Control**: Automatic refresh scheduling and management

## Features

### Supported Interfaces
- AXI4 slave port (64-bit data, 40-bit address)
- APB configuration interface
- DFI 5.0 command interface (DDR)
- DFI write data interface (16-phase)
- DFI read data interface (16-phase)
- WCK (Write Clock) control

### Memory Controller Features
- Open page policy with page table management
- Write and read buffer management
- Bank interleaving support
- Refresh scheduling (7.8μs interval for DDR)
- Configurable timing parameters
- Transaction statistics and monitoring

### Verification Features
- Comprehensive testbench with AXI master and DDR PHY models
- VCD waveform generation
- Transaction logging and statistics
- Configurable test scenarios

## File Structure

```
├── OpenDDR_systemc_model.h      # Main SystemC model header
├── OpenDDR_systemc_model.cpp    # SystemC model implementation
├── OpenDDR_testbench.cpp        # Testbench with AXI master and PHY models
├── Makefile                     # Build system
├── README.md                    # This file
└── docs/                        # Documentation (if available)
```

## Prerequisites

### SystemC Installation
1. Download SystemC from [Accellera](https://www.accellera.org/downloads/standards/systemc)
2. Extract and build SystemC:
   ```bash
   tar -xzf systemc-2.3.3.tar.gz
   cd systemc-2.3.3
   mkdir objdir && cd objdir
   ../configure --prefix=/usr/local/systemc-2.3.3
   make && sudo make install
   ```

### Required Tools
- GCC 4.8+ or Clang 3.4+ with C++11 support
- Make
- GTKWave (optional, for waveform viewing)

On Ubuntu/Debian:
```bash
sudo apt-get install build-essential gtkwave
```

## Building and Running

### Quick Start
```bash
# Set SystemC path (if different from default)
export SYSTEMC_HOME=/usr/local/systemc-2.3.3

# Build the simulation
make

# Run the simulation
make run

# View waveforms (optional)
make wave
```

### Manual Build
```bash
g++ -std=c++11 -I$SYSTEMC_HOME/include -L$SYSTEMC_HOME/lib-linux64 \
    OpenDDR_systemc_model.cpp OpenDDR_testbench.cpp \
    -lsystemc -lm -o OpenDDR_simulation

./OpenDDR_simulation
```

### Makefile Targets
- `make all` - Build the simulation executable
- `make clean` - Remove build artifacts
- `make run` - Run the simulation
- `make wave` - View waveforms with GTKWave
- `make help` - Show available targets

## Configuration

### Environment Variables
- `SYSTEMC_HOME` - Path to SystemC installation (default: `/usr/local/systemc-2.3.3`)
- `SYSTEMC_ARCH` - SystemC architecture (default: `linux64`)

### Model Configuration
The memory controller can be configured through APB register writes:

```cpp
// Example configuration in testbench
apb_write(0x000, 0x00000001); // seq_control_reg - DDR init done
apb_write(0x008, 0x00030520); // ddr_config_reg - DDR, BL32
apb_write(0x048, 0x00001F41); // refresh_cntrl_reg - Enable refresh
```

### Register Map
| Address | Register Name | Description |
|---------|---------------|-------------|
| 0x000 | seq_control_reg | Sequencer control and status |
| 0x004 | buf_config_reg | Buffer configuration |
| 0x008 | ddr_config_reg | DDR type and configuration |
| 0x00C | ddr_adr_config_reg | Address mapping configuration |
| 0x010 | pmu_cmd_reg | PMU command register |
| 0x014 | pmu_mrs_reg | Mode register set command |
| 0x018 | pmu_mpc_reg | Multi-purpose command |
| 0x01C | pmu_status_reg | PMU status (read-only) |
| 0x020-0x044 | ac_timing_reg1-10 | AC timing parameters |
| 0x048 | refresh_cntrl_reg | Refresh control |
| 0x04C | test_config_reg | Test configuration |

## Usage Examples

### Basic AXI Transactions
```cpp
// Write transaction
write_transaction(0x10000000, 0x123456789ABCDEF0ULL, 1);

// Read transaction  
read_transaction(0x10000000, 3);
```

### Custom Test Scenarios
The testbench can be modified to create custom test scenarios:

```cpp
// Test burst transactions
for (int i = 0; i < 16; i++) {
    write_transaction(0x10000000 + i*8, 0xDEADBEEF00000000ULL + i, i);
}

// Test different banks
write_transaction(0x11000000, 0xAAAABBBBCCCCDDDDULL, 5); // Bank 1
write_transaction(0x12000000, 0x1111222233334444ULL, 6); // Bank 2
```

## Simulation Output

The simulation provides detailed logging of all transactions:

```
Starting OpenDDR DDR SystemC Model Simulation...
@20 ns Reset sequence completed
@25 ns Starting APB register access...
@30 ns APB Write: Addr=0x0 Data=0x1
@50 ns Starting AXI transactions...
@60 ns AXI Write Addr: ID=1 Addr=0x10000000 Len=0
@65 ns AXI Write Data: Data=0x123456789abcdef0 Strb=0xff Last=1
@70 ns DDR Cmd Scheduled: Type=1 Rank=0 Bank=0 Row=0x800 Col=0x0
@75 ns DDR Cmd Executed: Type=1 Rank=0 Bank=0 Row=0x800 Col=0x0

=== OpenDDR SystemC Model Statistics ===
Total Write Transactions: 4
Total Read Transactions:  4
Total DDR Commands:       8
Page Hits:                2
Page Misses:              6
Page Hit Rate:            25.00%
========================================
```

## Model Architecture

### Key Components

1. **AXI Interface Handler**
   - Processes AXI4 read/write transactions
   - Manages transaction queues
   - Generates appropriate responses

2. **Scheduler**
   - Arbitrates between read and write requests
   - Implements page hit/miss detection
   - Manages buffer allocation

3. **Sequencer**
   - Converts AXI transactions to DDR commands
   - Implements DDR timing constraints
   - Manages command state machine

4. **DFI Interface**
   - Outputs DDR commands to PHY
   - Handles write data transmission
   - Processes read data reception

5. **Register Interface**
   - APB slave for configuration access
   - Implements register map
   - Provides status information

### Address Mapping
The model uses a simplified DDR address mapping:
- Rank: Address bit [31]
- Row: Address bits [30:15] 
- Bank: Address bits [14:12]
- Column: Address bits [11:2]

## Limitations

This is a behavioral model with the following limitations:

1. **Timing**: Simplified timing model (not cycle-accurate for all DDR timings)
2. **Features**: Subset of full OpenDDR controller features implemented
3. **DFI**: Simplified DFI interface (not all phases implemented)
4. **Memory**: No actual memory storage (data patterns generated)
5. **Error Handling**: Limited error injection and handling

## Extending the Model

### Adding New Features
1. Extend the register map in `read_register()` and `write_register()`
2. Add new processes for additional functionality
3. Update the constructor to register new processes

### Customizing Timing
Modify timing parameters in the AC timing registers or add new timing counters in the sequencer process.

### Adding Protocols
The model can be extended to support additional protocols by:
1. Adding new interface ports
2. Implementing protocol-specific processes
3. Updating the scheduler for new transaction types

## Troubleshooting

### Common Issues

1. **SystemC not found**
   ```
   Error: cannot open source file "systemc.h"
   ```
   Solution: Set `SYSTEMC_HOME` environment variable or update Makefile paths

2. **Linking errors**
   ```
   Error: undefined reference to SystemC functions
   ```
   Solution: Check `SYSTEMC_ARCH` matches your system (linux64, macosx64, etc.)

3. **Simulation hangs**
   - Check reset sequence timing
   - Verify clock connections
   - Enable debug output to trace execution

### Debug Tips
- Enable VCD tracing to visualize signal behavior
- Add debug prints in critical processes
- Use SystemC's `sc_assert()` for runtime checks
- Monitor transaction queues for deadlocks

## Contributing

When contributing to this model:

1. Follow SystemC coding guidelines
2. Add appropriate comments and documentation
3. Test changes with the provided testbench
4. Update this README for new features

## License

This SystemC model is provided for educational and verification purposes. Please check with your organization's policies regarding SystemC model usage and distribution.

## References

- [SystemC Language Reference Manual](https://www.accellera.org/downloads/standards/systemc)
- [DDR JEDEC Standard](https://www.jedec.org/standards-documents/docs/jesd209-5)
- [DFI Specification](https://www.jedec.org/standards-documents/docs/jesd82-01)
- [AMBA AXI Protocol Specification](https://developer.arm.com/documentation/ihi0022/latest/)

## Support

For questions or issues with this SystemC model, please:
1. Check the troubleshooting section above
2. Review the SystemC documentation
3. Consult the original RTL code for reference behavior
