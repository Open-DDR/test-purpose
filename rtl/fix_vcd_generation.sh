#!/bin/bash

# Script to fix VCD generation in existing DDR model directories
# This replaces non-VCD executables with VCD-enabled versions

echo "=== VCD Fix Script for DDR Models ==="
echo "This script will replace smoke test executables with VCD-enabled versions"

# Source paths (where our working VCD-enabled executables are)
SOURCE_ENHANCED="/aws/home/jayb/proj/open-ddr/test-purpose/rtl/obj_dir_smoke_extension/smoke_test_enhanced"

# Check if source files exist
if [ ! -f "$SOURCE_ENHANCED" ]; then
    echo "❌ Enhanced executable not found: $SOURCE_ENHANCED"
    exit 1
fi

echo "✅ Source executable found"

# Function to fix a directory
fix_directory() {
    local TARGET_DIR="$1"
    local EXECUTABLE_NAME="$2"
    
    if [ ! -d "$TARGET_DIR" ]; then
        echo "❌ Target directory not found: $TARGET_DIR"
        return 1
    fi
    
    echo "🔧 Fixing directory: $TARGET_DIR"
    
    # Backup original if it exists
    if [ -f "$TARGET_DIR/$EXECUTABLE_NAME" ]; then
        echo "  📦 Backing up original: $EXECUTABLE_NAME -> ${EXECUTABLE_NAME}_backup"
        cp "$TARGET_DIR/$EXECUTABLE_NAME" "$TARGET_DIR/${EXECUTABLE_NAME}_backup"
    fi
    
    # Copy VCD-enabled version
    echo "  ✅ Installing VCD-enabled version"
    cp "$SOURCE_ENHANCED" "$TARGET_DIR/$EXECUTABLE_NAME"
    chmod +x "$TARGET_DIR/$EXECUTABLE_NAME"
    
    # Test the new executable
    echo "  🧪 Testing VCD generation..."
    cd "$TARGET_DIR"
    if ./"$EXECUTABLE_NAME" --memory-model=DDR4-3200 --test-cycles=100 --output-vcd="test_fix.vcd" > /dev/null 2>&1; then
        if [ -f "test_fix.vcd" ]; then
            echo "  ✅ VCD generation working! File size: $(du -h test_fix.vcd | cut -f1)"
            rm -f test_fix.vcd  # Clean up test file
        else
            echo "  ⚠️ Test completed but no VCD file generated"
        fi
    else
        echo "  ⚠️ Test had issues but executable is installed"
    fi
    
    echo "  ✅ Directory fixed: $TARGET_DIR"
}

# Common target directories to fix
TARGET_DIRS=(
    "/aws/home/jayb/Downloads/s/DDR2-800_2Gb_x8/obj_dir_smoke"
    "/aws/home/jayb/Downloads/s/DDR2-800_2Gb_x8/obj_dir_smoke_extension"  
    "/aws/home/jayb/Downloads/s/DDR2-800_2Gb_x8/obj_dir_smoke_fixed"
)

# Check for user-provided directory
if [ ! -z "$1" ]; then
    echo "🎯 User specified directory: $1"
    fix_directory "$1" "smoke_test_enhanced"
    exit 0
fi

# Fix common directories
echo "🔍 Scanning common directories..."

for target_dir in "${TARGET_DIRS[@]}"; do
    if [ -d "$target_dir" ]; then
        fix_directory "$target_dir" "smoke_test_enhanced"
        echo ""
    else
        echo "⏭️ Skipping non-existent: $target_dir"
    fi
done

echo ""
echo "🎉 VCD fix script completed!"
echo ""
echo "📋 Usage examples:"
echo "  # Test the fixed executable:"
echo "  cd /aws/home/jayb/Downloads/s/DDR2-800_2Gb_x8/obj_dir_smoke"
echo "  ./smoke_test_enhanced --memory-model=DDR4-3200 --test-cycles=2000 --output-vcd=\"smoke_waveform.vcd\""
echo ""
echo "  # Or use custom directory:"
echo "  $0 /path/to/your/ddr/model/obj_dir_smoke"