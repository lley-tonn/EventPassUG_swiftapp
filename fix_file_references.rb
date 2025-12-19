#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'EventPassUG.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "🔧 Fixing file reference paths...\n"

fixed_count = 0
project_root = File.dirname(File.expand_path(project_path))

# Recursively fix all file references
def fix_group_references(group, project_root, fixed_count_ref)
  group.children.each do |item|
    if item.is_a?(Xcodeproj::Project::Object::PBXFileReference)
      # Get the real path on disk
      real_path = item.real_path.to_s

      # Calculate what the path should be relative to the group
      if File.exist?(real_path)
        # Get path relative to EventPassUG folder
        eventpass_folder = File.join(project_root, 'EventPassUG')

        if real_path.start_with?(eventpass_folder)
          relative_to_eventpass = real_path.sub("#{eventpass_folder}/", '')

          # Only update if the path is wrong (just filename instead of full path)
          if item.path != relative_to_eventpass && item.path == File.basename(real_path)
            puts "  Fixing: #{item.display_name}"
            puts "    Old path: #{item.path}"
            puts "    New path: #{relative_to_eventpass}"

            item.path = relative_to_eventpass
            fixed_count_ref[:count] += 1
          end
        end
      end
    elsif item.is_a?(Xcodeproj::Project::Object::PBXGroup)
      # Recursively process subgroups
      fix_group_references(item, project_root, fixed_count_ref)
    end
  end
end

fixed_count_ref = { count: 0 }

project.main_group.children.each do |group|
  if group.is_a?(Xcodeproj::Project::Object::PBXGroup)
    fix_group_references(group, project_root, fixed_count_ref)
  end
end

puts "\n✅ Fixed #{fixed_count_ref[:count]} file references"

project.save
puts "💾 Project saved!"
