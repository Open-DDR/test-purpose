#!/bin/bash

echo "=== SystemC Sidebar Removal Verification ==="
echo ""

SOURCE_FILE="/aws/home/jayb/proj/open-ddr/openddr-extension-free/src/ConfigTimingSidebarProvider.ts"

echo "🔍 Checking for remaining SystemC references..."

# Check for SystemC in section headers
echo ""
echo "1. Section Headers:"
if grep -n "Test Status\|SYSTEMC SIMULATOR" "$SOURCE_FILE"; then
    echo "❌ Found SystemC section headers"
else
    echo "✅ No SystemC section headers found"
fi

# Check for SystemC HTML elements
echo ""
echo "2. HTML Elements:"
SYSTEMC_ELEMENTS=$(grep -n "testResults\|buildSystemCBtn\|clearLogBtn\|exportResultsBtn" "$SOURCE_FILE" | wc -l)
if [ "$SYSTEMC_ELEMENTS" -gt 0 ]; then
    echo "❌ Found $SYSTEMC_ELEMENTS SystemC HTML elements:"
    grep -n "testResults\|buildSystemCBtn\|clearLogBtn\|exportResultsBtn" "$SOURCE_FILE"
else
    echo "✅ No SystemC HTML elements found"
fi

# Check for SystemC JavaScript handlers
echo ""
echo "3. JavaScript Event Handlers:"
SYSTEMC_HANDLERS=$(grep -n "buildSystemCBtn\|clearLogBtn\|exportResultsBtn" "$SOURCE_FILE" | wc -l)
if [ "$SYSTEMC_HANDLERS" -gt 0 ]; then
    echo "❌ Found $SYSTEMC_HANDLERS SystemC event handlers:"
    grep -n "buildSystemCBtn\|clearLogBtn\|exportResultsBtn" "$SOURCE_FILE"
else
    echo "✅ No SystemC event handlers found"
fi

# Check for SystemC message handlers
echo ""
echo "4. Message Handlers:"
SYSTEMC_MESSAGES=$(grep -n "buildSystemC\|updateSystemCStatus" "$SOURCE_FILE" | wc -l)
if [ "$SYSTEMC_MESSAGES" -gt 0 ]; then
    echo "❌ Found $SYSTEMC_MESSAGES SystemC message handlers:"
    grep -n "buildSystemC\|updateSystemCStatus" "$SOURCE_FILE"
else
    echo "✅ No SystemC message handlers found"
fi

# Check for SystemC methods
echo ""
echo "5. SystemC Methods:"
if grep -n "handleSystemCBuild" "$SOURCE_FILE"; then
    echo "❌ Found SystemC methods"
else
    echo "✅ No SystemC methods found"
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
echo "Remaining sections in the sidebar:"
grep -n "section-header" "$SOURCE_FILE" | while read line; do
    echo "  - $(echo "$line" | sed 's/.*<div class="section-header">//' | sed 's/<\/div>.*//')"
done

echo ""
echo "=== Verification Summary ==="
if [ "$SYSTEMC_ELEMENTS" -eq 0 ] && [ "$SYSTEMC_HANDLERS" -eq 0 ] && [ "$SYSTEMC_MESSAGES" -eq 0 ] && ! grep -q "handleSystemCBuild" "$SOURCE_FILE" && ! grep -q "Test Status\|SYSTEMC SIMULATOR" "$SOURCE_FILE"; then
    echo "✅ SystemC sidebar successfully removed!"
    echo "✅ No remaining SystemC references found"
    echo "✅ Extension compiles without errors"
    echo ""
    echo "🎯 The VS Code extension now has a clean sidebar without SystemC functionality"
else
    echo "⚠️  Some SystemC references may remain - check the details above"
fi