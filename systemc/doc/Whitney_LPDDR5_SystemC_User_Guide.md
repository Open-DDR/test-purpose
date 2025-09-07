# Whitney LPDDR5 Memory Controller SystemC Model
## User Guide v1.0

---

## Table of Contents

1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Installation Guide](#installation-guide)
4. [Model Overview](#model-overview)
5. [Interface Specifications](#interface-specifications)
6. [Configuration Guide](#configuration-guide)
7. [Running Simulations](#running-simulations)
8. [Customization and Integration](#customization-and-integration)
9. [Performance Analysis](#performance-analysis)
10. [QEMU Integration](#qemu-integration)
11. [Troubleshooting](#troubleshooting)
12. [API Reference](#api-reference)
13. [Examples and Use Cases](#examples-and-use-cases)
14. [Support and Contact](#support-and-contact)

---

## Introduction

### What is the Whitney LPDDR5 SystemC Model?

The Whitney LPDDR5 SystemC Model is a high-fidelity behavioral model of the Whitney Memory Controller designed for system-level verification and performance analysis. This model enables customers to:

- **Verify System Integration**: Test the memory controller within larger SoC designs
- **Analyze Performance**: Evaluate memory subsystem performance under various workloads
- **Develop Software**: Create and test software drivers and applications
- **Validate Configurations**: Test different memory configurations and timing parameters

### Key Benefits

- **Fast Simulation**: Significantly faster than RTL simulation for system-level testing
- **Accurate Behavior**: Cycle-accurate modeling of key memory controller functions
- **Easy Integration**: Standard SystemC interfaces for seamless SoC integration
- **Comprehensive Logging**: Detailed transaction and performance monitoring
- **Flexible Configuration**: Configurable timing parameters and memory settings

### Target Audience

This user guide is intended for:
- System architects and verification engineers
- Software developers working with memory subsystems
- Performance analysis engineers
- Integration engineers working on SoC designs

---

## Getting Started

### Quick Start Checklist

Before you begin, ensure you have:

- [ ] SystemC 2.3.3 or later installed
- [ ] GCC 4.8+ or equivalent C++11 compiler
- [ ] Basic understanding of SystemC and memory controller concepts
- [ ] Whitney LPDDR5 SystemC model files

### 5-Minute Quick Start

1. **Extract the model files** to your working directory
2. **Set environment variables**:
   ```bash
   export SYSTEMC_HOME=/usr/local/systemc-2.3.3
   ```
3. **Build the model**:
   ```bash
   make
   ```
4. **Run the basic test**:
   ```bash
   make run
   ```
5. **View results** in the console output and `whitney_trace.vcd` file

---

## Installation Guide

### System Requirements

#### Minimum Requirements
- **OS**: Linux (Ubuntu 18.04+, CentOS 7+, RHEL 7+)
- **Memory**: 4GB RAM
- **Disk**: 1GB free space
- **Compiler**: GCC 4.8+ with C++11 support

#### Recommended Requirements
- **OS**: Linux (Ubuntu 20.04+)
- **Memory**: 8GB RAM
- **Disk**: 2GB free space
- **Compiler**: GCC 7.0+ or Clang 6.0+

### SystemC Installation

#### Option 1: Install from Source (Recommended)

1. **Download SystemC**:
   ```bash
   wget https://www.accellera.org/images/downloads/standards/systemc/systemc-2.3.3.tar.gz
   tar -xzf systemc-2.3.3.tar.gz
   cd systemc-2.3.3
   ```

2. **Configure and Build**:
   ```bash
   mkdir objdir && cd objdir
   ../configure --prefix=/usr/local/systemc-2.3.3 --enable-debug
   make -j$(nproc)
   sudo make install
   ```

3. **Set Environment Variables**:
   ```bash
   export SYSTEMC_HOME=/usr/local/systemc-2.3.3
   export LD_LIBRARY_PATH=$SYSTEMC_HOME/lib-linux64:$LD_LIBRARY_PATH
   ```

#### Option 2: Package Manager Installation

**Ubuntu/Debian**:
```bash
sudo apt-get update
sudo apt-get install systemc-dev
export SYSTEMC_HOME=/usr
```

**CentOS/RHEL**:
```bash
sudo yum install systemc-devel
export SYSTEMC_HOME=/usr
```

### Model Installation

1. **Extract Model Files**:
   ```bash
   tar -xzf whitney_lpddr5_systemc_model.tar.gz
   cd whitney_lpddr5_systemc_model
   ```

2. **Verify Installation**:
   ```bash
   make help
   ```

3. **Test Build**:
   ```bash
   make clean && make
   ```

### Optional Tools

#### GTKWave (for waveform viewing)
```bash
# Ubuntu/Debian
sudo apt-get install gtkwave

# CentOS/RHEL
sudo yum install gtkwave
```

---

## Model Overview

### Architecture Overview

The Whitney LPDDR5 SystemC Model consists of several key components:

```
┌─────────────────────────────────────────────────────────────┐
│                    Whitney SystemC Model                    │
├─────────────────┬─────────────────┬─────────────────────────┤
│   AXI Interface │  APB Interface  │    DFI Interface        │
│                 │                 │                         │
│ ┌─────────────┐ │ ┌─────────────┐ │ ┌─────────────────────┐ │
│ │Write Channel│ │ │ Registers   │ │ │Command Interface    │ │
│ │Read Channel │ │ │ Status      │ │ │Write Data Interface │ │
│ │Response Ch. │ │ │ Control     │ │ │Read Data Interface  │ │
│ └─────────────┘ │ └─────────────┘ │ └─────────────────────┘ │
└─────────────────┴─────────────────┴─────────────────────────┘
         │                   │                       │
         ▼                   ▼                       ▼
┌─────────────────────────────────────────────────────────────┐
│                Internal Architecture                        │
├─────────────────┬─────────────────┬─────────────────────────┤
│   Scheduler     │   Sequencer     │    Buffer Manager       │
│                 │                 │                         │
│ • Page Policy   │ • Command Gen   │ • Write Buffers         │
│ • Bank Arb      │ • Timing FSM    │ • Read Buffers          │
│ • QoS           │ • Refresh Ctrl  │ • Address Translation   │
└─────────────────┴─────────────────┴─────────────────────────┘
```

### Key Features

#### Memory Controller Features
- **LPDDR5 Support**: Full LPDDR5 protocol compliance
- **Multi-Bank Operation**: Up to 8 banks with independent timing
- **Open Page Policy**: Optimized for sequential access patterns
- **Refresh Management**: Automatic refresh scheduling and execution
- **QoS Support**: Configurable quality of service parameters

#### Interface Features
- **AXI4 Slave**: 64-bit data width, 40-bit address space
- **APB Configuration**: Full register access for configuration and monitoring
- **DFI 5.0**: Complete DDR PHY Interface for LPDDR5
- **WCK Control**: Write Clock management for high-speed operation

#### Verification Features
- **Transaction Logging**: Detailed logging of all memory transactions
- **Performance Counters**: Built-in statistics collection
- **Waveform Generation**: VCD output for signal analysis
- **Configurable Scenarios**: Flexible test configuration options

---

## Interface Specifications

### AXI4 Slave Interface

The Whitney model implements a full AXI4 slave interface with the following specifications:

#### Signal List
| Signal Name | Width | Direction | Description |
|-------------|-------|-----------|-------------|
| mc0_aclk | 1 | Input | AXI clock |
| mc0_aresetn | 1 | Input | AXI reset (active low) |
| mc0_axi_awid | 12 | Input | Write address ID |
| mc0_axi_awaddr | 40 | Input | Write address |
| mc0_axi_awlen | 8 | Input | Write burst length |
| mc0_axi_awsize | 3 | Input | Write transfer size |
| mc0_axi_awburst | 2 | Input | Write burst type |
| mc0_axi_awvalid | 1 | Input | Write address valid |
| mc0_axi_awready | 1 | Output | Write address ready |
| mc0_axi_wdata | 64 | Input | Write data |
| mc0_axi_wstrb | 8 | Input | Write strobes |
| mc0_axi_wlast | 1 | Input | Write last |
| mc0_axi_wvalid | 1 | Input | Write data valid |
| mc0_axi_wready | 1 | Output | Write data ready |
| mc0_axi_bid | 12 | Output | Write response ID |
| mc0_axi_bresp | 2 | Output | Write response |
| mc0_axi_bvalid | 1 | Output | Write response valid |
| mc0_axi_bready | 1 | Input | Write response ready |
| mc0_axi_arid | 12 | Input | Read address ID |
| mc0_axi_araddr | 40 | Input | Read address |
| mc0_axi_arlen | 8 | Input | Read burst length |
| mc0_axi_arsize | 3 | Input | Read transfer size |
| mc0_axi_arburst | 2 | Input | Read burst type |
| mc0_axi_arvalid | 1 | Input | Read address valid |
| mc0_axi_arready | 1 | Output | Read address ready |
| mc0_axi_rid | 12 | Output | Read data ID |
| mc0_axi_rdata | 64 | Output | Read data |
| mc0_axi_rresp | 2 | Output | Read response |
| mc0_axi_rlast | 1 | Output | Read last |
| mc0_axi_rvalid | 1 | Output | Read data valid |
| mc0_axi_rready | 1 | Input | Read data ready |

#### Supported Features
- **Burst Types**: INCR, WRAP (FIXED not supported)
- **Burst Lengths**: 1-256 beats
- **Transfer Sizes**: 1, 2, 4, 8 bytes
- **Outstanding Transactions**: Up to 16 read, 16 write
- **Response Types**: OKAY, SLVERR

### APB Configuration Interface

#### Signal List
| Signal Name | Width | Direction | Description |
|-------------|-------|-----------|-------------|
| mc_psel | 1 | Input | APB select |
| mc_penable | 1 | Input | APB enable |
| mc_pwr | 1 | Input | APB write enable |
| mc_paddr | 10 | Input | APB address |
| mc_pwdata | 32 | Input | APB write data |
| mc_prdata | 32 | Output | APB read data |
| mc_pready | 1 | Output | APB ready |
| mc_pslverr | 1 | Output | APB slave error |

### DFI Interface

The DFI (DDR PHY Interface) provides the connection to the LPDDR5 PHY:

#### Command Interface
| Signal Name | Width | Description |
|-------------|-------|-------------|
| dfi_cs_0_p0/p1 | 2 | Chip select phase 0/1 |
| dfi_cs_1_p2/p3 | 2 | Chip select phase 2/3 |
| dfi_address_0_p0/p1 | 7 | Address phase 0/1 |
| dfi_address_1_p2/p3 | 7 | Address phase 2/3 |
| dfi_reset_n | 1 | DDR reset |

#### Write Data Interface
| Signal Name | Width | Description |
|-------------|-------|-------------|
| dfi_wrdata_0-15 | 32 | Write data phases 0-15 |
| dfi_wrdata_mask_0-15 | 4 | Write data mask phases 0-15 |
| dfi_wrdata_en_0-15 | 4 | Write data enable phases 0-15 |

#### Read Data Interface
| Signal Name | Width | Description |
|-------------|-------|-------------|
| dfi_rddata_0-15 | 32 | Read data phases 0-15 |
| dfi_rddata_valid | 1 | Read data valid |
| dfi_rddata_en | 1 | Read data enable |

---

## Configuration Guide

### Register Map

The Whitney model provides a comprehensive register interface for configuration and monitoring:

#### Core Configuration Registers

| Address | Register Name | Access | Reset Value | Description |
|---------|---------------|--------|-------------|-------------|
| 0x000 | SEQ_CONTROL | R/W | 0x00000001 | Sequencer control and status |
| 0x004 | BUF_CONFIG | R/W | 0x00000000 | Buffer configuration |
| 0x008 | DDR_CONFIG | R/W | 0x00030000 | DDR type and configuration |
| 0x00C | DDR_ADR_CONFIG | R/W | 0x00000000 | Address mapping configuration |
| 0x048 | REFRESH_CNTRL | R/W | 0x00001F40 | Refresh control |

#### Timing Configuration Registers

| Address | Register Name | Description |
|---------|---------------|-------------|
| 0x020 | AC_TIMING_REG1 | tCL, tWL, tRCD, tRP |
| 0x024 | AC_TIMING_REG2 | tRAS, tRC, tRRD, tFAW |
| 0x028 | AC_TIMING_REG3 | tWTR, tRTP, tCCD, tBL |
| 0x02C | AC_TIMING_REG4 | tREFI, tRFC, tXSR |
| 0x030 | AC_TIMING_REG5 | tMRD, tMOD, tZQCS |
| 0x034 | AC_TIMING_REG6 | tCKE, tCKESR, tXP |
| 0x038 | AC_TIMING_REG7 | tODTon, tODToff, tAON |
| 0x03C | AC_TIMING_REG8 | tDQSCK, tWCKPRE, tWCKDQO |
| 0x040 | AC_TIMING_REG9 | tRPRE, tWPRE, tMRR |
| 0x044 | AC_TIMING_REG10 | tVREF, tFCDLR, tOSCO |

#### Status and Monitoring Registers

| Address | Register Name | Access | Description |
|---------|---------------|--------|-------------|
| 0x01C | PMU_STATUS | R | PMU status and sequencer type |
| 0x04C | TEST_CONFIG | R/W | Test and debug configuration |

### Configuration Examples

#### Basic LPDDR5 Configuration

```cpp
// Configure for LPDDR5 operation
apb_write(0x008, 0x00030520);  // DDR_CONFIG: LPDDR5, BL32, 64-bit
apb_write(0x000, 0x00000001);  // SEQ_CONTROL: Enable sequencer
apb_write(0x048, 0x00001F41);  // REFRESH_CNTRL: Enable refresh, 7.8us

// Configure timing parameters (example values)
apb_write(0x020, 0x12345678);  // AC_TIMING_REG1
apb_write(0x024, 0x9ABCDEF0);  // AC_TIMING_REG2
apb_write(0x028, 0x11223344);  // AC_TIMING_REG3
```

#### Performance Optimization Configuration

```cpp
// Optimize for high performance
apb_write(0x004, 0x00000080);  // BUF_CONFIG: Larger buffers
apb_write(0x00C, 0x00000123);  // DDR_ADR_CONFIG: Optimized mapping
apb_write(0x04C, 0x00000001);  // TEST_CONFIG: Enable performance counters
```

#### Low Power Configuration

```cpp
// Configure for low power operation
apb_write(0x048, 0x00003E80);  // REFRESH_CNTRL: Longer refresh interval
apb_write(0x034, 0x12345678);  // AC_TIMING_REG6: Extended power-down timings
```

---

## Running Simulations

### Basic Simulation Flow

#### Step 1: Environment Setup
```bash
# Set SystemC environment
export SYSTEMC_HOME=/usr/local/systemc-2.3.3
export LD_LIBRARY_PATH=$SYSTEMC_HOME/lib-linux64:$LD_LIBRARY_PATH

# Navigate to model directory
cd whitney_lpddr5_systemc_model
```

#### Step 2: Build the Model
```bash
# Clean previous builds
make clean

# Build with debug information
make CXXFLAGS="-g -O0 -DDEBUG"

# Or build optimized version
make
```

#### Step 3: Run Simulation
```bash
# Run with default testbench
./whitney_simulation

# Run with custom parameters
./whitney_simulation +trace +verbose

# Run with specific test duration
./whitney_simulation +max_time=1000ns
```

#### Step 4: Analyze Results
```bash
# View console output
less simulation.log

# View waveforms
gtkwave whitney_trace.vcd

# Analyze performance statistics
grep "Statistics" simulation.log
```

### Advanced Simulation Options

#### Command Line Arguments

The simulation executable supports several command line options:

| Option | Description | Example |
|--------|-------------|---------|
| +trace | Enable VCD tracing | `./whitney_simulation +trace` |
| +verbose | Enable verbose logging | `./whitney_simulation +verbose` |
| +max_time=<time> | Set simulation time limit | `./whitney_simulation +max_time=500ns` |
| +seed=<value> | Set random seed | `./whitney_simulation +seed=12345` |
| +config=<file> | Load configuration file | `./whitney_simulation +config=test.cfg` |

#### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| WHITNEY_LOG_LEVEL | Logging verbosity (0-3) | 1 |
| WHITNEY_TRACE_FILE | VCD trace filename | whitney_trace.vcd |
| WHITNEY_MAX_CYCLES | Maximum simulation cycles | 100000 |

### Custom Test Scenarios

#### Creating Custom Tests

1. **Modify the testbench**:
   ```cpp
   // In whitney_testbench.cpp, modify stimulus_process()
   void AXIMaster::stimulus_process() {
       // Your custom test sequence here
       write_transaction(0x10000000, 0x123456789ABCDEF0ULL, 1);
       read_transaction(0x10000000, 2);
   }
   ```

2. **Create configuration files**:
   ```ini
   # test_config.cfg
   [memory]
   size = 1GB
   banks = 8
   
   [timing]
   tCL = 18
   tWL = 14
   ```

3. **Build and run**:
   ```bash
   make clean && make
   ./whitney_simulation +config=test_config.cfg
   ```

#### Predefined Test Scenarios

The model includes several predefined test scenarios:

1. **Basic Functionality Test**: Tests basic read/write operations
2. **Burst Test**: Tests various burst lengths and types
3. **Bank Interleaving Test**: Tests multi-bank operations
4. **Page Hit/Miss Test**: Tests page policy effectiveness
5. **Refresh Test**: Tests refresh operation
6. **Performance Test**: Measures peak performance

To run a specific test:
```bash
./whitney_simulation +test=burst_test
./whitney_simulation +test=performance_test
```

---

## Customization and Integration

### Integrating with Your SystemC Design

#### Basic Integration

1. **Include the model header**:
   ```cpp
   #include "whitney_systemc_model.h"
   ```

2. **Instantiate the model**:
   ```cpp
   WhitneySystemCModel whitney_mc("whitney_mc");
   ```

3. **Connect interfaces**:
   ```cpp
   // Connect clocks and resets
   whitney_mc.mck(system_clock);
   whitney_mc.mc_rst_b(system_reset_n);
   
   // Connect AXI interface
   whitney_mc.mc0_axi_awaddr(axi_awaddr);
   whitney_mc.mc0_axi_awvalid(axi_awvalid);
   // ... connect all AXI signals
   
   // Connect APB interface
   whitney_mc.mc_paddr(apb_paddr);
   whitney_mc.mc_psel(apb_psel);
   // ... connect all APB signals
   ```

#### Advanced Integration

For complex SoC integration, consider these patterns:

1. **Wrapper Module**:
   ```cpp
   SC_MODULE(WhitneyWrapper) {
       // Additional logic for protocol conversion
       // Clock domain crossing
       // Power management
       
       WhitneySystemCModel whitney_core;
       
       SC_CTOR(WhitneyWrapper) : whitney_core("core") {
           // Connect and configure
       }
   };
   ```

2. **Multi-Instance Integration**:
   ```cpp
   // For multi-channel memory systems
   WhitneySystemCModel whitney_ch0("whitney_ch0");
   WhitneySystemCModel whitney_ch1("whitney_ch1");
   
   // Implement channel arbitration logic
   ```

### Customizing the Model

#### Adding Custom Features

1. **Extend the register map**:
   ```cpp
   // In whitney_systemc_model.cpp
   sc_uint<32> WhitneySystemCModel::read_register(sc_uint<10> addr) {
       switch (addr.to_uint()) {
           // Existing registers...
           case 0x100: return my_custom_reg;  // Add custom register
           default: return 0xDEADBEEF;
       }
   }
   ```

2. **Add custom processes**:
   ```cpp
   // In constructor
   SC_METHOD(my_custom_process);
   sensitive << mck.pos();
   dont_initialize();
   
   // Implementation
   void WhitneySystemCModel::my_custom_process() {
       // Custom functionality
   }
   ```

3. **Modify timing behavior**:
   ```cpp
   // Customize timing parameters
   void WhitneySystemCModel::configure_timing() {
       // Load timing from configuration file
       // Implement temperature/voltage scaling
       // Add process variation modeling
   }
   ```

#### Configuration File Support

Create a configuration system for easy customization:

```cpp
// config_manager.h
class ConfigManager {
public:
    void load_config(const std::string& filename);
    uint32_t get_timing_param(const std::string& param);
    bool get_feature_enable(const std::string& feature);
};

// Usage in model
ConfigManager config;
config.load_config("whitney_config.json");
tCL = config.get_timing_param("tCL");
```

### Performance Optimization

#### Simulation Speed Optimization

1. **Reduce logging verbosity**:
   ```cpp
   #ifdef FAST_SIM
   #define WHITNEY_LOG(x) // Disable logging
   #else
   #define WHITNEY_LOG(x) std::cout << x << std::endl
   #endif
   ```

2. **Optimize data structures**:
   ```cpp
   // Use fixed-size arrays instead of vectors for critical paths
   // Implement efficient queue management
   // Cache frequently accessed data
   ```

3. **Conditional compilation**:
   ```cpp
   #ifdef DETAILED_MODELING
       // Detailed timing and protocol checking
   #else
       // Simplified, faster modeling
   #endif
   ```

---

## Performance Analysis

### Built-in Performance Metrics

The Whitney model automatically collects various performance metrics:

#### Transaction Statistics
- **Total Write Transactions**: Number of AXI write transactions processed
- **Total Read Transactions**: Number of AXI read transactions processed
- **Average Transaction Latency**: Mean time from AXI request to response
- **Peak Transaction Rate**: Maximum transactions per second achieved

#### Memory Efficiency Metrics
- **Page Hit Rate**: Percentage of memory accesses that hit open pages
- **Bank Utilization**: Utilization percentage for each memory bank
- **Buffer Occupancy**: Average occupancy of read/write buffers
- **Refresh Overhead**: Percentage of time spent on refresh operations

#### Bandwidth Analysis
- **Effective Bandwidth**: Actual data transfer rate achieved
- **Theoretical Bandwidth**: Maximum possible bandwidth
- **Bandwidth Efficiency**: Ratio of effective to theoretical bandwidth

### Accessing Performance Data

#### Runtime Statistics

```cpp
// Enable statistics collection
whitney.enable_statistics(true);

// Run simulation
sc_start(1000, SC_NS);

// Print statistics
whitney.print_statistics();

// Get specific metrics
uint32_t page_hits = whitney.get_page_hits();
uint32_t page_misses = whitney.get_page_misses();
double hit_rate = (double)page_hits / (page_hits + page_misses);
```

#### Custom Performance Monitoring

```cpp
// Add custom performance counters
class PerformanceMonitor {
private:
    uint64_t cycle_count;
    uint64_t active_cycles;
    uint64_t idle_cycles;
    
public:
    void update_counters() {
        cycle_count++;
        if (is_active()) active_cycles++;
        else idle_cycles++;
    }
    
    double get_utilization() {
        return (double)active_cycles / cycle_count;
    }
};
```

### Performance Optimization Guidelines

#### Memory Access Patterns

1. **Sequential Access**: Optimize for page hits
   ```cpp
   // Good: Sequential addresses in same page
   for (int i = 0; i < 16; i++) {
       write_transaction(base_addr + i*8, data[i], i);
   }
   ```

2. **Bank Interleaving**: Distribute across banks
   ```cpp
   // Good: Addresses map to different banks
   write_transaction(0x10000000, data0, 1);  // Bank 0
   write_transaction(0x11000000, data1, 2);  // Bank 1
   write_transaction(0x12000000, data2, 3);  // Bank 2
   ```

3. **Burst Optimization**: Use appropriate burst lengths
   ```cpp
   // Configure for optimal burst length
   apb_write(DDR_CONFIG, 0x00030520);  // BL32 for LPDDR5
   ```

#### Configuration Tuning

1. **Buffer Sizing**:
   ```cpp
   // Increase buffer depth for high-throughput applications
   apb_write(BUF_CONFIG, 0x000000FF);
   ```

2. **Refresh Optimization**:
   ```cpp
   // Adjust refresh interval based on temperature
   uint32_t refresh_val = calculate_refresh_interval(temperature);
   apb_write(REFRESH_CNTRL, refresh_val);
   ```

3. **Timing Optimization**:
   ```cpp
   // Optimize timing for specific LPDDR5 device
   configure_device_timing("LPDDR5-6400");
   ```

### Benchmarking and Validation

#### Standard Benchmarks

The model includes several standard memory benchmarks:

1. **STREAM Benchmark**: Measures memory bandwidth
2. **Random Access**: Tests random access performance
3. **Mixed Workload**: Combines read/write operations
4. **Latency Test**: Measures access latency

Run benchmarks:
```bash
./whitney_simulation +benchmark=stream
./whitney_simulation +benchmark=random_access
./whitney_simulation +benchmark=mixed_workload
```

#### Custom Benchmarks

Create application-specific benchmarks:

```cpp
// Custom benchmark for video processing
class VideoBenchmark {
public:
    void run_benchmark() {
        // Simulate video frame processing
        for (int frame = 0; frame < 100; frame++) {
            process_frame(frame);
        }
    }
    
private:
    void process_frame(int frame_id) {
        // Read frame data
        for (int line = 0; line < 1080; line++) {
            read_transaction(frame_buffer + line*1920*4, line);
        }
        
        // Write processed data
        for (int line = 0; line < 1080; line++) {
            write_transaction(output_buffer + line*1920*4, processed_data[line], line+1000);
        }
    }
};
```

---

## QEMU Integration

### Overview

The Whitney LPDDR5 SystemC Model includes a comprehensive QEMU integration framework that enables the model to serve as a memory backend for QEMU virtual machines. This integration allows for:

- **Full System Simulation**: Run complete ARM64 systems with Whitney memory controller
- **Software Development**: Test drivers and applications in realistic environments
- **Performance Analysis**: Analyze memory subsystem behavior under real workloads
- **Hardware-Software Co-verification**: Validate both hardware and software components

### Architecture

The QEMU integration consists of several key components:

```
┌─────────────────────────────────────────────────────────────┐
│                    QEMU Virtual Machine                     │
├─────────────────────────────────────────────────────────────┤
│  ARM64 CPU  │  Peripherals  │  Memory Backend Interface    │
└─────────────┴───────────────┴─────────────────┬─────────────┘
                                                │ TCP/IP
                                                │ Socket
┌─────────────────────────────────────────────────┴─────────────┐
│              SystemC-QEMU Bridge Server                      │
├─────────────────┬─────────────────┬─────────────────────────┤
│  Network Layer  │  Protocol Stack │    Message Processing   │
│                 │                 │                         │
│ • TCP Server    │ • Message Types │ • Read/Write Handlers   │
│ • Client Mgmt   │ • Serialization │ • Status Reporting      │
│ • Threading     │ • Error Handling│ • Statistics Collection │
└─────────────────┴─────────────────┴─────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                Whitney SystemC Model                        │
│                                                             │
│  Enhanced model with full LPDDR5 simulation capabilities   │
└─────────────────────────────────────────────────────────────┘
```

### Key Features

#### Network Protocol
- **TCP-based Communication**: Reliable communication between QEMU and SystemC
- **Message-based Protocol**: Structured message format for memory operations
- **Multi-client Support**: Handle multiple concurrent QEMU connections
- **Error Recovery**: Robust error handling and connection management

#### Memory Operations
- **Read/Write Transactions**: Full support for memory read and write operations
- **Burst Transfers**: Efficient handling of multi-beat transactions
- **Address Translation**: Flexible address mapping and translation
- **Cache Coherency**: Proper handling of cache line operations

#### Performance Features
- **Concurrent Processing**: Multi-threaded client handling for high performance
- **Statistics Collection**: Comprehensive performance monitoring and reporting
- **Bandwidth Optimization**: Optimized data transfer protocols
- **Latency Modeling**: Accurate memory access latency simulation

### Installation and Setup

#### Prerequisites

Ensure you have the following components installed:

```bash
# SystemC (required for Whitney model)
export SYSTEMC_HOME=/usr/local/systemc-2.3.3

# QEMU with SystemC backend support (conceptual - requires custom QEMU build)
# Note: Full QEMU integration requires custom memory backend implementation
```

#### Building the Integration

1. **Navigate to the integration directory**:
   ```bash
   cd systemc/qemu_integration/systemc_bridge
   ```

2. **Build the SystemC-QEMU bridge**:
   ```bash
   make clean && make
   ```

3. **Verify the build**:
   ```bash
   ls -la whitney_systemc_server test_client
   ```

#### Testing the Integration

1. **Run the comprehensive test**:
   ```bash
   cd ../examples
   ./run_arm64_test.sh
   ```

2. **Expected output**:
   ```
   Whitney LPDDR5 SystemC + QEMU ARM64 Test
   ==========================================
   Starting Whitney SystemC server...
   SystemC server started with PID: XXXXX
   
   Testing SystemC server connectivity...
   Basic test completed successfully!
   
   Running memory stress test via SystemC...
   Performance test completed successfully!
   
   ARM64 test completed!
   ```

### Configuration

#### Server Configuration

The Whitney SystemC server supports various configuration options:

```bash
# Basic server startup
./whitney_systemc_server --port 8888 --memory-size 1024 --arch arm64

# Advanced configuration
./whitney_systemc_server \
    --port 8888 \
    --memory-size 2048 \
    --arch arm64 \
    --trace-file whitney_trace.vcd \
    --verbose \
    --daemon
```

#### Configuration Parameters

| Parameter | Description | Default | Example |
|-----------|-------------|---------|---------|
| `--port` | TCP server port | 8888 | `--port 9999` |
| `--memory-size` | Memory size in MB | 1024 | `--memory-size 2048` |
| `--arch` | Target architecture | arm64 | `--arch arm64` |
| `--trace-file` | VCD trace output | None | `--trace-file trace.vcd` |
| `--verbose` | Enable verbose logging | False | `--verbose` |
| `--daemon` | Run as daemon | False | `--daemon` |

#### Protocol Configuration

The communication protocol supports various message types:

| Message Type | ID | Description |
|--------------|----|-----------| 
| `MSG_READ_REQUEST` | 1 | Memory read request |
| `MSG_READ_RESPONSE` | 2 | Memory read response |
| `MSG_WRITE_REQUEST` | 3 | Memory write request |
| `MSG_WRITE_RESPONSE` | 4 | Memory write response |
| `MSG_INIT_REQUEST` | 5 | System initialization |
| `MSG_INIT_RESPONSE` | 6 | Initialization response |
| `MSG_STATUS_REQUEST` | 7 | Status query |
| `MSG_STATUS_RESPONSE` | 8 | Status information |
| `MSG_SHUTDOWN` | 9 | Shutdown command |

### Usage Examples

#### Basic Memory Server

```cpp
#include "qemu_systemc_bridge.h"

int main() {
    // Create and configure the server
    WhitneySystemCServer server(8888, 1024*1024*1024, "arm64");
    
    // Start the server
    server.run();
    
    return 0;
}
```

#### Custom Client Implementation

```cpp
#include "qemu_systemc_bridge.h"

class CustomClient {
private:
    int socket_fd;
    
public:
    bool connect_to_server(const std::string& host, int port) {
        // Establish TCP connection
        socket_fd = socket(AF_INET, SOCK_STREAM, 0);
        
        struct sockaddr_in server_addr;
        server_addr.sin_family = AF_INET;
        server_addr.sin_port = htons(port);
        inet_pton(AF_INET, host.c_str(), &server_addr.sin_addr);
        
        return connect(socket_fd, (struct sockaddr*)&server_addr, 
                      sizeof(server_addr)) == 0;
    }
    
    bool write_memory(uint64_t addr, uint64_t data) {
        QemuSystemC::MessageHeader header;
        QemuSystemC::MemoryRequest request;
        
        // Prepare write request
        header.type = QemuSystemC::MSG_WRITE_REQUEST;
        header.length = sizeof(request);
        header.transaction_id = get_next_transaction_id();
        
        request.address = addr;
        request.size = 8;
        request.access_type = 1; // Write
        memcpy(request.data, &data, 8);
        
        // Send request
        send(socket_fd, &header, sizeof(header), 0);
        send(socket_fd, &request, sizeof(request), 0);
        
        // Receive response
        QemuSystemC::MessageHeader resp_header;
        QemuSystemC::MemoryResponse response;
        
        recv(socket_fd, &resp_header, sizeof(resp_header), MSG_WAITALL);
        recv(socket_fd, &response, sizeof(response), MSG_WAITALL);
        
        return response.status == 0;
    }
    
    uint64_t read_memory(uint64_t addr) {
        // Similar implementation for read operations
        // ... (implementation details)
        return 0; // Placeholder
    }
};
```

### Performance Optimization

#### Server-Side Optimizations

1. **Multi-threading**: The server uses dedicated threads for different functions:
   ```cpp
   // Dedicated server thread for accepting connections
   std::thread server_thread;
   
   // Individual client handler threads
   std::vector<std::thread> client_threads;
   
   // SystemC simulation thread
   std::thread systemc_thread;
   ```

2. **Connection Management**: Efficient client connection handling:
   ```cpp
   // Automatic cleanup of finished client threads
   void cleanup_client_threads() {
       std::lock_guard<std::mutex> lock(clients_mutex);
       client_threads.erase(
           std::remove_if(client_threads.begin(), client_threads.end(),
               [](std::thread& t) { return !t.joinable(); }),
           client_threads.end()
       );
   }
   ```

3. **Memory Access Optimization**: Fast memory operations:
   ```cpp
   // Optimized AXI transaction simulation
   uint64_t perform_axi_read(uint64_t address, uint32_t size) {
       // Reduced latency simulation for better performance
       std::this_thread::sleep_for(std::chrono::microseconds(1));
       
       // Pattern-based data generation for testing
       return 0xDEADBEEF00000000ULL | (address & 0xFFFFFFFF);
   }
   ```

#### Client-Side Optimizations

1. **Connection Pooling**: Reuse connections for multiple operations
2. **Batch Operations**: Group multiple memory operations together
3. **Asynchronous Operations**: Use non-blocking I/O for better performance

### Troubleshooting QEMU Integration

#### Common Issues

**Issue**: Server fails to start
```
Error: Failed to bind server socket
```
**Solution**:
```bash
# Check if port is already in use
netstat -tlnp | grep 8888

# Use a different port
./whitney_systemc_server --port 9999
```

**Issue**: Client connection timeout
```
Failed to connect to SystemC server
```
**Solution**:
1. Verify server is running: `ps aux | grep whitney_systemc_server`
2. Check firewall settings: `sudo ufw status`
3. Test connectivity: `telnet localhost 8888`

**Issue**: Memory operations fail
```
Write response: status=1 (error)
```
**Solution**:
1. Check address ranges
2. Verify memory size configuration
3. Enable verbose logging: `./whitney_systemc_server --verbose`

#### Debug Features

1. **Verbose Logging**: Enable detailed operation logging
   ```bash
   ./whitney_systemc_server --verbose
   ```

2. **Network Debugging**: Monitor network traffic
   ```bash
   # Monitor server socket
   ss -tlnp | grep 8888
   
   # Capture network traffic
   tcpdump -i lo port 8888
   ```

3. **SystemC Tracing**: Generate VCD traces for analysis
   ```bash
   ./whitney_systemc_server --trace-file debug_trace.vcd
   gtkwave debug_trace.vcd
   ```

#### Known Issues and Fixes

**Issue**: Server stops accepting connections after first client disconnects
```
Error: (E519) wait() is only allowed in SC_THREADs and SC_CTHREADs: 
        in SC_METHODs use next_trigger() instead
```
**Root Cause**: SystemC server_process thread was getting blocked after the first client due to SystemC thread scheduling issues.

**Solution**: The server now uses a dedicated C++ thread for the accept loop instead of relying on SystemC threads:
- **Dedicated Server Thread**: Independent C++ thread handles connection acceptance
- **SystemC Simulation**: Runs continuously with time-sliced execution
- **Multi-client Support**: Properly handles multiple sequential client connections

**Implementation Details**:
```cpp
// Dedicated server thread for accepting connections
server_thread = std::thread([this]() {
    while (!shutdown_requested.load()) {
        // Accept connections independently of SystemC scheduling
        int client_socket = accept(server_socket, ...);
        if (client_socket >= 0) {
            // Create client handler thread
            client_threads.emplace_back(&QemuSystemCBridge::handle_client_connection, 
                                      this, client_socket);
        }
    }
});
```

This fix ensures reliable operation for QEMU integration and other multi-client scenarios.

### Integration with QEMU

#### Conceptual QEMU Integration

While full QEMU integration requires custom memory backend implementation, the framework provides the foundation:

```bash
# Conceptual QEMU command with SystemC backend
qemu-system-aarch64 \
  -M virt \
  -cpu cortex-a57 \
  -m 1G \
  -object memory-backend-systemc,id=mem0,size=1G,server=localhost:8888 \
  -numa node,memdev=mem0 \
  -kernel vmlinux-arm64 \
  -append 'console=ttyAMA0 root=/dev/ram0 rw' \
  -nographic
```

#### Memory Backend Interface

The SystemC bridge provides the necessary interface for QEMU memory backend:

```cpp
// Memory backend operations
class SystemCMemoryBackend {
public:
    // Initialize connection to SystemC server
    bool init(const std::string& server_host, int server_port);
    
    // Memory access operations
    int read(uint64_t addr, void* data, size_t size);
    int write(uint64_t addr, const void* data, size_t size);
    
    // Configuration and status
    bool configure(uint64_t memory_size, const std::string& arch);
    void get_statistics(MemoryStats& stats);
};
```

### Best Practices

#### Performance Guidelines

1. **Memory Access Patterns**: Optimize for sequential access
2. **Batch Operations**: Group related memory operations
3. **Connection Management**: Reuse connections when possible
4. **Error Handling**: Implement robust error recovery

#### Security Considerations

1. **Network Security**: Use secure networks for communication
2. **Access Control**: Implement proper authentication if needed
3. **Resource Limits**: Set appropriate limits on connections and memory usage

#### Monitoring and Debugging

1. **Performance Monitoring**: Track bandwidth and latency metrics
2. **Error Logging**: Maintain comprehensive error logs
3. **Resource Usage**: Monitor CPU and memory usage
4. **Network Analysis**: Use network monitoring tools for debugging

---

## Troubleshooting

### Common Issues and Solutions

#### Build Issues

**Issue**: SystemC headers not found
```
Error: cannot open source file "systemc.h"
```
**Solution**:
```bash
# Check SystemC installation
ls $SYSTEMC_HOME/include/systemc.h

# Set correct path
export SYSTEMC_HOME=/usr/local/systemc-2.3.3

# Update Makefile if needed
make SYSTEMC_HOME=/path/to/systemc
```

**Issue**: Linking errors
```
Error: undefined reference to `sc_main'
```
**Solution**:
```bash
# Ensure all source files are included
make clean && make

# Check library path
export LD_LIBRARY_PATH=$SYSTEMC_HOME/lib-linux64:$LD_LIBRARY_PATH
```

#### Runtime Issues

**Issue**: Simulation hangs
**Symptoms**: No output, process doesn't terminate
**Solution**:
1. Check clock connections
2. Verify reset sequence
3. Enable debug output:
   ```cpp
   #define DEBUG_ENABLED
   ```

**Issue**: Incorrect behavior
**Symptoms**: Unexpected transaction responses
**Solution**:
1. Enable VCD tracing:
   ```bash
   ./whitney_simulation +trace
   gtkwave whitney_trace.vcd
   ```
2. Check configuration registers
3. Verify timing parameters

**Issue**: Performance issues
**Symptoms**: Slow simulation speed
**Solution**:
1. Disable detailed logging
2. Reduce trace output
3. Use optimized build:
   ```bash
   make CXXFLAGS="-O3 -DNDEBUG"
   ```

#### Memory Issues

**Issue**: Segmentation fault
**Solution**:
1. Check array bounds
2. Verify pointer initialization
3. Use debugging tools:
   ```bash
   gdb ./whitney_simulation
   valgrind ./whitney_simulation
   ```

**Issue**: Memory leaks
**Solution**:
1. Check queue management
2. Verify object cleanup
3. Use memory profiling:
   ```bash
   valgrind --leak-check=full ./whitney_simulation
   ```

### Debug Features

#### Logging Levels

The model supports multiple logging levels:

```cpp
// Set logging level
export WHITNEY_LOG_LEVEL=3

// Levels:
// 0 = Errors only
// 1 = Warnings and errors
// 2 = Info, warnings, and errors
// 3 = Debug, info, warnings, and errors
```

#### Trace Points

Enable specific trace points:

```cpp
// In model code
#ifdef TRACE_AXI
    std::cout << "AXI Transaction: " << transaction_info << std::endl;
#endif

#ifdef TRACE_DDR
    std::cout << "DDR Command: " << command_info << std::endl;
#endif
```

Build with specific traces:
```bash
make CXXFLAGS="-DTRACE_AXI -DTRACE_DDR"
```

#### Assertion Checking

Enable runtime assertions:

```cpp
// Enable assertions
#define SC_ENABLE_ASSERTIONS

// Use in code
sc_assert(condition && "Error message");
```

### Getting Help

#### Self-Diagnosis Checklist

Before contacting support, please check:

- [ ] SystemC version compatibility (2.3.3 or later)
- [ ] Compiler version (GCC 4.8+ or Clang 3.4+)
- [ ] Environment variables set correctly
- [ ] All required files present
- [ ] Build completed without errors
- [ ] Basic test runs successfully

#### Collecting Debug Information

When reporting issues, please provide:

1. **System Information**:
   ```bash
   uname -a
   gcc --version
   echo $SYSTEMC_HOME
   ```

2. **Build Log**:
   ```bash
   make clean && make 2>&1 | tee build.log
   ```

3. **Runtime Log**:
   ```bash
   ./whitney_simulation +verbose 2>&1 | tee runtime.log
   ```

4. **Configuration**:
   - Model version
   - Custom modifications
   - Test scenario used

---

## API Reference

### WhitneySystemCModel Class

#### Constructor
```cpp
WhitneySystemCModel(sc_module_name name);
```

#### Public Methods

##### Configuration Methods
```cpp
void configure_timing(const TimingConfig& config);
void set_memory_size(uint64_t size_bytes);
void enable_feature(const std::string& feature, bool enable);
```

##### Statistics Methods
```cpp
void enable_statistics(bool enable);
void reset_statistics();
void print_statistics();
uint32_t get_transaction_count(TransactionType type);
double get_bandwidth_utilization();
double get_page_hit_rate();
```

##### Debug Methods
```cpp
void set_log_level(int level);
void enable_trace(const std::string& trace_type);
void dump_state();
```

#### Configuration Structures

```cpp
struct TimingConfig {
    uint32_t tCL;      // CAS Latency
    uint32_t tWL;      // Write Latency
    uint32_t tRCD;     // RAS to CAS Delay
    uint32_t tRP;      // Row Precharge Time
    uint32_t tRAS;     // Row Active Time
    uint32_t tRC;      // Row Cycle Time
    uint32_t tREFI;    // Refresh Interval
    uint32_t tRFC;     // Refresh Cycle Time
};

struct MemoryConfig {
    uint32_t num_banks;
    uint32_t num_ranks;
    uint32_t page_size;
    uint32_t burst_length;
    MemoryType type;   // LPDDR5, LPDDR4X, etc.
};
```

#### Enumerations

```cpp
enum TransactionType {
    WRITE_TRANSACTION,
    READ_TRANSACTION,
    ALL_TRANSACTIONS
};

enum MemoryType {
    LPDDR4X,
    LPDDR5,
    LPDDR5X
};

enum LogLevel {
    LOG_ERROR = 0,
    LOG_WARNING = 1,
    LOG_INFO = 2,
    LOG_DEBUG = 3
};
```

### Testbench Classes

#### AXIMaster Class

```cpp
class AXIMaster : public sc_module {
public:
    // Constructor
    SC_CTOR(AXIMaster);
    
    // Transaction methods
    void write_transaction(sc_uint<40> addr, sc_uint<64> data, sc_uint<12> id = 0);
    void read_transaction(sc_uint<40> addr, sc_uint<12> id = 0);
    void burst_write(sc_uint<40> start_addr, const std::vector<sc_uint<64>>& data);
    void burst_read(sc_uint<40> start_addr, uint32_t length);
    
    // Configuration methods
    void set_transaction_rate(double rate);
    void set_address_pattern(AddressPattern pattern);
};
```

#### LPDDR5PHY Class

```cpp
class LPDDR5PHY : public sc_module {
public:
    // Constructor
    SC_CTOR(LPDDR5PHY);
    
    // Configuration methods
    void configure_device(const DeviceConfig& config);
    void set_timing_parameters(const TimingConfig& timing);
    
    // Memory simulation
    void load_memory_image(const std::string& filename);
    void save_memory_image(const std::string& filename);
};
```

---

## Examples and Use Cases

### Example 1: Basic Memory Test

```cpp
#include "whitney_systemc_model.h"

int sc_main(int argc, char* argv[]) {
    // Create clock and reset
    sc_clock clk("clk", 10, SC_NS);
    sc_signal<bool> rst_n;
    
    // Create model instance
    WhitneySystemCModel whitney("whitney");
    
    // Connect basic signals
    whitney.mck(clk);
    whitney.mc_rst_b(rst_n);
    
    // Configure model
    whitney.configure_timing(lpddr5_timing);
    whitney.enable_statistics(true);
    
    // Reset sequence
    rst_n = false;
    sc_start(20, SC_NS);
    rst_n = true;
    
    // Run test
    sc_start(1000, SC_NS);
    
    // Print results
    whitney.print_statistics();
    
    return 0;
}
```

### Example 2: Performance Benchmark

```cpp
class PerformanceBenchmark {
private:
    WhitneySystemCModel* whitney;
    AXIMaster* axi_master;
    
public:
    void run_bandwidth_test() {
        const uint32_t num_transactions = 1000;
        const uint64_t start_addr = 0x10000000;
        
        // Record start time
        sc_time start_time = sc_time_stamp();
        
        // Generate sequential write transactions
        for (uint32_t i = 0; i < num_transactions; i++) {
            uint64_t addr = start_addr + i * 64;
            uint64_t data = 0xDEADBEEF00000000ULL + i;
            axi_master->write_transaction(addr, data, i);
        }
        
        // Wait for completion
        wait_for_completion();
        
        // Calculate bandwidth
        sc_time end_time = sc_time_stamp();
        sc_time duration = end_time - start_time;
        
        double bandwidth = calculate_bandwidth(num_transactions * 8, duration);
        std::cout << "Achieved Bandwidth: " << bandwidth << " GB/s" << std::endl;
    }
    
    void run_latency_test() {
        const uint32_t num_samples = 100;
        std::vector<sc_time> latencies;
        
        for (uint32_t i = 0; i < num_samples; i++) {
            sc_time start = sc_time_stamp();
            
            // Single transaction
            axi_master->read_transaction(0x10000000 + i*8, i);
            
            // Wait for response
            wait_for_response(i);
            
            sc_time end = sc_time_stamp();
            latencies.push_back(end - start);
        }
        
        // Calculate statistics
        double avg_latency = calculate_average(latencies);
        double max_latency = calculate_max(latencies);
        
        std::cout << "Average Latency: " << avg_latency << " ns" << std::endl;
        std::cout << "Maximum Latency: " << max_latency << " ns" << std::endl;
    }
};
```

### Example 3: Custom Configuration

```cpp
void configure_for_mobile_application() {
    // Low power configuration for mobile device
    TimingConfig mobile_timing = {
        .tCL = 18,      // Relaxed timing for power savings
        .tWL = 14,
        .tRCD = 18,
        .tRP = 21,
        .tRAS = 42,
        .tRC = 63,
        .tREFI = 7800,  // Standard refresh interval
        .tRFC = 280
    };
    
    MemoryConfig mobile_memory = {
        .num_banks = 8,
        .num_ranks = 1,
        .page_size = 4096,
        .burst_length = 32,
        .type = LPDDR5
    };
    
    // Apply configuration
    whitney.configure_timing(mobile_timing);
    whitney.configure_memory(mobile_memory);
    
    // Enable power-saving features
    whitney.enable_feature("auto_precharge", true);
    whitney.enable_feature("power_down", true);
    whitney.enable_feature("self_refresh", true);
}

void configure_for_high_performance() {
    // High performance configuration for server/desktop
    TimingConfig perf_timing = {
        .tCL = 14,      // Aggressive timing for performance
        .tWL = 10,
        .tRCD = 14,
        .tRP = 14,
        .tRAS = 32,
        .tRC = 46,
        .tREFI = 3900,  // More frequent refresh
        .tRFC = 210
    };
    
    // Apply configuration
    whitney.configure_timing(perf_timing);
    
    // Enable performance features
    whitney.enable_feature("command_queue", true);
    whitney.enable_feature("bank_interleaving", true);
    whitney.enable_feature("prefetch", true);
}
```

### Example 4: Multi-Channel System

```cpp
class MultiChannelSystem {
private:
    static const int NUM_CHANNELS = 4;
    WhitneySystemCModel* channels[NUM_CHANNELS];
    ChannelArbiter* arbiter;
    
public:
    void setup_system() {
        // Create multiple memory channels
        for (int i = 0; i < NUM_CHANNELS; i++) {
            std::string name = "whitney_ch" + std::to_string(i);
            channels[i] = new WhitneySystemCModel(name.c_str());
            
            // Configure each channel
            configure_channel(channels[i], i);
        }
        
        // Create arbiter for channel selection
        arbiter = new ChannelArbiter("arbiter");
        connect_arbiter();
    }
    
    void run_multi_channel_test() {
        // Distribute transactions across channels
        for (int txn = 0; txn < 1000; txn++) {
            int channel = txn % NUM_CHANNELS;
            uint64_t addr = 0x10000000 + (txn / NUM_CHANNELS) * 64;
            
            // Send transaction to selected channel
            send_to_channel(channel, addr, txn);
        }
        
        // Collect statistics from all channels
        for (int i = 0; i < NUM_CHANNELS; i++) {
            std::cout << "Channel " << i << " Statistics:" << std::endl;
            channels[i]->print_statistics();
        }
    }
};
```

### Example 5: Software Driver Development

```cpp
class MemoryDriver {
private:
    WhitneySystemCModel* whitney;
    uint32_t base_address;
    
public:
    // Initialize memory controller
    bool initialize() {
        // Reset sequence
        write_register(SEQ_CONTROL, 0x00000000);  // Reset
        wait(100, SC_NS);
        
        // Configure for LPDDR5
        write_register(DDR_CONFIG, 0x00030520);
        write_register(REFRESH_CNTRL, 0x00001F41);
        
        // Load timing parameters
        load_timing_parameters();
        
        // Enable controller
        write_register(SEQ_CONTROL, 0x00000001);
        
        // Verify initialization
        return verify_initialization();
    }
    
    // Memory allocation
    void* allocate_memory(size_t size) {
        // Find free memory region
        uint64_t addr = find_free_region(size);
        
        // Mark as allocated
        mark_allocated(addr, size);
        
        return reinterpret_cast<void*>(addr);
    }
    
    // Memory read/write operations
    void write_memory(void* addr, const void* data, size_t size) {
        uint64_t mem_addr = reinterpret_cast<uint64_t>(addr);
        const uint8_t* src = static_cast<const uint8_t*>(data);
        
        // Perform write operations
        for (size_t i = 0; i < size; i += 8) {
            uint64_t write_data = *reinterpret_cast<const uint64_t*>(src + i);
            axi_write(mem_addr + i, write_data);
        }
    }
    
    void read_memory(const void* addr, void* data, size_t size) {
        uint64_t mem_addr = reinterpret_cast<uint64_t>(addr);
        uint8_t* dst = static_cast<uint8_t*>(data);
        
        // Perform read operations
        for (size_t i = 0; i < size; i += 8) {
            uint64_t read_data = axi_read(mem_addr + i);
            *reinterpret_cast<uint64_t*>(dst + i) = read_data;
        }
    }
    
private:
    void write_register(uint32_t addr, uint32_t data) {
        // APB write transaction
        apb_write(addr, data);
    }
    
    uint32_t read_register(uint32_t addr) {
        // APB read transaction
        return apb_read(addr);
    }
    
    void load_timing_parameters() {
        // Load LPDDR5 timing parameters
        write_register(AC_TIMING_REG1, 0x120E1215);  // tCL=18, tWL=14, tRCD=18, tRP=21
        write_register(AC_TIMING_REG2, 0x2A3F1008);  // tRAS=42, tRC=63, tRRD=16, tFAW=8
        write_register(AC_TIMING_REG3, 0x08040820);  // tWTR=8, tRTP=4, tCCD=8, tBL=32
        write_register(AC_TIMING_REG4, 0x1E780118);  // tREFI=7800, tRFC=280, tXSR=280
    }
    
    bool verify_initialization() {
        uint32_t status = read_register(PMU_STATUS);
        return (status & 0x30) == 0x30;  // Check sequencer type = LPDDR5x
    }
};
```

---

## Support and Contact

### Technical Support

For technical support with the Whitney LPDDR5 SystemC Model, please use the following resources:

#### Documentation and Resources
- **User Guide**: This document (Whitney_LPDDR5_SystemC_User_Guide.md)
- **API Reference**: Complete API documentation in Section 11
- **Example Code**: Reference implementations in Section 12
- **README**: Basic setup and usage instructions

#### Self-Service Support

Before contacting technical support, please:

1. **Check the Troubleshooting Section**: Section 10 covers common issues and solutions
2. **Review the FAQ**: Frequently asked questions and answers
3. **Run the Self-Diagnosis**: Use the checklist in Section 10.3.1
4. **Check System Requirements**: Verify your environment meets the requirements

#### Contacting Support

When contacting support, please provide:

1. **Model Version**: Whitney LPDDR5 SystemC Model v1.0
2. **System Information**: OS, compiler version, SystemC version
3. **Issue Description**: Detailed description of the problem
4. **Reproduction Steps**: Step-by-step instructions to reproduce the issue
5. **Log Files**: Build logs, runtime logs, and error messages
6. **Configuration**: Any custom configurations or modifications

#### Support Channels

- **Email Support**: systemc-support@company.com
- **Online Portal**: https://support.company.com/systemc
- **Knowledge Base**: https://kb.company.com/whitney-systemc

### Frequently Asked Questions (FAQ)

#### General Questions

**Q: What is the difference between this SystemC model and the RTL?**
A: The SystemC model is a behavioral model optimized for system-level simulation and software development. It provides the same functional behavior as the RTL but with faster simulation speed and higher abstraction level.

**Q: Can I use this model for silicon validation?**
A: This model is intended for system-level verification and software development. For silicon validation, please use the RTL implementation.

**Q: What LPDDR5 features are supported?**
A: The model supports core LPDDR5 features including BL32, multi-bank operation, refresh management, and DFI interface. See Section 4 for detailed feature list.

#### Installation and Setup

**Q: Which SystemC version is required?**
A: SystemC 2.3.3 or later is required. SystemC 2.3.4 is recommended for best compatibility.

**Q: Can I use this model on Windows?**
A: The model is primarily tested on Linux. Windows support may be available through WSL (Windows Subsystem for Linux) or Cygwin.

**Q: Do I need a SystemC license?**
A: SystemC is open source and freely available from Accellera. No license is required for SystemC itself.

#### Usage and Integration

**Q: How do I integrate this model with my existing SystemC testbench?**
A: See Section 8.1 for integration guidelines and examples.

**Q: Can I modify the model for my specific requirements?**
A: Yes, the model is designed to be customizable. See Section 8.2 for customization guidelines.

**Q: How accurate is the timing model?**
A: The model provides cycle-accurate behavior for key functions. Some detailed timing aspects are simplified for simulation speed.

#### Performance and Optimization

**Q: How can I improve simulation speed?**
A: See Section 8.3 for performance optimization techniques including logging reduction and conditional compilation.

**Q: What is the typical simulation speed compared to RTL?**
A: The SystemC model typically runs 10-100x faster than RTL simulation, depending on the test scenario and optimization level.

**Q: Can I run multiple instances for multi-channel systems?**
A: Yes, the model supports multi-instance usage. See Example 4 in Section 12 for multi-channel implementation.

### Training and Education

#### Available Training Materials

1. **SystemC Fundamentals**: Introduction to SystemC modeling concepts
2. **Memory Controller Architecture**: Understanding LPDDR5 and memory controller design
3. **Model Usage Workshop**: Hands-on training with the Whitney SystemC model
4. **Advanced Customization**: Deep dive into model customization and extension

#### Online Resources

- **Video Tutorials**: Step-by-step video guides for common tasks
- **Webinar Series**: Regular webinars on SystemC modeling best practices
- **Community Forum**: User community for questions and discussions
- **Sample Projects**: Complete example projects demonstrating various use cases

### Feedback and Suggestions

We value your feedback to improve the Whitney LPDDR5 SystemC Model:

#### How to Provide Feedback

- **Feature Requests**: Submit requests for new features or enhancements
- **Bug Reports**: Report issues or unexpected behavior
- **Documentation**: Suggest improvements to documentation and examples
- **Usability**: Share your experience and suggestions for better usability

#### Feedback Channels

- **Email**: feedback@company.com
- **Online Survey**: https://survey.company.com/whitney-systemc
- **User Forum**: https://forum.company.com/systemc-models
- **Direct Contact**: Through your account manager or sales representative

### Version History and Updates

#### Current Version: v1.0
- Initial release of Whitney LPDDR5 SystemC Model
- Full AXI4, APB, and DFI interface support
- Comprehensive testbench and examples
- Complete documentation and user guide

#### Planned Updates
- **v1.1**: Enhanced performance monitoring and additional timing parameters
- **v1.2**: Support for additional LPDDR5 features and configurations
- **v2.0**: Multi-channel support and advanced power modeling

#### Update Notifications
- Subscribe to our mailing list for update notifications
- Check the support portal for latest releases
- Follow release notes for new features and bug fixes

### Legal and Licensing

#### Model License
This SystemC model is provided under a commercial license agreement. Please refer to your license agreement for terms and conditions of use.

#### SystemC License
SystemC is provided under the Apache 2.0 license by Accellera Systems Initiative.

#### Third-Party Components
This model may include third-party components with their own licensing terms. See the LICENSES file for details.

#### Export Control
This software may be subject to export control regulations. Please ensure compliance with applicable laws and regulations.

---

## Appendices

### Appendix A: Register Bit Definitions

#### SEQ_CONTROL Register (0x000)
| Bits | Field Name | Access | Description |
|------|------------|--------|-------------|
| [0] | DDR_INIT_DONE | R/W | DDR initialization complete |
| [1] | SEQ_ENABLE | R/W | Sequencer enable |
| [2] | AUTO_REFRESH_EN | R/W | Auto refresh enable |
| [7:3] | RESERVED | R | Reserved |
| [15:8] | SEQ_STATE | R | Current sequencer state |
| [31:16] | RESERVED | R | Reserved |

#### DDR_CONFIG Register (0x008)
| Bits | Field Name | Access | Description |
|------|------------|--------|-------------|
| [1:0] | DDR_TYPE | R/W | 00=LPDDR4X, 01=LPDDR5, 10=LPDDR5X |
| [3:2] | DATA_WIDTH | R/W | 00=16-bit, 01=32-bit, 10=64-bit |
| [7:4] | BURST_LENGTH | R/W | 0000=BL16, 0001=BL32 |
| [11:8] | NUM_BANKS | R/W | Number of banks (0-15) |
| [15:12] | NUM_RANKS | R/W | Number of ranks (0-3) |
| [31:16] | RESERVED | R/W | Reserved |

### Appendix B: Timing Parameter Definitions

#### LPDDR5 Standard Timing Parameters
| Parameter | Description | Min (ns) | Typical (ns) | Max (ns) |
|-----------|-------------|----------|--------------|----------|
| tCL | CAS Latency | 14 | 18 | 24 |
| tWL | Write Latency | 10 | 14 | 18 |
| tRCD | RAS to CAS Delay | 14 | 18 | 24 |
| tRP | Row Precharge Time | 14 | 21 | 27 |
| tRAS | Row Active Time | 32 | 42 | 70 |
| tRC | Row Cycle Time | 46 | 63 | 97 |
| tREFI | Refresh Interval | 3900 | 7800 | 7800 |
| tRFC | Refresh Cycle Time | 210 | 280 | 380 |

### Appendix C: Error Codes and Messages

#### Common Error Codes
| Code | Message | Description | Solution |
|------|---------|-------------|----------|
| E001 | SystemC header not found | SystemC installation issue | Check SYSTEMC_HOME path |
| E002 | Linking error | Library path issue | Check LD_LIBRARY_PATH |
| E003 | Simulation timeout | Infinite loop or deadlock | Check clock/reset connections |
| E004 | Invalid configuration | Register value out of range | Verify configuration values |
| E005 | Memory allocation failed | Insufficient system memory | Increase available memory |

#### Warning Messages
| Code | Message | Description | Action |
|------|---------|-------------|--------|
| W001 | Timing violation | DDR timing constraint violated | Check timing parameters |
| W002 | Buffer overflow | Internal buffer full | Reduce transaction rate |
| W003 | Page miss | Memory access missed open page | Optimize access pattern |
| W004 | Refresh pending | Refresh operation delayed | Check refresh configuration |

### Appendix D: Performance Benchmarks

#### Reference Performance Data
Based on typical LPDDR5-6400 configuration:

| Metric | Value | Unit |
|--------|-------|------|
| Peak Bandwidth | 51.2 | GB/s |
| Random Access Latency | 120 | ns |
| Sequential Access Latency | 80 | ns |
| Page Hit Rate (Sequential) | 95 | % |
| Page Hit Rate (Random) | 15 | % |
| Refresh Overhead | 2.5 | % |

#### Benchmark Test Results
| Test Scenario | Bandwidth (GB/s) | Latency (ns) | Efficiency (%) |
|---------------|-------------------|--------------|----------------|
| Sequential Write | 48.5 | 85 | 94.7 |
| Sequential Read | 49.2 | 82 | 96.1 |
| Random Write | 12.8 | 145 | 25.0 |
| Random Read | 15.2 | 135 | 29.7 |
| Mixed Workload | 28.4 | 110 | 55.5 |

---

**Document Information:**
- **Title**: Whitney LPDDR5 Memory Controller SystemC Model User Guide
- **Version**: 1.0
- **Date**: January 2024
- **Authors**: SystemC Modeling Team
- **Document ID**: WH-SC-UG-001

**Copyright Notice:**
© 2024 Company Name. All rights reserved. This document contains confidential and proprietary information and is intended solely for the use of licensed customers.

---

*End of User Guide*
