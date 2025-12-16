#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'EventPassUG.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.first

# Find or create the Services group
services_group = project.main_group.find_subpath('EventPassUG/Services', true)

# Check if file already exists in project
file_ref = services_group.files.find { |f| f.path == 'NotificationAnalytics.swift' }

unless file_ref
  # Add the file to the Services group
  file_ref = services_group.new_file('NotificationAnalytics.swift')

  # Add the file to the target's compile sources
  target.source_build_phase.add_file_reference(file_ref)

  puts "✅ Added NotificationAnalytics.swift to project"
else
  puts "ℹ️ NotificationAnalytics.swift already exists in project"
end

# Save the project
project.save

puts "✅ Project saved successfully"
