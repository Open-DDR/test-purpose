#!/bin/bash
set -e

echo "=== CUSTOM TEST BUILD (Linux) ==="
echo "Building full-featured DDR controller..."

MODEL_PATH="$1"

if [ "$MODEL_PATH" != "UNKNOWN" ] && [ -n "$MODEL_PATH" ]; then
    echo "✅ Using downloaded DDR model at: $MODEL_PATH"
    
    # Find main RTL file
    MAIN_RTL_FILE=$(find "$MODEL_PATH" -name "*ddr*controller*.sv" | grep -v "_tb\|testbench" | head -1)
    if [ -z "$MAIN_RTL_FILE" ]; then
        MAIN_RTL_FILE=$(find "$MODEL_PATH" -name "*controller*.sv" | grep -v "_tb\|testbench" | head -1)
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
            
            verilator --cc --exe --build --top-module ddr2_controller --Mdir "$OBJ_DIR" -CFLAGS "-DCUSTOM_TEST -O2 -g" --trace --trace-depth 3 --trace-structs --assert --coverage --timescale 1ns/1ps $INCLUDE_DIRS "$MAIN_RTL_FILE" $PKG_FILES -o custom_test
            echo "✅ Custom test build completed!"
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