#!/bin/bash

# Safe Verilator smoke test build script
# This script builds the DDR2 controller with the safe C++ testbench

echo "=== SAFE SMOKE TEST BUILD (Linux) ==="
echo "Building DDR controller with Verilator and safe testbench..."

# Set paths to use local RTL files
CURRENT_DIR="$(pwd)"
MODEL_PATH="$CURRENT_DIR"
MAIN_RTL_FILE="$MODEL_PATH/ddr2_axi_controller_verilator_clean.sv"
OBJ_DIR="$MODEL_PATH/obj_dir_smoke_safe"
TESTBENCH_FILE="$MODEL_PATH/smoke_test_safe.cpp"

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
    
    # Set up include paths for local directory
    INCLUDE_DIRS=""
    if [ -d "$MODEL_PATH/include" ]; then
        INCLUDE_DIRS="$INCLUDE_DIRS -I$MODEL_PATH/include"
        echo "✅ Added include path: $MODEL_PATH/include"
    fi
    if [ -d "$MODEL_PATH/src" ]; then
        INCLUDE_DIRS="$INCLUDE_DIRS -I$MODEL_PATH/src"
        echo "✅ Added include path: $MODEL_PATH/src"
    fi
    
    echo "Include directories: $INCLUDE_DIRS"
    echo "Building with main file: $MAIN_RTL_FILE"
    echo "Using testbench: $TESTBENCH_FILE"
    echo "Output directory: $OBJ_DIR"
    
    # Create a clean object directory
    rm -rf "$OBJ_DIR"
    mkdir -p "$OBJ_DIR"
    
    # Run Verilator with our safe local files and trace support
    verilator --cc --exe --build --trace \
        --top-module ddr2_axi_controller \
        --Mdir "$OBJ_DIR" \
        -CFLAGS "-DSMOKE_TEST -O0" \
        $INCLUDE_DIRS \
        "$MAIN_RTL_FILE" \
        "$TESTBENCH_FILE" \
        -o smoke_test_safe
    
    if [ $? -eq 0 ]; then
        echo "✅ Safe smoke test build completed successfully!"
        echo "Executable created: $OBJ_DIR/smoke_test_safe"
        
        # Run the test
        echo ""
        echo "=== RUNNING SAFE SMOKE TEST ==="
        cd "$OBJ_DIR"
        ./smoke_test_safe
        if [ $? -eq 0 ]; then
            echo "✅ Safe smoke test execution completed successfully!"
            echo "VCD trace file generated: smoke_test.vcd"
            echo ""
            echo "Usage examples:"
            echo "  ./smoke_test_safe --output-vcd=custom.vcd --test-cycles=500"
            echo "  ./smoke_test_safe --memory-model=DDR2-1066"
        else
            echo "❌ Safe smoke test execution failed"
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