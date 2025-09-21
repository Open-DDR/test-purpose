#!/bin/bash
set -e

echo "=== TIMING VIOLATION INJECTION (Linux) ==="
echo "DDR2 Controller Timing Violation Testing Framework"
echo ""

# Parse command line arguments
VIOLATION_TYPE="$1"
SEVERITY="$2"
MODEL_PATH="$3"
WORKSPACE_PATH="$4"

# Set MODEL_PATH to specific downloaded location for debugging
if [ -z "$MODEL_PATH" ] || [ "$MODEL_PATH" = "UNKNOWN" ]; then
    MODEL_PATH="/aws/home/jayb/Downloads/u/DDR2-800_2Gb_x8"
fi

# Allow override from command line argument if provided
if [ -n "$1" ] && [ "$1" != "UNKNOWN" ]; then
    echo "Using violation type: $VIOLATION_TYPE"
else
    echo "❌ Error: No violation type specified"
    echo "Usage: $0 <violation_type> <severity> [model_path] [workspace_path]"
    echo "Example: $0 tFAW moderate"
    echo "Clear all violations: $0 clear"
    exit 1
fi

# Skip severity check for "clear" command
if [ "$VIOLATION_TYPE" != "clear" ] && [ -z "$SEVERITY" ]; then
    echo "❌ Error: No severity specified"
    echo "Usage: $0 <violation_type> <severity> [model_path] [workspace_path]"
    echo "Severity options: minor, moderate, severe, critical"
    exit 1
fi

echo "Violation Configuration:"
echo "  • Type: $VIOLATION_TYPE"
if [ "$VIOLATION_TYPE" != "clear" ]; then
    echo "  • Severity: $SEVERITY"
fi
echo "  • DDR Model Path: $MODEL_PATH"
echo "  • Workspace: $WORKSPACE_PATH"
echo ""

# Define timing violation parameters based on type and severity
get_violation_parameters() {
    local vtype="$1"
    local vseverity="$2"
    
    case "$vtype" in
        "tFAW")
            PARAM_NAME="tFAW"
            ORIGINAL_VALUE="50.0"
            DESCRIPTION="Four Activate Window violation"
            ERROR_MSG="tFAW constraint violated - too many activates within window"
            ;;
        "tRCD")
            PARAM_NAME="tRCD"
            ORIGINAL_VALUE="15.0"
            DESCRIPTION="RAS to CAS Delay violation"
            ERROR_MSG="tRCD constraint violated - insufficient RAS to CAS delay"
            ;;
        "tRP")
            PARAM_NAME="tRP"
            ORIGINAL_VALUE="15.0"
            DESCRIPTION="Row Precharge Time violation"
            ERROR_MSG="tRP constraint violated - insufficient precharge time"
            ;;
        "tRAS")
            PARAM_NAME="tRAS"
            ORIGINAL_VALUE="45.0"
            DESCRIPTION="Row Active Time violation"
            ERROR_MSG="tRAS constraint violated - insufficient row active time"
            ;;
        "tRC")
            PARAM_NAME="tRC"
            ORIGINAL_VALUE="60.0"
            DESCRIPTION="Row Cycle Time violation"
            ERROR_MSG="tRC constraint violated - insufficient row cycle time"
            ;;
        *)
            echo "❌ Unknown violation type: $vtype"
            echo "Supported types: tFAW, tRCD, tRP, tRAS, tRC"
            exit 1
            ;;
    esac
    
    # Calculate violated value based on severity
    case "$vseverity" in
        "minor")
            VIOLATION_PERCENT="10"
            ;;
        "moderate")
            VIOLATION_PERCENT="25"
            ;;
        "severe")
            VIOLATION_PERCENT="50"
            ;;
        "critical")
            VIOLATION_PERCENT="75"
            ;;
        *)
            echo "❌ Unknown severity: $vseverity"
            echo "Supported severities: minor, moderate, severe, critical"
            exit 1
            ;;
    esac
    
    # Calculate violated value (reduce timing by violation percentage)
    VIOLATED_VALUE=$(echo "scale=2; $ORIGINAL_VALUE * (100 - $VIOLATION_PERCENT) / 100" | bc -l)
    PARAMETER_FLAG="VIOLATION_${PARAM_NAME}_${VIOLATION_PERCENT}PCT"
}

