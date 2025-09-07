# DDR2 Memory Controller Architecture

## Overview

The DDR2 memory controller is a high-performance, AXI4-compliant memory controller designed to interface with DDR2 SDRAM devices. It provides efficient memory access while maintaining compliance with JEDEC DDR2 specifications.

## Key Features

- **AXI4 Interface**: Full AXI4 slave interface for system integration
- **DDR2 Compliance**: Supports JEDEC DDR2-400/533/667/800 specifications
- **Multi-Bank Support**: Manages up to 8 banks with independent timing
- **Refresh Management**: Automatic refresh scheduling with configurable intervals
- **Power Management**: Support for power-down and self-refresh modes
- **Configurable Parameters**: Flexible timing and geometry parameters

## Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   AXI4 Master   │────│  DDR2 Controller │────│   DDR2 SDRAM    │
│    (CPU/DMA)    │    │                  │    │     Device      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Block Diagram

```
                    DDR2 Controller
    ┌─────────────────────────────────────────────────────┐
    │                                                     │
    │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │
    │  │    AXI4     │  │   Command   │  │    Bank     │ │
    │  │  Interface  │──│   Decoder   │──│ State Machine│ │
    │  └─────────────┘  └─────────────┘  └─────────────┘ │
    │         │                                   │       │
    │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │
    │  │   Request   │  │   Refresh   │  │     PHY     │ │
    │  │    Queue    │  │ Controller  │  │  Interface  │ │
    │  └─────────────┘  └─────────────┘  └─────────────┘ │
    │                                             │       │
    └─────────────────────────────────────────────┼───────┘
                                                  │
                                          DDR2 Physical
                                            Interface
```

## Major Components

### 1. AXI4 Interface
- **Purpose**: Provides standard AXI4 slave interface for system connectivity
- **Features**:
  - Full AXI4 protocol support (AR, R, AW, W, B channels)
  - Configurable data width (32/64/128 bits)
  - Burst transaction support
  - Outstanding transaction handling

### 2. Command Decoder
- **Purpose**: Translates AXI addresses to DDR2 bank/row/column addresses
- **Features**:
  - Configurable address mapping
  - Bank interleaving support
  - Row/column address extraction
  - Command prioritization

### 3. Bank State Machine
- **Purpose**: Manages individual bank states and timing constraints
- **Features**:
  - Per-bank state tracking (IDLE, ACTIVE, PRECHARGE)
  - Timing constraint enforcement (tRCD, tRP, tRAS, etc.)
  - Bank conflict detection and resolution
  - Auto-precharge support

### 4. Refresh Controller
- **Purpose**: Manages DDR2 refresh operations
- **Features**:
  - Configurable refresh interval (tREFI)
  - Refresh command scheduling
  - Refresh conflict resolution
  - Temperature-compensated refresh (optional)

### 5. PHY Interface
- **Purpose**: Provides physical interface to DDR2 device
- **Features**:
  - Clock generation and distribution
  - Data path management (DQ, DQS, DM)
  - Write leveling support
  - ODT (On-Die Termination) control

## Timing Parameters

| Parameter | Description | Typical Value (DDR2-800) |
|-----------|-------------|---------------------------|
| tRCD | RAS to CAS delay | 15 ns |
| tRP | Row precharge time | 15 ns |
| tRAS | Row active time | 40 ns |
| tRC | Row cycle time | 55 ns |
| tRRD | Row to row delay | 10 ns |
| tWR | Write recovery time | 15 ns |
| tWTR | Write to read delay | 7.5 ns |
| tRTP | Read to precharge delay | 7.5 ns |
| tCCD | Column to column delay | 2 cycles |
| tFAW | Four bank activate window | 45 ns |
| tREFI | Refresh interval | 7.8 μs |

## Address Mapping

The controller supports flexible address mapping schemes:

### Default Mapping (Row-Bank-Column)
```
AXI Address: [31:0]
├─ Row Address:    [31:19] → DDR2 A[13:0]
├─ Bank Address:   [18:16] → DDR2 BA[2:0]
└─ Column Address: [15:3]  → DDR2 A[9:0] (with A10 for auto-precharge)
```

### Alternative Mapping (Bank-Row-Column)
```
AXI Address: [31:0]
├─ Bank Address:   [31:29] → DDR2 BA[2:0]
├─ Row Address:    [28:15] → DDR2 A[13:0]
└─ Column Address: [14:3]  → DDR2 A[9:0]
```

## Performance Characteristics

### Theoretical Performance
- **Peak Bandwidth**: Up to 6.4 GB/s (DDR2-800, 64-bit interface)
- **Latency**: Minimum 3-4 clock cycles for cache hits
- **Efficiency**: 85-95% under optimal conditions

### Real-World Performance
- **Sequential Access**: 90-95% of peak bandwidth
- **Random Access**: 60-80% of peak bandwidth
- **Mixed Workload**: 70-85% of peak bandwidth

## Power Management

### Power-Down Mode
- Entered when no transactions pending
- CKE deasserted to reduce power
- Fast exit (few clock cycles)

### Self-Refresh Mode
- Entered during extended idle periods
- Internal refresh maintained by DRAM
- Slower exit (hundreds of clock cycles)

## Configuration Parameters

### Compile-Time Parameters
```systemverilog
parameter DATA_WIDTH = 64;        // 32, 64, or 128 bits
parameter ADDR_WIDTH = 32;        // AXI address width
parameter BANK_WIDTH = 3;         // 8 banks (2^3)
parameter ROW_WIDTH = 14;         // 16K rows (2^14)
parameter COL_WIDTH = 10;         // 1K columns (2^10)
```

### Runtime Configuration
- Timing parameters via mode registers
- Refresh interval adjustment
- Power management thresholds
- Address mapping selection

## Integration Guidelines

### Clock Requirements
- Single clock domain operation
- Clock frequency: 100-400 MHz
- Clean clock with low jitter (<100 ps)

### Reset Requirements
- Asynchronous assert, synchronous deassert
- Minimum reset duration: 200 μs
- DDR2 initialization sequence: ~200 μs

### Signal Integrity
- Proper termination for high-speed signals
- Matched trace lengths for data groups
- Power supply decoupling
- Ground plane integrity

## Verification Strategy

### Unit Tests
- Individual component testing
- Timing constraint verification
- Protocol compliance checking

### Integration Tests
- Full system simulation
- Real hardware validation
- Performance benchmarking
- Stress testing

### Formal Verification
- Protocol property checking
- Timing assertion verification
- Coverage analysis

## Known Limitations

1. **Single Rank Support**: Currently supports single-rank DIMMs only
2. **Fixed Burst Length**: BL=4 only (BL=8 support planned)
3. **No ECC**: Error correction not implemented
4. **Temperature Monitoring**: Basic support only

## Future Enhancements

1. **Multi-Rank Support**: Support for dual-rank DIMMs
2. **ECC Integration**: On-the-fly error correction
3. **Advanced Power Management**: Fine-grained power control
4. **Performance Optimization**: Better scheduling algorithms
5. **Debug Interface**: Enhanced observability features

## References

1. JEDEC Standard JESD79-2F: DDR2 SDRAM Specification
2. ARM AMBA AXI Protocol Specification
3. DDR2 SDRAM Controller Design Guidelines
4. High-Speed Digital Design Best Practices
