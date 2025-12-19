#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'EventPassUG.xcodeproj'
project = Xcodeproj::Project.open(project_path)
project_root = File.dirname(File.expand_path(project_path))

puts "🔧 Fixing all file references to match physical locations...\n"

# Find or create a group for a given path
def find_or_create_group(project, path_from_eventpass)
  # Start from EventPassUG group
  eventpass_group = project.main_group['EventPassUG']
  return nil unless eventpass_group
  
  # Split path into components
  parts = path_from_eventpass.split('/').reject(&:empty?)
  
  current_group = eventpass_group
  parts.each do |part|
    # Find existing group or create new one
    existing = current_group.children.find { |c| c.is_a?(Xcodeproj::Project::Object::PBXGroup) && c.display_name == part }
    
    if existing
      current_group = existing
    else
      # Create new group
      new_group = current_group.new_group(part, part)
      current_group = new_group
    end
  end
  
  current_group
end

moved_count = 0
eventpass_root = File.join(project_root, 'EventPassUG')

# Process all file references
project.files.each do |file_ref|
  next unless file_ref.real_path
  
  real_path_str = file_ref.real_path.to_s
  
  # Only process files inside EventPassUG folder
  next unless real_path_str.start_with?(eventpass_root)
  
  # Get the path relative to EventPassUG folder
  relative_to_eventpass = real_path_str.sub("#{eventpass_root}/", '')
  
  # Skip if file is directly in EventPassUG root (no subdirectories)
  next unless relative_to_eventpass.include?('/')
  
  # Get the directory path (without filename)
  dir_path = File.dirname(relative_to_eventpass)
  filename = File.basename(relative_to_eventpass)
  
  # Find the correct group for this file
  target_group = find_or_create_group(project, dir_path)
  next unless target_group
  
  # Check if file is already in the correct group
  current_parent = file_ref.parent
  if current_parent != target_group
    puts "  Moving: #{file_ref.display_name}"
    puts "    From: #{current_parent.hierarchy_path rescue 'unknown'}"
    puts "    To: #{target_group.hierarchy_path}"
    
    # Remove from current parent
    current_parent.children.delete(file_ref)
    
    # Add to new parent
    target_group.children << file_ref
    file_ref.parent = target_group
    
    moved_count += 1
  end
  
  # Ensure the file's path is just the filename
  if file_ref.path != filename
    file_ref.path = filename
  end
end

puts "\n✅ Moved #{moved_count} files to correct groups"

project.save
puts "💾 Project saved!"
puts "\nNow try building again!"