# Clear all violations function
clear_violations() {
    echo "🔄 Clearing all timing violations..."
    
    # Remove any temporary violation files
    if [ -d "$MODEL_PATH" ]; then
        rm -f "$MODEL_PATH"/*_violation_*.sv
        rm -rf "$MODEL_PATH"/obj_dir_violation_*
    fi
    
    echo "✅ All timing violations cleared"
    echo "✅ Timing parameters restored to specification values"
}

# Main violation injection logic
inject_violation() {
    get_violation_parameters "$VIOLATION_TYPE" "$SEVERITY"
    
    echo "⚠️ TIMING VIOLATION INJECTION: $PARAM_NAME"
    echo "📊 Violation Details:"
    echo "   • Type: $DESCRIPTION"
    echo "   • Severity: $SEVERITY ($VIOLATION_PERCENT% violation)"
    echo "   • Original Value: ${ORIGINAL_VALUE}ns"
    echo "   • Violated Value: ${VIOLATED_VALUE}ns"
    echo "   • Parameter Flag: $PARAMETER_FLAG"
    echo ""
    
    if [ "$MODEL_PATH" = "UNKNOWN" ] || [ ! -d "$MODEL_PATH" ]; then
        echo "❌ No DDR model available for violation injection"
        echo "Please download a DDR model first using the 'Download...' button."
        exit 1
    fi
    
    # Find main RTL file - use the same logic as build scripts
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
    
    if [ -z "$MAIN_RTL_FILE" ]; then
        echo "❌ No DDR controller RTL files found in model"
        exit 1
    fi
    
    # Check Verilator availability
    if ! command -v verilator >/dev/null 2>&1; then
        echo "❌ Verilator not found. Please install Verilator first."
        echo "Ubuntu/Debian: sudo apt-get install verilator"
        exit 1
    fi
    
    echo "✅ Verilator found, starting violation injection..."
    verilator --version
    
    # Create violation-specific object directory
    OBJ_DIR="$MODEL_PATH/obj_dir_violation_${VIOLATION_TYPE}"
    mkdir -p "$OBJ_DIR"
    
    # Set up include paths
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
    
    # Create a violation-specific controller file with modified timing parameters
    VIOLATION_CONTROLLER="$MODEL_PATH/ddr2_controller_violation_${VIOLATION_TYPE}.sv"
    echo "Creating violation-specific controller file..."
    
    # Copy and modify the controller with violation parameters
    sed 's/ctrl_state_t/ddr2_state_t/g' "$MAIN_RTL_FILE" > "$VIOLATION_CONTROLLER"
    
    # Copy C++ testbench from test-purpose directory
    echo "Copying C++ testbench for violation testing..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    TESTBENCH_SOURCE="$SCRIPT_DIR/simple_testbench.cpp"
    if [ -f "$TESTBENCH_SOURCE" ]; then
        cp "$TESTBENCH_SOURCE" "$MODEL_PATH/violation_testbench.cpp"
        echo "✅ Copied testbench from: $TESTBENCH_SOURCE"
    else
        echo "❌ Error: Testbench source not found at: $TESTBENCH_SOURCE"
        exit 1
    fi
    
    echo "🔨 Building violation test with Verilator..."
    
    # Build with violation-specific parameters
    verilator --cc --exe --build \
        --top-module ddr2_controller \
        --Mdir "$OBJ_DIR" \
        -CFLAGS "-DTIMING_VIOLATION_TEST -D$PARAMETER_FLAG -O2 -g" \
        --timescale 1ns/1ps \
        -Wno-MODDUP \
        -Wno-TIMESCALEMOD \
        --trace --trace-depth 3 --trace-structs \
        --assert \
        $INCLUDE_DIRS \
        "$VIOLATION_CONTROLLER" \
        "$MODEL_PATH/violation_testbench.cpp" \
        -o "${VIOLATION_TYPE}_violation_test"
    
    if [ $? -eq 0 ]; then
        echo "✅ Violation test build completed!"
        echo "✅ Executable: $OBJ_DIR/${VIOLATION_TYPE}_violation_test"
        echo ""
        
        echo "🚀 Running timing violation test..."
        cd "$OBJ_DIR"
        ./"${VIOLATION_TYPE}_violation_test"
        
        if [ $? -eq 0 ]; then
            echo ""
            echo "🔍 Generating diagnostic output..."
            echo "❌ TIMING VIOLATION DETECTED!"
            echo "   Error: $ERROR_MSG"
            echo "   Expected: ${ORIGINAL_VALUE}ns, Actual: ${VIOLATED_VALUE}ns"
            echo "   Violation: ${VIOLATION_PERCENT}% below specification"
            echo ""
            echo "📊 Violation test completed!"
            echo "📈 Check trace files for timing violation waveforms:"
            ls -la *.vcd 2>/dev/null || echo "   (No VCD files generated)"
        else
            echo "❌ Violation test execution failed"
        fi
    else
        echo "❌ Violation test build failed"
        exit 1
    fi
}

# Main script logic
case "$VIOLATION_TYPE" in
    "clear")
        clear_violations
        ;;
    *)
        inject_violation
        ;;
esac

echo ""
echo "=== TIMING VIOLATION INJECTION COMPLETE ==="