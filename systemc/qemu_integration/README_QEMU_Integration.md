# QEMU Integration Guide for Whitney LPDDR5 SystemC Model

## Overview

This guide explains how to interface the Whitney LPDDR5 SystemC model with QEMU for comprehensive system-level testing. The integration allows QEMU to use the SystemC model as a realistic memory backend, enabling full software stack testing with accurate LPDDR5 behavior.

## Integration Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│     QEMU        │    │   Socket Bridge  │    │   SystemC Model     │
│                 │    │                  │    │                     │
│  ┌───────────┐  │    │  ┌─────────────┐ │    │  ┌───────────────┐  │
│  │    CPU    │  │    │  │   Memory    │ │    │  │   Whitney     │  │
│  │           │  │◄──►│  │   Manager   │ │◄──►│  │   LPDDR5      │  │
│  └───────────┘  │    │  │             │ │    │  │   Model       │  │
│                 │    │  └─────────────┘ │    │  └───────────────┘  │
│  ┌───────────┐  │    │                  │    │                     │
│  │  Devices  │  │    │  ┌─────────────┐ │    │  ┌───────────────┐  │
│  │           │  │    │  │   Protocol  │ │    │  │  Verification │  │
│  └───────────┘  │    │  │   Bridge    │ │    │  │  Framework    │  │
│                 │    │  └─────────────┘ │    │  └───────────────┘  │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
```

## Quick Start

### 1. Build the SystemC Bridge

```bash
cd systemc/qemu_integration/systemc_bridge
make all
```

### 2. Test the Bridge

```bash
# Start SystemC server
./whitney_systemc_server --port 8888 --memory-size 1024 --arch arm64 &

# Test connectivity
./test_client --server localhost:8888 --test basic

# Stop server
killall whitney_systemc_server
```

### 3. Run Example Test

```bash
cd ../examples
./run_arm64_test.sh
```

## File Structure

```
qemu_integration/
├── README_QEMU_Integration.md     # This file
├── systemc_bridge/                # SystemC-QEMU bridge implementation
│   ├── qemu_systemc_bridge.h      # Bridge header file
│   ├── qemu_systemc_bridge.cpp    # Bridge implementation
│   ├── whitney_systemc_server.cpp # Standalone server application
│   ├── test_client.cpp            # Test client for validation
│   └── Makefile                   # Build system
└── examples/                      # Example scripts and tests
    ├── run_arm64_test.sh          # ARM64 system test
    ├── run_riscv_test.sh          # RISC-V system test (future)
    └── run_x86_test.sh            # x86 system test (future)
```

## SystemC Bridge Components

### 1. QemuSystemCBridge Class

The main bridge class that interfaces between QEMU and the SystemC model:

- **Network Server**: Listens for QEMU connections on configurable port
- **Protocol Handler**: Processes memory read/write requests from QEMU
- **SystemC Interface**: Translates requests to AXI transactions
- **Statistics**: Tracks performance and error metrics

### 2. WhitneySystemCServer Class

Standalone server application with command-line interface:

```bash
./whitney_systemc_server [OPTIONS]

Options:
  -p, --port PORT          Server port (default: 8888)
  -m, --memory-size SIZE   Memory size in MB (default: 1024)
  -a, --arch ARCH          Target architecture (default: arm64)
  -t, --trace-file FILE    VCD trace file (default: none)
  -v, --verbose            Verbose output
  -h, --help               Show help
```

### 3. Communication Protocol

The bridge uses a custom protocol for QEMU-SystemC communication:

#### Message Types:
- `MSG_INIT_REQUEST/RESPONSE`: System initialization
- `MSG_READ_REQUEST/RESPONSE`: Memory read operations
- `MSG_WRITE_REQUEST/RESPONSE`: Memory write operations
- `MSG_STATUS_REQUEST/RESPONSE`: System status queries
- `MSG_SHUTDOWN`: Graceful shutdown

#### Message Format:
```cpp
struct MessageHeader {
    uint32_t type;           // Message type
    uint32_t length;         // Data length
    uint64_t transaction_id; // Unique transaction ID
    uint64_t timestamp;      // Timestamp
};
```

## Usage Examples

### Basic ARM64 System Test

```bash
# 1. Start SystemC server
./whitney_systemc_server --port 8888 --memory-size 2048 --arch arm64 &

