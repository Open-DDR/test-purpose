#!/bin/bash
set -e

# Check if this is a SystemC test request  
if [ "$1" = "systemc" ]; then
    exec "$(dirname "$0")/simple_systemc_test.sh" "${@:2}"
fi

echo "=== SMOKE TEST BUILD (Linux) ==="
echo "Building DDR controller with Verilator..."

# Set MODEL_PATH to specific downloaded location for debugging
MODEL_PATH="/aws/home/jayb/Downloads/1/DDR2-800_2Gb_x8"

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
            
            # Use Verilator with the corrected file and VCD tracing
            verilator --cc --exe --build --trace \
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
                ./smoke_test_enhanced --vcd=smoke_waveform.vcd
                if [ $? -eq 0 ]; then
                    echo "✅ Smoke test execution completed successfully!"
                    if [ -f "smoke_waveform.vcd" ]; then
                        echo "✅ VCD file generated: $OBJ_DIR/smoke_waveform.vcd"
                        echo "📊 VCD file size: $(du -h smoke_waveform.vcd | cut -f1)"
                        echo "🔍 You can view this file with GTKWave or VCD viewer extensions"
                    else
                        echo "⚠️ VCD file was not generated"
                    fi
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

# === EMBEDDED SIMPLE SYSTEMC TEST SCRIPT ===
cat > "$(dirname "$0")/simple_systemc_test.sh" << 'SYSTEMC_SCRIPT_EOF'
#!/bin/bash
set -e

echo "=== SIMPLE SYSTEMC TEST ==="
echo "Basic SystemC compilation and test"
echo ""

# Parse command line arguments
TEST_TYPE="${1:-basic}"
MODEL_PATH="${2:-/aws/home/jayb/Downloads/1/DDR2-800_2Gb_x8}"
WORKSPACE_PATH="$3"

echo "SystemC Test Configuration:"
echo "  • Test Type: $TEST_TYPE"
echo "  • Model Path: $MODEL_PATH" 
echo "  • Workspace: $WORKSPACE_PATH"
echo ""

# Check SystemC installation
check_systemc() {
    echo "🔍 Checking SystemC installation..."
    
    # Check for SystemC headers
    if [ -d "/usr/local/systemc/include" ]; then
        SYSTEMC_HOME="/usr/local/systemc"
        echo "✅ Found SystemC installation: $SYSTEMC_HOME"
    elif [ -d "/usr/include/systemc" ]; then
        SYSTEMC_HOME="/usr"
        echo "✅ Found system SystemC installation: $SYSTEMC_HOME"
    elif [ ! -z "$SYSTEMC_HOME" ] && [ -d "$SYSTEMC_HOME/include" ]; then
        echo "✅ Using SYSTEMC_HOME: $SYSTEMC_HOME"
    else
        echo "❌ SystemC not found. Trying to install..."
        
        # Try to install SystemC on Ubuntu/Debian
        if command -v apt-get >/dev/null 2>&1; then
            echo "🔄 Installing libsystemc-dev..."
            sudo apt-get update && sudo apt-get install -y libsystemc-dev || {
                echo "❌ Failed to install SystemC automatically"
                echo "Please install SystemC manually:"
                echo "Ubuntu/Debian: sudo apt-get install libsystemc-dev"
                echo "Or download from: https://systemc.org"
                exit 1
            }
            SYSTEMC_HOME="/usr"
        else
            echo "❌ SystemC not found and cannot auto-install"
            exit 1
        fi
    fi
    
    # Set environment variables
    export SYSTEMC_HOME
    export LD_LIBRARY_PATH="$SYSTEMC_HOME/lib:$LD_LIBRARY_PATH"
    
    echo "✅ SystemC environment configured"
    echo "   SYSTEMC_HOME: $SYSTEMC_HOME"
}

# Create simple SystemC test
create_simple_test() {
    echo "🔨 Creating simple SystemC test..."
    
    # Create test directory
    TEST_DIR="$(dirname "$0")/systemc"
    mkdir -p "$TEST_DIR"
    
    # Simple SystemC test file
    TEST_FILE="$TEST_DIR/simple_test.cpp"
    
    cat > "$TEST_FILE" << 'EOF'
#include <systemc.h>
#include <iostream>

SC_MODULE(simple_counter) {
    sc_in<bool> clk;
    sc_in<bool> reset;
    sc_out<sc_uint<8>> count;
    
    sc_uint<8> counter_value;
    
    SC_CTOR(simple_counter) {
        SC_METHOD(count_process);
        sensitive << clk.pos();
        counter_value = 0;
    }
    
    void count_process() {
        if (reset.read()) {
            counter_value = 0;
        } else {
            counter_value++;
        }
        count.write(counter_value);
        
        if (counter_value % 10 == 0) {
            std::cout << "Counter: " << counter_value << " at " << sc_time_stamp() << std::endl;
        }
    }
};

SC_MODULE(testbench) {
    sc_clock clk;
    sc_signal<bool> reset;
    sc_signal<sc_uint<8>> count;
    
    simple_counter* dut;
    
    SC_CTOR(testbench) : clk("clk", sc_time(10, SC_NS)) {
        dut = new simple_counter("counter");
        dut->clk(clk);
        dut->reset(reset);
        dut->count(count);
        
        SC_THREAD(stimulus);
    }
    
    void stimulus() {
        reset.write(true);
        wait(25, SC_NS);
        reset.write(false);
        
        std::cout << "=== Simple SystemC Counter Test ===" << std::endl;
        std::cout << "Starting counter..." << std::endl;
        
        wait(200, SC_NS);
        
        std::cout << "Final count: " << count.read() << std::endl;
        std::cout << "✅ SystemC test completed successfully!" << std::endl;
        sc_stop();
    }
    
    ~testbench() { delete dut; }
};

int sc_main(int argc, char* argv[]) {
    std::cout << "=== SystemC Simple Test ===" << std::endl;
    testbench tb("tb");
    sc_start();
    return 0;
}
EOF

    echo "✅ Simple SystemC test created: $TEST_FILE"
}

# Build and run SystemC test
build_and_run_test() {
    echo "🔨 Building SystemC test..."
    cd "$TEST_DIR"
    
    BUILD_CMD="g++ -I$SYSTEMC_HOME/include -L$SYSTEMC_HOME/lib -o simple_systemc_test simple_test.cpp -lsystemc -lm"
    echo "🔨 Executing build command:"
    echo "   $BUILD_CMD"
    
    if eval "$BUILD_CMD"; then
        echo "✅ SystemC test build completed successfully!"
        echo "✅ Executable: $TEST_DIR/simple_systemc_test"
        echo ""
        echo "🚀 Running SystemC test..."
        if ./simple_systemc_test; then
            echo ""
            echo "✅ SystemC test execution completed successfully!"
        else
            echo "❌ SystemC test execution failed"
            exit 1
        fi
    else
        echo "❌ SystemC test build failed"
        exit 1
    fi
}

echo "🚀 Starting SystemC test process..."
check_systemc
create_simple_test
build_and_run_test

echo ""
echo "=== SYSTEMC TEST COMPLETE ==="
echo "✅ Test Type: $TEST_TYPE"
echo "✅ Executable: $TEST_DIR/simple_systemc_test"
echo "🎯 Simple SystemC test ready!"
SYSTEMC_SCRIPT_EOF

chmod +x "$(dirname "$0")/simple_systemc_test.sh"
echo "✅ Created simple_systemc_test.sh script"