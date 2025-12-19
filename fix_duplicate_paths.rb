#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'EventPassUG.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "🔧 Fixing duplicate paths in file references...\n"

fixed_count = 0

# Function to get parent group path
def get_parent_path(file_ref)
  parts = []
  parent = file_ref.parent

  while parent && parent.respond_to?(:path) && parent.path
    parts.unshift(parent.path) unless parent.path.empty?
    parent = parent.parent
  end

  parts.join('/')
end

# Check all Swift files
project.files.select { |f| f.path&.end_with?('.swift') }.each do |file_ref|
  # Get the parent group's full path
  parent_path = get_parent_path(file_ref)

  # If the file's path includes the parent path, it's duplicated
  if file_ref.path.include?('/')
    # The path should just be the filename if it's in a group
    expected_path = File.basename(file_ref.path)

    if file_ref.path != expected_path
      puts "  Fixing: #{file_ref.display_name}"
      puts "    Old path: #{file_ref.path}"
      puts "    New path: #{expected_path}"
      puts "    Parent path: #{parent_path}"

      file_ref.path = expected_path
      fixed_count += 1
    end
  end
end

puts "\n✅ Fixed #{fixed_count} file references"

project.save
puts "💾 Project saved!"
