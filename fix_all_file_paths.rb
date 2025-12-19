#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'EventPassUG.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "🔧 Fixing file paths to use just filename...\n"

fixed_count = 0

# Fix all file references that have paths containing directory separators
project.files.each do |file_ref|
  next unless file_ref.path

  # If the path contains a directory separator, it should just be the filename
  if file_ref.path.include?('/')
    expected_path = File.basename(file_ref.path)

    if file_ref.path != expected_path
      puts "  Fixing: #{file_ref.display_name}"
      puts "    Old path: #{file_ref.path}"
      puts "    New path: #{expected_path}"

      file_ref.path = expected_path
      fixed_count += 1
    end
  end
end

puts "\n✅ Fixed #{fixed_count} file references"

project.save
puts "💾 Project saved!"
