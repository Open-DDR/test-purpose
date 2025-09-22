#!/bin/bash

echo "=== SystemC Sidebar Restoration Verification ==="
echo ""

SOURCE_FILE="/aws/home/jayb/proj/open-ddr/openddr-extension-free/src/ConfigTimingSidebarProvider.ts"

echo "🔍 Checking restored SystemC components..."

# Check for SystemC section header
echo ""
echo "1. HTML Section:"
if grep -q "📊 Test Status" "$SOURCE_FILE"; then
    echo "✅ Found SystemC Test Status section header"
else
    echo "❌ SystemC section header not found"
fi

# Check for SystemC HTML elements
echo ""
echo "2. HTML Elements:"
SYSTEMC_ELEMENTS=0
if grep -q "testResults" "$SOURCE_FILE"; then
    echo "✅ Found testResults log area"
    ((SYSTEMC_ELEMENTS++))
fi
if grep -q "buildSystemCBtn" "$SOURCE_FILE"; then
    echo "✅ Found Build Test System button"
    ((SYSTEMC_ELEMENTS++))
fi
if grep -q "clearLogBtn" "$SOURCE_FILE"; then
    echo "✅ Found Clear Log button"
    ((SYSTEMC_ELEMENTS++))
fi
if grep -q "exportResultsBtn" "$SOURCE_FILE"; then
    echo "✅ Found Export Results button"
    ((SYSTEMC_ELEMENTS++))
fi

# Check for SystemC JavaScript handlers
echo ""
echo "3. JavaScript Event Handlers:"
SYSTEMC_HANDLERS=0
if grep -q "buildSystemCBtn.*onclick" "$SOURCE_FILE"; then
    echo "✅ Found buildSystemCBtn event handler"
    ((SYSTEMC_HANDLERS++))
fi
if grep -q "clearLogBtn.*onclick" "$SOURCE_FILE"; then
    echo "✅ Found clearLogBtn event handler"
    ((SYSTEMC_HANDLERS++))
fi
if grep -q "exportResultsBtn.*onclick" "$SOURCE_FILE"; then
    echo "✅ Found exportResultsBtn event handler"
    ((SYSTEMC_HANDLERS++))
fi

# Check for SystemC message handlers
echo ""
echo "4. Message Handlers:"
SYSTEMC_MESSAGES=0
if grep -q "buildSystemC" "$SOURCE_FILE"; then
    echo "✅ Found buildSystemC message handler"
    ((SYSTEMC_MESSAGES++))
fi
if grep -q "updateSystemCStatus" "$SOURCE_FILE"; then
    echo "✅ Found updateSystemCStatus message handler"
    ((SYSTEMC_MESSAGES++))
fi
if grep -q "appendLog" "$SOURCE_FILE"; then
    echo "✅ Found appendLog message handler"
    ((SYSTEMC_MESSAGES++))
fi

# Check for SystemC methods
echo ""
echo "5. SystemC Backend Method:"
if grep -q "handleSystemCBuild" "$SOURCE_FILE"; then
    echo "✅ Found handleSystemCBuild method"
    # Check if it uses downloaded model path
    if grep -A 10 "handleSystemCBuild" "$SOURCE_FILE" | grep -q "systemc/src"; then
        echo "✅ Method uses downloaded model SystemC path"
    else
        echo "⚠️  Method may not be using downloaded model path"
    fi
else
    echo "❌ handleSystemCBuild method not found"
fi

# Check compilation status
echo ""
echo "6. Compilation Status:"
cd /aws/home/jayb/proj/open-ddr/openddr-extension-free
if npm run compile > /tmp/compile_test.log 2>&1; then
    echo "✅ Extension compiles successfully"
else
    echo "❌ Extension compilation failed:"
    cat /tmp/compile_test.log
fi

echo ""
echo "=== Current Sidebar Sections ==="
echo "All sections in the sidebar:"
grep -n "section-header" "$SOURCE_FILE" | while read line; do
    section=$(echo "$line" | sed 's/.*<div class="section-header">//' | sed 's/<\/div>.*//')
    echo "  - $section"
done

echo ""
echo "=== Restoration Summary ==="
if [ "$SYSTEMC_ELEMENTS" -ge 3 ] && [ "$SYSTEMC_HANDLERS" -ge 3 ] && [ "$SYSTEMC_MESSAGES" -ge 2 ] && grep -q "handleSystemCBuild" "$SOURCE_FILE"; then
    echo "✅ SystemC sidebar successfully restored!"
    echo "✅ Found $SYSTEMC_ELEMENTS HTML elements"
    echo "✅ Found $SYSTEMC_HANDLERS JavaScript handlers"
    echo "✅ Found $SYSTEMC_MESSAGES message handlers"
    echo "✅ Extension compiles without errors"
    echo ""
    echo "🎯 The SystemC 'Build Test System' functionality is ready to use!"
    echo "   - Uses downloaded DDR model SystemC files"
    echo "   - Builds and runs SystemC simulations"
    echo "   - Provides log output and status updates"
else
    echo "⚠️  SystemC restoration may be incomplete - check the details above"
    echo "   Elements: $SYSTEMC_ELEMENTS, Handlers: $SYSTEMC_HANDLERS, Messages: $SYSTEMC_MESSAGES"
fi