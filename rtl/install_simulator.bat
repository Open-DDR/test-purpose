@echo off
REM Quick Installation Script for Icarus Verilog
REM This will help you install a free SystemVerilog simulator

echo =====================================================
echo OpenDDR RTL - Quick Simulator Installation
echo =====================================================
echo.

echo This script will help you install Icarus Verilog (free simulator)
echo for testing your OpenDDR RTL implementation.
echo.

echo Option 1: Automatic Download and Install (Recommended)
echo Option 2: Manual Installation Instructions
echo Option 3: Show All Simulator Options
echo.

set /p choice="Enter your choice (1-3): "

if "%choice%"=="1" goto :auto_install
if "%choice%"=="2" goto :manual_install
if "%choice%"=="3" goto :show_options
goto :end

:auto_install
echo.
echo =====================================================
echo AUTOMATIC INSTALLATION
echo =====================================================
echo.
echo Downloading Icarus Verilog...
echo This may take a few minutes depending on your connection.
echo.

REM Check if we can use PowerShell to download
powershell -Command "& {if (Get-Command Invoke-WebRequest -ErrorAction SilentlyContinue) { echo 'PowerShell download available' } else { echo 'Manual download required' }}"

echo.
echo Attempting to download Icarus Verilog installer...
echo.

REM Try to download the installer
powershell -Command "& {try { Invoke-WebRequest -Uri 'http://bleyer.org/icarus/iverilog-v12-20220611-x64.msi' -OutFile 'iverilog_installer.msi'; echo 'Download completed successfully!' } catch { echo 'Download failed. Please use manual installation.' }}"

if exist iverilog_installer.msi (
    echo.
    echo Installer downloaded successfully!
    echo Starting installation...
    echo.
    
    REM Run the installer
    msiexec /i iverilog_installer.msi /qb
    
    echo.
    echo Installation completed!
    echo.
    echo Testing installation...
    iverilog -V
    
    if %errorlevel% equ 0 (
        echo.
        echo ✓ Icarus Verilog installed successfully!
        echo You can now test your RTL with: iverilog -g2012 -I include -o test.out include/openddr_pkg.sv src/*.sv
    ) else (
        echo.
        echo Installation may have failed. Please check manually.
    )
) else (
    echo Download failed. Please use manual installation.
    goto :manual_install
)
goto :end

:manual_install
echo.
echo =====================================================
echo MANUAL INSTALLATION INSTRUCTIONS
echo =====================================================
echo.
echo 1. ICARUS VERILOG (Quick - 5 minutes):
echo    - Go to: http://iverilog.icarus.com/
echo    - Download: iverilog-v12-20220611-x64.msi
echo    - Double-click to install
echo    - Test with: iverilog -V
echo.
echo 2. INTEL QUARTUS PRIME LITE (Full - 2 hours):
echo    - Go to: https://www.intel.com/content/www/us/en/software/programmable/quartus-prime/download.html
echo    - Download: Quartus-lite (8GB)
echo    - Install with ModelSim option
echo    - Provides: vlib, vlog, vsim commands
echo.
echo 3. XILINX VIVADO WEBPACK (Alternative):
echo    - Go to: https://www.xilinx.com/support/download.html
echo    - Download: Vivado WebPACK
echo    - Provides: xvlog, xelab, xsim commands
echo.
echo RECOMMENDATION: Start with Icarus Verilog for quick testing!
goto :end

:show_options
echo.
echo =====================================================
echo ALL SIMULATOR OPTIONS
echo =====================================================
echo.
echo FREE OPTIONS:
echo.
echo 1. Icarus Verilog (Open Source)
echo    Size: ~50MB
echo    Time: 5 minutes
echo    Features: Basic SystemVerilog support
echo    Best for: Quick testing, learning
echo    Commands: iverilog, vvp
echo.
echo 2. Intel Quartus Prime Lite (Free for small projects)
echo    Size: ~8GB
echo    Time: 1-2 hours
echo    Features: Full SystemVerilog, ModelSim included
echo    Best for: Professional development
echo    Commands: vlib, vlog, vsim
echo.
echo 3. Xilinx Vivado WebPACK (Free for small devices)
echo    Size: ~6GB
echo    Time: 1-2 hours
echo    Features: Full SystemVerilog support
echo    Best for: Xilinx FPGA targeting
echo    Commands: xvlog, xelab, xsim
echo.
echo 4. Verilator (Open Source)
echo    Size: ~100MB
echo    Time: 30 minutes (if pre-compiled available)
echo    Features: Very fast simulation, C++ compilation
echo    Best for: Large designs, performance
echo    Commands: verilator
echo.
echo COMMERCIAL OPTIONS (Free trials available):
echo.
echo 5. Siemens QuestaSim (30-day trial)
echo    Features: Full SystemVerilog, UVM, advanced debug
echo    Best for: Professional verification
echo.
echo 6. Cadence Xcelium (Academic/trial)
echo    Features: Advanced SystemVerilog, formal verification
echo    Best for: Advanced verification flows
echo.
echo RECOMMENDATION FOR YOUR OPENDDR PROJECT:
echo   Start with: Icarus Verilog (5 min setup)
echo   Upgrade to: Intel Quartus + ModelSim (full features)
goto :end

:end
echo.
echo =====================================================
echo NEXT STEPS AFTER INSTALLATION
echo =====================================================
echo.
echo 1. Test your simulator installation:
echo    iverilog -V    (for Icarus)
echo    vsim -version  (for ModelSim)
echo    xsim -version  (for Vivado)
echo.
echo 2. Test OpenDDR RTL compilation:
echo    Navigate to: C:\jae\memtech\openddr-project\test-purpose\rtl
echo    Run: test_rtl.bat
echo.
echo 3. If you need help with specific installation:
echo    See: SIMULATOR_INSTALL.md for detailed guides
echo.
echo Happy simulating!
pause
