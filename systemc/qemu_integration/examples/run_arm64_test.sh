#!/bin/bash

# ARM64 System Test with OpenDDR DDR SystemC Model
# This script demonstrates how to run QEMU with the SystemC memory backend

set -e

# Configuration
SYSTEMC_PORT=8888
MEMORY_SIZE=1024  # MB
QEMU_MEMORY=1G
KERNEL_IMAGE="vmlinux-arm64"
INITRD_IMAGE="initrd-arm64.img"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}OpenDDR DDR SystemC + QEMU ARM64 Test${NC}"
echo "=========================================="

# Check if SystemC server is available
if ! command -v ../systemc_bridge/OpenDDR_systemc_server &> /dev/null; then
    echo -e "${RED}Error: SystemC server not found. Please build it first:${NC}"
    echo "  cd ../systemc_bridge && make"
    exit 1
fi

# Check if QEMU is available
if ! command -v qemu-system-aarch64 &> /dev/null; then
    echo -e "${RED}Error: qemu-system-aarch64 not found. Please install QEMU.${NC}"
    exit 1
fi

# Start SystemC server in background
echo -e "${YELLOW}Starting OpenDDR SystemC server...${NC}"
../systemc_bridge/OpenDDR_systemc_server \
    --port $SYSTEMC_PORT \
    --memory-size $MEMORY_SIZE \
    --arch arm64 \
    --trace-file OpenDDR_arm64_trace.vcd &

SYSTEMC_PID=$!
echo "SystemC server started with PID: $SYSTEMC_PID"

# Wait for server to initialize
sleep 3

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}Cleaning up...${NC}"
    if kill -0 $SYSTEMC_PID 2>/dev/null; then
        echo "Stopping SystemC server (PID: $SYSTEMC_PID)"
        
        # First try SIGTERM for graceful shutdown
        kill -TERM $SYSTEMC_PID
        
        # Wait for process to terminate gracefully (VCD file needs time to close)
        local timeout=5
        local count=0
        while kill -0 $SYSTEMC_PID 2>/dev/null && [ $count -lt $timeout ]; do
            sleep 1
            count=$((count + 1))
        done
        
        # If process is still running, try SIGINT
        if kill -0 $SYSTEMC_PID 2>/dev/null; then
            echo "Sending SIGINT for graceful shutdown..."
            kill -INT $SYSTEMC_PID 2>/dev/null || true
            sleep 3
        fi
        
        # If process is still running, force kill it
        if kill -0 $SYSTEMC_PID 2>/dev/null; then
            echo "Process didn't terminate gracefully, force killing..."
            kill -9 $SYSTEMC_PID 2>/dev/null || true
            sleep 1
        fi
        
        # Final wait to clean up zombie process
        wait $SYSTEMC_PID 2>/dev/null || true
    fi
    echo "Cleanup complete"
}

# Set trap for cleanup
trap cleanup EXIT INT TERM

# Test SystemC server connectivity
echo -e "${YELLOW}Testing SystemC server connectivity...${NC}"
if ../systemc_bridge/test_client --server 127.0.0.1:$SYSTEMC_PORT --test basic; then
    echo -e "${GREEN}SystemC server test passed!${NC}"
else
    echo -e "${RED}SystemC server test failed!${NC}"
    exit 1
fi

# Check if kernel image exists
if [ ! -f "$KERNEL_IMAGE" ]; then
    echo -e "${YELLOW}Warning: Kernel image '$KERNEL_IMAGE' not found.${NC}"
    echo "Creating a simple test kernel command..."
    KERNEL_CMD="-kernel /dev/null"
    echo -e "${YELLOW}Note: This will boot to QEMU monitor only.${NC}"
else
    KERNEL_CMD="-kernel $KERNEL_IMAGE"
fi

# Check if initrd exists
if [ -f "$INITRD_IMAGE" ]; then
    INITRD_CMD="-initrd $INITRD_IMAGE"
else
    INITRD_CMD=""
    echo -e "${YELLOW}Note: No initrd image found, booting without initrd.${NC}"
fi

echo -e "${YELLOW}Starting QEMU ARM64 system...${NC}"
echo "Configuration:"
echo "  Architecture: ARM64 (Cortex-A57)"
echo "  Memory: $QEMU_MEMORY (via SystemC backend)"
echo "  SystemC Port: $SYSTEMC_PORT"
echo "  Kernel: $KERNEL_IMAGE"
echo ""
echo -e "${GREEN}QEMU will connect to SystemC server for memory operations${NC}"
echo -e "${YELLOW}Press Ctrl+A, X to exit QEMU${NC}"
echo ""

# Note: This is a conceptual command. Actual QEMU integration would require
# a custom memory backend plugin or patches to QEMU
echo "# Conceptual QEMU command (requires SystemC backend support):"
echo "qemu-system-aarch64 \\"
echo "  -M virt \\"
echo "  -cpu cortex-a57 \\"
echo "  -m $QEMU_MEMORY \\"
echo "  -object memory-backend-systemc,id=mem0,size=$QEMU_MEMORY,server=localhost:$SYSTEMC_PORT \\"
echo "  -numa node,memdev=mem0 \\"
echo "  $KERNEL_CMD \\"
echo "  $INITRD_CMD \\"
echo "  -append 'console=ttyAMA0 root=/dev/ram0 rw' \\"
echo "  -nographic \\"
echo "  -monitor stdio"
echo ""

# For demonstration, run a memory stress test instead
echo -e "${YELLOW}Running memory stress test via SystemC...${NC}"
echo "Note: Test client has been optimized with request pacing to prevent queue overflow"
echo "Waiting for server to be ready for new connection..."
sleep 2
../systemc_bridge/test_client --server 127.0.0.1:$SYSTEMC_PORT --test performance

echo ""
echo -e "${GREEN}ARM64 test completed!${NC}"
echo "SystemC trace saved to: OpenDDR_arm64_trace.vcd"
echo ""
echo "To view the trace:"
echo "  gtkwave OpenDDR_arm64_trace.vcd"
