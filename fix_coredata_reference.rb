#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'EventPassUG.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "🔧 Fixing CoreData model reference..."

# Find the CoreData model
coredata_ref = project.files.find { |f| f.path && f.path.include?('EventPassUG.xcdatamodeld') }

if coredata_ref
  puts "Found CoreData model: #{coredata_ref.path}"

  # Update the path to the new location
  new_path = 'Core/Data/CoreData/EventPassUG.xcdatamodeld'
  coredata_ref.path = new_path

  puts "Updated path to: #{new_path}"

  project.save
  puts "✅ CoreData reference fixed!"
else
  puts "⚠️ CoreData model reference not found"
end
