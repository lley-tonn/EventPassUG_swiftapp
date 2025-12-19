#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'EventPassUG.xcodeproj'
project = Xcodeproj::Project.open(project_path)
project_root = File.dirname(File.dirname(project_path))

puts "🔧 Removing orphaned file references from build phases..."

target = project.targets.first
build_phase = target.source_build_phase

removed_count = 0

# Remove files that don't exist
build_phase.files.to_a.each do |build_file|
  file_ref = build_file.file_ref
  next unless file_ref

  # Get the real path
  real_path = file_ref.real_path.to_s

  # Check if file exists
  unless File.exist?(real_path)
    puts "  ✗ Removing missing: #{file_ref.display_name} (#{real_path})"
    build_phase.remove_file_reference(file_ref)
    removed_count += 1
  end
end

puts "\n✅ Removed #{removed_count} orphaned references"

# Now add all existing Swift files that aren't in the build phase
puts "\n🔧 Adding missing Swift files to build phase..."

added_count = 0
swift_files = Dir.glob(File.join(project_root, 'EventPassUG', '**', '*.swift'))

swift_files.each do |file_path|
  relative_path = file_path.sub("#{project_root}/EventPassUG/", '')

  # Check if this file is already in the project
  file_ref = project.files.find { |f| f.real_path.to_s == file_path }

  if file_ref
    # Check if it's in the build phase
    in_build_phase = build_phase.files.any? { |bf| bf.file_ref == file_ref }

    unless in_build_phase
      build_phase.add_file_reference(file_ref)
      puts "  + Added: #{relative_path}"
      added_count += 1
    end
  end
end

puts "\n✅ Added #{added_count} missing files"

project.save
puts "💾 Project saved!"