# 2. Run QEMU (conceptual - requires SystemC backend support)
qemu-system-aarch64 \
  -M virt \
  -cpu cortex-a57 \
  -m 2G \
  -object memory-backend-systemc,id=mem0,size=2G,server=localhost:8888 \
  -numa node,memdev=mem0 \
  -kernel vmlinux \
  -append "console=ttyAMA0 root=/dev/ram0" \
  -nographic

# 3. Monitor SystemC server
./test_client --server localhost:8888 --test performance
```

### RISC-V System Test

```bash
# SystemC server for RISC-V
./whitney_systemc_server --port 8889 --arch riscv64 --memory-size 4096 &

# QEMU RISC-V (conceptual)
qemu-system-riscv64 \
  -M virt \
  -cpu rv64 \
  -m 4G \
  -object memory-backend-systemc,id=mem0,size=4G,server=localhost:8889 \
  -numa node,memdev=mem0 \
  -kernel bbl \
  -append "console=ttyS0 root=/dev/ram0" \
  -nographic
```

### x86 System Test

```bash
# SystemC server for x86
./whitney_systemc_server --port 8890 --arch x86_64 --memory-size 8192 &

# QEMU x86 (conceptual)
qemu-system-x86_64 \
  -M pc \
  -cpu host \
  -m 8G \
  -object memory-backend-systemc,id=mem0,size=8G,server=localhost:8890 \
  -numa node,memdev=mem0 \
  -kernel bzImage \
  -append "console=ttyS0 root=/dev/ram0" \
  -nographic
```

## Performance Considerations

### Expected Performance Impact

| Metric | Native QEMU | With SystemC Bridge | Overhead |
|--------|-------------|---------------------|----------|
| Memory Latency | ~100ns | ~10-50μs | 100-500x |
| Memory Bandwidth | ~10 GB/s | ~100-500 MB/s | 20-100x |
| CPU Performance | Baseline | 10-50% slower | Variable |

### Optimization Strategies

1. **Batch Operations**: Group multiple memory accesses
2. **Caching**: Implement intelligent caching in the bridge
3. **Asynchronous I/O**: Non-blocking communication
4. **Memory Mapping**: Direct memory mapping where possible
5. **Protocol Optimization**: Reduce protocol overhead

## Testing and Validation

### Test Suite

The integration includes comprehensive testing:

```bash
# Build and run all tests
make test

# Performance testing
make perf-test

# Memory leak testing
make mem-test

# Static analysis
make lint
```

### Test Scenarios

1. **Basic Functionality**: Read/write operations, initialization
2. **Performance Testing**: Sustained memory traffic, bandwidth measurement
3. **Error Handling**: Invalid addresses, connection failures
4. **Stress Testing**: High-frequency operations, concurrent access
5. **System Integration**: Full OS boot, application workloads

### Validation Results

The bridge has been validated to provide:

✅ **Functional Correctness**: All memory operations work correctly
✅ **Protocol Compliance**: Proper message handling and error recovery
✅ **Performance Predictability**: Consistent latency and bandwidth
✅ **Stability**: Long-running tests without crashes or leaks

## Debugging and Analysis

### Debug Features

- **Verbose Logging**: Detailed operation logging
- **Transaction Tracing**: Complete transaction history
- **Performance Counters**: Real-time performance monitoring
- **Error Reporting**: Comprehensive error detection and reporting

### Analysis Tools

```bash
# Monitor server status
./test_client --server localhost:8888 --test status

# Generate performance report
./whitney_systemc_server --port 8888 --profile --profile-file perf.json

# Collect memory traces
./whitney_systemc_server --port 8888 --trace-file memory.vcd
```

### Common Issues and Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| Connection Refused | Server not running | Start SystemC server first |
| Memory Size Mismatch | QEMU/SystemC size differ | Ensure sizes match exactly |
| Performance Issues | Network latency | Use localhost, optimize batch size |
| Timing Violations | High traffic load | Reduce traffic or increase timeouts |

## Integration with QEMU

### Current Status

The current implementation provides:
- ✅ SystemC bridge server
- ✅ Communication protocol
- ✅ Test framework
- ⏳ QEMU memory backend plugin (conceptual)

### QEMU Memory Backend Plugin

To fully integrate with QEMU, a memory backend plugin is needed:

```c
// Conceptual QEMU plugin structure
typedef struct SystemCMemoryBackend {
    HostMemoryBackend parent;
    char *server_address;
    int server_port;
    int socket_fd;
} SystemCMemoryBackend;

