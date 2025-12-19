#!/usr/bin/env ruby

require 'xcodeproj'
require 'find'

project_path = 'EventPassUG.xcodeproj'
project = Xcodeproj::Project.open(project_path)
project_root = File.dirname(File.expand_path(project_path))
eventpass_root = File.join(project_root, 'EventPassUG')

puts "🔧 Reorganizing all file references based on physical locations...\n"

# Find or create a group for a given path
def find_or_create_group(project, path_components)
  eventpass_group = project.main_group['EventPassUG']
  return eventpass_group if path_components.empty?
  
  current_group = eventpass_group
  path_components.each do |component|
    existing = current_group.groups.find { |g| g.display_name == component }
    
    if existing
      current_group = existing
    else
      current_group = current_group.new_group(component, component)
    end
  end
  
  current_group
end

# Get all Swift files from filesystem
physical_files = []
Find.find(eventpass_root) do |path|
  next unless File.file?(path)
  next unless path.end_with?('.swift') || path.end_with?('.xcdatamodeld') || path.end_with?('.xcassets')
  
  relative_path = path.sub("#{eventpass_root}/", '')
  physical_files << relative_path
end

puts "Found #{physical_files.count} physical files\n\n"

moved_count = 0

physical_files.each do |relative_path|
  filename = File.basename(relative_path)
  dir_path = File.dirname(relative_path)
  
  # Find the file reference in the project
  file_ref = project.files.find { |f| f.display_name == filename }
  next unless file_ref
  
  # Determine the correct group
  if dir_path == '.'
    target_group = project.main_group['EventPassUG']
  else
    path_components = dir_path.split('/')
    target_group = find_or_create_group(project, path_components)
  end
  
  next unless target_group
  
  # Check if file needs to be moved
  current_parent = file_ref.parent
  if current_parent != target_group
    puts "  Moving: #{filename}"
    puts "    From: #{current_parent.hierarchy_path rescue current_parent.display_name}"
    puts "    To: #{target_group.hierarchy_path rescue target_group.display_name}"
    
    # Remove from old parent
    current_parent.children.delete(file_ref) if current_parent
    
    # Add to new parent  
    target_group.children << file_ref unless target_group.children.include?(file_ref)
    file_ref.parent = target_group
    
    moved_count += 1
  end
  
  # Ensure file path is just the filename
  file_ref.path = filename if file_ref.path != filename
end

puts "\n✅ Moved #{moved_count} files to correct groups"

project.save
puts "💾 Project saved!"
puts "\n🎯 All file references now match physical structure!"
