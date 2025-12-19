#!/usr/bin/env ruby

require 'fileutils'

puts "🔧 Fixing duplicated directory structure..."

base_path = 'EventPassUG'
duplicate_path = File.join(base_path, 'EventPassUG')

if Dir.exist?(duplicate_path)
  # Find all files in the duplicated directory
  files = Dir.glob(File.join(duplicate_path, '**', '*')).select { |f| File.file?(f) }

  files.each do |file|
    # Calculate the target path
    relative_path = file.sub("#{duplicate_path}/", '')
    target = File.join(base_path, relative_path)

    # Create target directory if needed
    FileUtils.mkdir_p(File.dirname(target))

    # Move the file
    FileUtils.mv(file, target)
    puts "  ✓ Moved: #{File.basename(file)}"
  end

  # Remove the duplicated directory
  FileUtils.rm_rf(duplicate_path)
  puts "  ✓ Removed duplicate EventPassUG/ directory"
end

puts "✅ Directory structure fixed!"
