#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'EventPassUG.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "🔧 Re-adding all Swift files to build phase...\n"

target = project.targets.first
build_phase = target.source_build_phase

# Get all Swift file references in the project
all_swift_files = project.files.select { |f| f.path&.end_with?('.swift') }

puts "📊 Found #{all_swift_files.count} Swift files in project"
puts "📊 Currently #{build_phase.files.count} files in build phase\n"

added_count = 0

all_swift_files.each do |file_ref|
  # Check if already in build phase
  in_build_phase = build_phase.files.any? { |bf| bf.file_ref == file_ref }

  unless in_build_phase
    build_phase.add_file_reference(file_ref)
    puts "  ✓ Added: #{file_ref.display_name}"
    added_count += 1
  end
end

puts "\n✅ Added #{added_count} files to build phase"
puts "📊 Build phase now has #{build_phase.files.count} files\n"

project.save
puts "💾 Project saved!"
