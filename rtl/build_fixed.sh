#!/bin/bash

# Fixed Verilator smoke test build script
# This script builds the DDR2 controller with a proper C++ testbench

echo "=== FIXED SMOKE TEST BUILD (Linux) ==="
echo "Building DDR controller with Verilator and testbench..."

# Set paths based on the error log
MODEL_PATH="/aws/home/jayb/Downloads/888/DDR2-800_2Gb_x8"
MAIN_RTL_FILE="$MODEL_PATH/rtl/src/ddr2_controller.sv"
OBJ_DIR="$MODEL_PATH/obj_dir_smoke_fixed"
TESTBENCH_FILE="/aws/home/jayb/proj/open-ddr/test-purpose/rtl/smoke_test.cpp"

# Check if the model exists
if [ ! -d "$MODEL_PATH" ]; then
    echo "❌ DDR model not found at: $MODEL_PATH"
    echo "Please make sure the model is downloaded and the path is correct."
    exit 1
fi

# Check if main RTL file exists
if [ ! -f "$MAIN_RTL_FILE" ]; then
    echo "❌ Main RTL file not found: $MAIN_RTL_FILE"
    exit 1
fi

# Check if testbench file exists
if [ ! -f "$TESTBENCH_FILE" ]; then
    echo "❌ Testbench file not found: $TESTBENCH_FILE"
    exit 1
fi

# Check if Verilator is available
if command -v verilator >/dev/null 2>&1; then
    echo "✅ Verilator found, starting build..."
    verilator --version
    
    # Set up include paths
    INCLUDE_DIRS=""
    if [ -d "$MODEL_PATH/rtl/include" ]; then
        INCLUDE_DIRS="$INCLUDE_DIRS -I$MODEL_PATH/rtl/include"
        echo "✅ Added include path: $MODEL_PATH/rtl/include"
    fi
    if [ -d "$MODEL_PATH/rtl" ]; then
        INCLUDE_DIRS="$INCLUDE_DIRS -I$MODEL_PATH/rtl"
        echo "✅ Added include path: $MODEL_PATH/rtl"
    fi
    
    echo "Include directories: $INCLUDE_DIRS"
    echo "Building with main file: $MAIN_RTL_FILE"
    echo "Using testbench: $TESTBENCH_FILE"
    echo "Output directory: $OBJ_DIR"
    
    # Create a clean object directory
    rm -rf "$OBJ_DIR"
    mkdir -p "$OBJ_DIR"
    
    # Run Verilator with proper testbench
    verilator --cc --exe --build \
        --top-module ddr2_controller \
        --Mdir "$OBJ_DIR" \
        -CFLAGS "-DSMOKE_TEST -O0" \
        $INCLUDE_DIRS \
        "$MAIN_RTL_FILE" \
        "$TESTBENCH_FILE" \
        -o smoke_test_fixed
    
    if [ $? -eq 0 ]; then
        echo "✅ Smoke test build completed successfully!"
        echo "Executable created: $OBJ_DIR/smoke_test_fixed"
        
        # Run the test
        echo ""
        echo "=== RUNNING SMOKE TEST ==="
        cd "$OBJ_DIR"
        ./smoke_test_fixed
        if [ $? -eq 0 ]; then
            echo "✅ Smoke test execution completed successfully!"
        else
            echo "❌ Smoke test execution failed"
        fi
    else
        echo "❌ Build failed"
        exit 1
    fi
else
    echo "❌ Verilator not found. Please install Verilator first."
    echo "Ubuntu/Debian: sudo apt-get install verilator"
    echo "CentOS/RHEL: sudo yum install verilator"
    echo "macOS: brew install verilator"
    exit 1
fi