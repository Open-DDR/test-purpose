# SystemVerilog Simulator Installation Guide for Windows

## RECOMMENDED: Intel Quartus Prime Lite (FREE)

### Why Intel Quartus Prime?
- ✅ **FREE** for educational and small commercial use
- ✅ Includes **ModelSim-Intel FPGA Starter Edition**
- ✅ Full SystemVerilog support
- ✅ Provides `vlib`, `vlog`, `vsim` commands
- ✅ Excellent for DDR controller development

### Step-by-Step Installation:

#### 1. Download Intel Quartus Prime Lite
```
URL: https://www.intel.com/content/www/us/en/software/programmable/quartus-prime/download.html
File: Quartus-lite-21.1.1.850-windows.exe (or latest version)
Size: ~8GB
```

#### 2. Installation Process
1. Run the installer as Administrator
2. Select "Quartus Prime Lite" 
3. **IMPORTANT**: Check "ModelSim-Intel FPGA Starter Edition"
4. Choose installation directory (default: C:\intelFPGA_lite\)
5. Install (takes 30-60 minutes)

#### 3. Setup Environment
After installation, add to PATH:
```
C:\intelFPGA_lite\21.1\modelsim_ase\win32aloem
C:\intelFPGA_lite\21.1\quartus\bin64
```

#### 4. Verify Installation
Open new Command Prompt and test:
```batch
vlib --version
vlog --version
vsim -version
```

## ALTERNATIVE 1: Xilinx Vivado (FREE)

### Vivado WebPACK Edition
- ✅ FREE for small devices
- ✅ Includes Vivado Simulator (xsim)
- ✅ SystemVerilog support
- ❌ Different command syntax

### Installation:
```
URL: https://www.xilinx.com/support/download.html
File: Xilinx_Unified_2023.2_1013_2256_Win64.exe
Commands: xvlog, xelab, xsim
```

## ALTERNATIVE 2: Icarus Verilog (OPEN SOURCE)

### Icarus Verilog - Free & Open Source
- ✅ Completely FREE
- ✅ Small download (~50MB)
- ❌ Limited SystemVerilog support
- ❌ May have issues with advanced features

### Installation:
1. Download from: http://iverilog.icarus.com/
2. Install iverilog-v12-20220611-x64.msi
3. Commands: `iverilog`, `vvp`

## ALTERNATIVE 3: Verilator (OPEN SOURCE)

### Verilator - High Performance
- ✅ Very fast simulation
- ✅ FREE and open source
- ❌ Requires compilation to C++
- ❌ Different workflow

### Installation (via WSL or MSYS2):
```bash
# In WSL Ubuntu
sudo apt install verilator

# Or download Windows build
```

## RECOMMENDED INSTALLATION STEPS FOR YOUR PROJECT

### Step 1: Quick Test with Icarus (15 minutes)
```batch
1. Download: http://iverilog.icarus.com/ -> iverilog-v12-20220611-x64.msi
2. Install with default options
3. Open new Command Prompt
4. Test: iverilog -V
```

### Step 2: Full Setup with Intel Quartus (1-2 hours)
```batch
1. Download Intel Quartus Prime Lite (8GB)
2. Install with ModelSim option
3. Add to PATH
4. Test with our RTL files
```

## Testing Your OpenDDR RTL

### With Icarus Verilog (Basic Test):
```batch
cd C:\jae\memtech\openddr-project\test-purpose\rtl
iverilog -g2012 -I include -o openddr_test.out include/openddr_pkg.sv src/openddr_*.sv
vvp openddr_test.out
```

### With ModelSim (Full Test):
```batch
cd C:\jae\memtech\openddr-project\test-purpose\rtl
vlib work
vlog +incdir+include include/openddr_pkg.sv
vlog +incdir+include src/openddr_*.sv
vsim -gui openddr_controller
```

### With Vivado (Alternative):
```batch
cd C:\jae\memtech\openddr-project\test-purpose\rtl
xvlog --sv include/openddr_pkg.sv src/openddr_*.sv
xelab openddr_controller
xsim openddr_controller -gui
```

## Installation Priority for Your Project

1. **🚀 Quick Start (15 min)**: Icarus Verilog - Basic testing
2. **🏆 Professional (2 hours)**: Intel Quartus + ModelSim - Full features  
3. **⚡ Alternative**: Vivado WebPACK - If you prefer Xilinx tools

## Next Steps After Installation

1. **Verify Installation**: Test with simple Verilog file
2. **Test OpenDDR RTL**: Use our provided test scripts
3. **Run Full Simulation**: Execute testbench
4. **SystemC Integration**: Set up co-simulation

## Need Help?

Common issues:
- **PATH not set**: Add tool directories to Windows PATH
- **License issues**: Ensure using free/lite versions
- **32-bit vs 64-bit**: Match your Windows version
- **Antivirus blocking**: Temporarily disable during install

Let me know which option you choose, and I'll help with the specific setup!