// Plugin registration
static void systemc_memory_backend_class_init(ObjectClass *oc, void *data) {
    HostMemoryBackendClass *bc = MEMORY_BACKEND_CLASS(oc);
    bc->alloc = systemc_memory_backend_alloc;
}
```

### Future Enhancements

1. **QEMU Plugin Development**: Complete QEMU memory backend plugin
2. **Shared Memory**: High-performance shared memory interface
3. **Hardware Acceleration**: FPGA-based acceleration
4. **Multi-threading**: Parallel SystemC execution
5. **Advanced Caching**: Intelligent caching strategies

## System Requirements

### Software Dependencies

- **SystemC**: Version 2.3.3 or later
- **C++ Compiler**: GCC 7+ or Clang 6+ with C++17 support
- **QEMU**: Version 5.0+ (for future integration)
- **Build Tools**: Make, CMake (optional)

### Hardware Requirements

- **CPU**: Multi-core processor (4+ cores recommended)
- **Memory**: 8GB+ RAM (for large memory models)
- **Storage**: 1GB+ free space
- **Network**: Localhost communication (no external network required)

## Installation

### Prerequisites

```bash
# Install SystemC (if not already installed)
wget https://www.accellera.org/images/downloads/standards/systemc/systemc-2.3.3.tar.gz
tar -xzf systemc-2.3.3.tar.gz
cd systemc-2.3.3
mkdir build && cd build
../configure --prefix=/opt/systemc-2.3.3
make && sudo make install

# Install QEMU
sudo apt-get update
sudo apt-get install qemu-system-arm qemu-system-misc qemu-utils
```

### Build and Install

```bash
# Clone and build
cd systemc/qemu_integration/systemc_bridge
export SYSTEMC_HOME=/opt/systemc-2.3.3
make all

# Install to user bin
make install

# Verify installation
whitney_systemc_server --help
```

## Troubleshooting

### Build Issues

```bash
# SystemC not found
export SYSTEMC_HOME=/path/to/systemc
export LD_LIBRARY_PATH=$SYSTEMC_HOME/lib-linux64:$LD_LIBRARY_PATH

# Compiler errors
make clean && make debug

# Missing dependencies
sudo apt-get install build-essential libsystemc-dev
```

### Runtime Issues

```bash
# Port already in use
netstat -tulpn | grep 8888
killall whitney_systemc_server

# Permission denied
sudo sysctl net.ipv4.ip_local_port_range="1024 65535"

# Memory allocation errors
ulimit -v unlimited
```

## Contributing

### Development Workflow

1. Fork the repository
2. Create feature branch
3. Implement changes
4. Add tests
5. Submit pull request

### Coding Standards

- **C++ Standard**: C++17
- **Style**: Google C++ Style Guide
- **Documentation**: Doxygen comments
- **Testing**: Unit tests for all features

## License

This project is licensed under the Apache License 2.0. See LICENSE file for details.

## Support

For questions and support:
- **Documentation**: This README and inline comments
- **Issues**: GitHub issue tracker
- **Discussions**: GitHub discussions
- **Email**: Contact project maintainers

## Conclusion

The QEMU-SystemC integration provides a powerful platform for system-level verification of LPDDR5 memory controllers. While there is a performance overhead, the ability to run real operating systems and applications with accurate memory modeling provides invaluable verification capabilities that cannot be achieved with traditional testbenches alone.

Key benefits:
- **Complete System Verification**: Test entire software stacks
- **Real Workload Analysis**: Understand actual application behavior
- **Driver Validation**: Test memory controller drivers
- **Performance Characterization**: Measure real-world performance impact
- **Power Analysis**: Estimate power consumption of real workloads

The combination of QEMU's system emulation capabilities with the Whitney LPDDR5 SystemC model's accurate memory modeling creates a comprehensive verification environment suitable for both functional verification and performance analysis.
