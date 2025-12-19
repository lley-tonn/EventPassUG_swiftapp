#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'EventPassUG.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "🔧 Fixing Assets.xcassets reference..."

# Find the Assets.xcassets reference
assets_ref = project.files.find { |f| f.path && f.path.include?('Assets.xcassets') }

if assets_ref
  puts "Found Assets: #{assets_ref.path}"

  # Update the path to the new location
  new_path = 'Resources/Assets.xcassets'
  assets_ref.path = new_path

  puts "Updated path to: #{new_path}"

  project.save
  puts "✅ Assets reference fixed!"
else
  puts "⚠️ Assets.xcassets reference not found"
end
