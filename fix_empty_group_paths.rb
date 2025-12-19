#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'EventPassUG.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "🔧 Fixing empty group paths...\n"

fixed_count = 0

def fix_group_paths(group, fixed_count_ref)
  group.groups.each do |subgroup|
    # If the group has an empty path but has a display name, set path = display name
    if (subgroup.path.nil? || subgroup.path.empty?) && subgroup.display_name && !subgroup.display_name.empty?
      puts "  Fixing: #{subgroup.hierarchy_path}"
      puts "    Display name: #{subgroup.display_name}"
      puts "    Old path: '#{subgroup.path}'"

      subgroup.path = subgroup.display_name

      puts "    New path: '#{subgroup.path}'"
      fixed_count_ref[:count] += 1
    end

    # Recursively fix subgroups
    fix_group_paths(subgroup, fixed_count_ref)
  end
end

# Start from the main EventPassUG group
eventpass_group = project.main_group['EventPassUG']
if eventpass_group
  fixed_count_ref = { count: 0 }
  fix_group_paths(eventpass_group, fixed_count_ref)

  puts "\n✅ Fixed #{fixed_count_ref[:count]} groups"

  project.save
  puts "💾 Project saved!"
else
  puts "❌ Could not find EventPassUG group"
end
