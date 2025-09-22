#!/bin/bash
set -e

echo "=== SIMPLE SYSTEMC TEST ==="
echo "Basic SystemC compilation and test"
echo ""

# Parse command line arguments
TEST_TYPE="${1:-basic}"
MODEL_PATH="${2:-/aws/home/jayb/Downloads/u/DDR2-800_2Gb_x8}"
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
