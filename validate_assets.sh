#!/bin/bash

echo "🔍 Validating Asset Catalog Images..."
echo ""

cd EventPassUG/Assets.xcassets

# Check all PNG files
find . -name "*.png" -type f | while read img; do
    if file "$img" | grep -q "PNG image data"; then
        echo "✅ $img"
    else
        echo "❌ $img - CORRUPTED OR INVALID"
    fi
done

echo ""
echo "✅ Validation complete"
