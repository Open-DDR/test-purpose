#!/bin/bash
set -e

echo "=== CUSTOM TEST BUILD (Linux) ==="
echo "Building full-featured DDR controller..."

# Set MODEL_PATH to specific downloaded location for debugging
MODEL_PATH="/aws/home/jayb/Downloads/u/DDR2-800_2Gb_x8"

# Check if this is a SystemC test request
if [ "$1" = "systemc" ] || [ "$2" = "systemc" ]; then
    echo ""
    echo "🔄 Switching to SystemC test mode..."
    exec "$(dirname "$0")/simple_systemc_test.sh" "$@"
fi

# Allow override from command line argument if provided
if [ -n "$1" ] && [ "$1" != "UNKNOWN" ]; then
    MODEL_PATH="$1"
fi

if [ "$MODEL_PATH" != "UNKNOWN" ] && [ -n "$MODEL_PATH" ]; then
    echo "✅ Using downloaded DDR model at: $MODEL_PATH"
    
    # Find main RTL file - use the same logic as smoke test
    MAIN_RTL_FILE=""
    if [ -f "$MODEL_PATH/rtl/src/ddr2_controller.sv" ]; then
        MAIN_RTL_FILE="$MODEL_PATH/rtl/src/ddr2_controller.sv"
        echo "✅ Found main DDR controller file: $MAIN_RTL_FILE"
    else
        MAIN_RTL_FILE=$(find "$MODEL_PATH" -name "*ddr*controller*.sv" | grep -v "_tb\|testbench" | head -1)
        if [ -z "$MAIN_RTL_FILE" ]; then
            MAIN_RTL_FILE=$(find "$MODEL_PATH" -name "*controller*.sv" | grep -v "_tb\|testbench" | head -1)
        fi
        echo "✅ Found DDR controller file: $MAIN_RTL_FILE"
    fi
    
    if [ -n "$MAIN_RTL_FILE" ]; then
        if command -v verilator >/dev/null 2>&1; then
            OBJ_DIR="$MODEL_PATH/obj_dir_custom"
            
            # Build include directories
            INCLUDE_DIRS=""
            if [ -d "$MODEL_PATH/rtl/include" ]; then
                INCLUDE_DIRS="$INCLUDE_DIRS -I$MODEL_PATH/rtl/include"
            fi
            if [ -d "$MODEL_PATH/include" ]; then
                INCLUDE_DIRS="$INCLUDE_DIRS -I$MODEL_PATH/include"
            fi
            if [ -d "$MODEL_PATH/rtl" ]; then
                INCLUDE_DIRS="$INCLUDE_DIRS -I$MODEL_PATH/rtl"
            fi
            
            # Look for package files
            PKG_FILES=""
            if [ -f "$MODEL_PATH/rtl/include/ddr2_pkg.sv" ]; then
                PKG_FILES="$MODEL_PATH/rtl/include/ddr2_pkg.sv"
            elif [ -f "$MODEL_PATH/include/ddr2_pkg.sv" ]; then
                PKG_FILES="$MODEL_PATH/include/ddr2_pkg.sv"
            fi
            
            # Check if main RTL file has timescale directive and add if missing
            if ! grep -q "^\`timescale" "$MAIN_RTL_FILE"; then
                echo "⚠️ Adding missing timescale directive to RTL file..."
                # Create a temporary file with timescale directive
                TEMP_RTL_FILE="$MODEL_PATH/ddr2_controller_with_timescale.sv"
                echo "\`timescale 1ns/1ps" > "$TEMP_RTL_FILE"
                cat "$MAIN_RTL_FILE" >> "$TEMP_RTL_FILE"
                MAIN_RTL_FILE="$TEMP_RTL_FILE"
                echo "✅ Created temporary RTL file with timescale: $MAIN_RTL_FILE"
            fi
            
            # Copy C++ testbench from test-purpose directory
            echo "Copying C++ testbench from test-purpose..."
            SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            TESTBENCH_SOURCE="$SCRIPT_DIR/simple_testbench.cpp"
            if [ -f "$TESTBENCH_SOURCE" ]; then
                cp "$TESTBENCH_SOURCE" "$MODEL_PATH/simple_testbench.cpp"
                echo "✅ Copied testbench from: $TESTBENCH_SOURCE"
            else
                echo "❌ Error: Testbench source not found at: $TESTBENCH_SOURCE"
                exit 1
            fi
            
            echo "Building with C++ testbench..."
            
            # Create a corrected version of the controller with proper type names
            TEMP_CONTROLLER="$MODEL_PATH/ddr2_controller_custom_corrected.sv"
            echo "Creating corrected controller file with proper type names..."
            
            # Fix the type name mismatch in the controller
            sed 's/ctrl_state_t/ddr2_state_t/g' "$MAIN_RTL_FILE" > "$TEMP_CONTROLLER"
            
            echo "Using corrected controller file: $TEMP_CONTROLLER"
            
            # Use Verilator with the corrected file
            verilator --cc --exe --build \
                --top-module ddr2_controller \
                --Mdir "$OBJ_DIR" \
                -CFLAGS "-DCUSTOM_TEST -O2 -g" \
                --timescale 1ns/1ps \
                -Wno-MODDUP \
                -Wno-TIMESCALEMOD \
                --trace --trace-depth 3 --trace-structs \
                --assert --coverage \
                $INCLUDE_DIRS \
                "$TEMP_CONTROLLER" \
                "$MODEL_PATH/simple_testbench.cpp" \
                -o custom_test_enhanced
            
            echo "✅ Custom test build completed!"
            echo "✅ Executable: $OBJ_DIR/custom_test_enhanced"
        else
            echo "❌ Verilator not found. Please install Verilator first."
        fi
    else
        echo "❌ No DDR controller RTL files found in downloaded model"
    fi
else
    echo "❌ No DDR model downloaded yet. Please download a model first using the 'Download...' button."
    echo "Workspace path: $2"
fi