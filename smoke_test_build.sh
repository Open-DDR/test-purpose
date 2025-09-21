#!/bin/bash
set -e

echo "=== SMOKE TEST BUILD (Linux) ==="
echo "Building DDR controller with Verilator..."

# Set MODEL_PATH to specific downloaded location for debugging
MODEL_PATH="/aws/home/jayb/Downloads/u/DDR2-800_2Gb_x8"

# Allow override from command line argument if provided
if [ -n "$1" ] && [ "$1" != "UNKNOWN" ]; then
    MODEL_PATH="$1"
fi

if [ "$MODEL_PATH" != "UNKNOWN" ] && [ -n "$MODEL_PATH" ]; then
    echo "✅ Using downloaded DDR model at: $MODEL_PATH"
    
    # Find main RTL file
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
            echo "✅ Verilator found, starting build..."
            verilator --version
            
            OBJ_DIR="$MODEL_PATH/obj_dir_smoke"
            echo "Setting up include paths..."
            
            # Build include directories
            INCLUDE_DIRS=""
            if [ -d "$MODEL_PATH/rtl/include" ]; then
                INCLUDE_DIRS="$INCLUDE_DIRS -I$MODEL_PATH/rtl/include"
                echo "✅ Added include path: $MODEL_PATH/rtl/include"
            fi
            if [ -d "$MODEL_PATH/include" ]; then
                INCLUDE_DIRS="$INCLUDE_DIRS -I$MODEL_PATH/include"
                echo "✅ Added include path: $MODEL_PATH/include"
            fi
            if [ -d "$MODEL_PATH/rtl" ]; then
                INCLUDE_DIRS="$INCLUDE_DIRS -I$MODEL_PATH/rtl"
                echo "✅ Added include path: $MODEL_PATH/rtl"
            fi
            
            echo "Include directories: $INCLUDE_DIRS"
            echo "Building with main file: $MAIN_RTL_FILE"
            
            # Check if main RTL file has timescale directive and add if missing
            if ! grep -q "^\`timescale" "$MAIN_RTL_FILE"; then
                echo "⚠️ Adding missing timescale directive to RTL file..."
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
            TEMP_CONTROLLER="$MODEL_PATH/ddr2_controller_corrected.sv"
            echo "Creating corrected controller file with proper type names..."
            
            # Fix the type name mismatch in the controller
            sed 's/ctrl_state_t/ddr2_state_t/g' "$MAIN_RTL_FILE" > "$TEMP_CONTROLLER"
            
            echo "Using corrected controller file: $TEMP_CONTROLLER"
            
            # Use Verilator with the corrected file
            verilator --cc --exe --build \
                --top-module ddr2_controller \
                --Mdir "$OBJ_DIR" \
                -CFLAGS "-DSMOKE_TEST -O0" \
                --timescale 1ns/1ps \
                -Wno-MODDUP \
                -Wno-TIMESCALEMOD \
                $INCLUDE_DIRS \
                "$TEMP_CONTROLLER" \
                "$MODEL_PATH/simple_testbench.cpp" \
                -o smoke_test_enhanced
            
            if [ $? -eq 0 ]; then
                echo "✅ Smoke test build completed successfully!"
                echo "✅ Executable: $OBJ_DIR/smoke_test_enhanced"
                
                echo ""
                echo "=== RUNNING SMOKE TEST ==="
                cd "$OBJ_DIR"
                ./smoke_test_enhanced
                if [ $? -eq 0 ]; then
                    echo "✅ Smoke test execution completed successfully!"
                else
                    echo "❌ Smoke test execution failed"
                fi
            else
                echo "❌ Build failed"
            fi
        else
            echo "❌ Verilator not found. Please install Verilator first."
            echo "Ubuntu/Debian: sudo apt-get install verilator"
            echo "CentOS/RHEL: sudo yum install verilator"
            echo "macOS: brew install verilator"
        fi
    else
        echo "❌ No DDR controller RTL files found in downloaded model"
        echo "Available RTL files:"
        find "$MODEL_PATH" -name "*.sv" -o -name "*.v" 2>/dev/null || echo "No RTL files found"
    fi
else
    echo "❌ No DDR model downloaded yet. Please download a model first using the 'Download...' button."
    echo "Workspace path: $2"
fi