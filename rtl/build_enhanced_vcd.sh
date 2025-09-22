#!/bin/bash

# Enhanced Verilator smoke test build script with VCD support
# This script builds the DDR2 controller with VCD waveform generation capability

echo "=== ENHANCED SMOKE TEST BUILD WITH VCD (Linux) ==="
echo "Building DDR controller with Verilator, testbench, and VCD support..."

# Set paths to use local RTL files
CURRENT_DIR="$(pwd)"
MODEL_PATH="$CURRENT_DIR"
MAIN_RTL_FILE="$MODEL_PATH/ddr2_axi_controller_verilator_clean.sv"
OBJ_DIR="$MODEL_PATH/obj_dir_smoke_extension"
TESTBENCH_FILE="$MODEL_PATH/smoke_test_enhanced.cpp"

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
    echo "❌ Enhanced testbench file not found: $TESTBENCH_FILE"
    echo "Using the enhanced testbench for VCD generation..."
fi

# Check if Verilator is available
if command -v verilator >/dev/null 2>&1; then
    echo "✅ Verilator found, starting build with VCD support..."
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
    echo "Using enhanced testbench: $TESTBENCH_FILE"
    echo "Output directory: $OBJ_DIR"
    
    # Create a clean object directory
    rm -rf "$OBJ_DIR"
    mkdir -p "$OBJ_DIR"
    
    # Run Verilator with VCD support
    echo "Building with VCD tracing enabled..."
    verilator --cc --exe --build \
        --top-module ddr2_axi_controller \
        --Mdir "$OBJ_DIR" \
        --trace \
        -CFLAGS "-DSMOKE_TEST -O0" \
        -LDFLAGS "-lz" \
        $INCLUDE_DIRS \
        "$MAIN_RTL_FILE" \
        "$TESTBENCH_FILE" \
        -o smoke_test_enhanced
    
    if [ $? -eq 0 ]; then
        echo "✅ Enhanced smoke test build completed successfully!"
        echo "Executable created: $OBJ_DIR/smoke_test_enhanced"
        echo "VCD tracing enabled in the executable"
        
        # Test the executable with VCD generation
        echo ""
        echo "=== TESTING VCD GENERATION ==="
        cd "$OBJ_DIR"
        echo "Running smoke test with VCD generation..."
        ./smoke_test_enhanced --memory-model=DDR2-800 --test-cycles=500 --output-vcd=test_waveform.vcd
        
        if [ $? -eq 0 ]; then
            echo "✅ Enhanced smoke test execution completed successfully!"
            if [ -f "test_waveform.vcd" ]; then
                echo "✅ VCD file generated: $(pwd)/test_waveform.vcd"
                echo "📊 VCD file size: $(du -h test_waveform.vcd | cut -f1)"
                echo "🔍 You can view this file with GTKWave or load it in the VS Code VCD viewer"
            else
                echo "⚠️ VCD file was not generated - check testbench implementation"
            fi
        else
            echo "❌ Enhanced smoke test execution failed"
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