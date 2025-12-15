#!/bin/bash

echo "🧹 Cleaning Xcode build system..."

# 1. Kill Xcode if running
killall Xcode 2>/dev/null
sleep 2

# 2. Remove all derived data
echo "  → Removing DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/EventPassUG-*
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex

# 3. Remove project-specific build folders
echo "  → Removing build folders..."
rm -rf .build
rm -rf build

# 4. Remove workspace user data (state that might be corrupted)
echo "  → Cleaning workspace state..."
rm -rf EventPassUG.xcodeproj/project.xcworkspace/xcuserdata
rm -rf EventPassUG.xcodeproj/xcuserdata

# 5. Clear system caches
echo "  → Clearing system caches..."
rm -rf ~/Library/Caches/com.apple.dt.Xcode

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "Next steps:"
echo "1. Open Xcode: open EventPassUG.xcodeproj"
echo "2. Wait for indexing to complete"
echo "3. Product → Clean Build Folder (⌘⇧K)"
echo "4. Product → Build (⌘B)"
echo ""
