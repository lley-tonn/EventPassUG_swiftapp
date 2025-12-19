#!/usr/bin/env ruby

require 'xcodeproj'
require 'fileutils'

project_path = 'EventPassUG.xcodeproj'
project = Xcodeproj::Project.open(project_path)
main_group = project.main_group.find_subpath('EventPassUG', true)
target = project.targets.first

puts "🚀 Starting EventPass Project Structure Refactoring..."
puts "="  * 60

# Helper method to create a folder structure
def create_folder_path(parent, path_components)
  current = parent
  path_components.each do |component|
    existing = current.children.find { |child| child.display_name == component && child.isa == 'PBXGroup' }
    current = existing || current.new_group(component)
  end
  current
end

# Helper method to move file
def move_file_to_group(file_ref, new_group, project_root)
  return unless file_ref

  old_path = file_ref.real_path.to_s

  # Build new directory path from group hierarchy
  path_components = []
  current_group = new_group
  while current_group && current_group.display_name != 'EventPassUG'
    path_components.unshift(current_group.display_name)
    current_group = current_group.parent
  end

  new_dir_path = File.join(project_root, 'EventPassUG', *path_components)

  # Create physical directory if it doesn't exist
  FileUtils.mkdir_p(new_dir_path) unless Dir.exist?(new_dir_path)

  new_file_path = File.join(new_dir_path, File.basename(old_path))

  # Move physical file if it exists and hasn't been moved
  if File.exist?(old_path) && old_path != new_file_path
    FileUtils.mv(old_path, new_file_path)
    puts "  ✓ Moved: #{file_ref.display_name}"
  end

  # Update Xcode reference
  file_ref.move(new_group)
  file_ref.set_path(File.basename(new_file_path))
end

# Define all folder structure
folder_structure = {
  'App' => [],
  'Core' => ['Configuration', 'Data/CoreData', 'Data/Storage', 'Extensions'],
  'Models' => ['Domain', 'Notifications', 'Preferences', 'Support'],
  'Services' => [
    'Authentication', 'Events', 'Tickets', 'Notifications',
    'Recommendations', 'Location', 'Payment', 'Calendar',
    'UserPreferences', 'Database'
  ],
  'ViewModels' => ['Auth', 'Attendee', 'Organizer', 'Settings'],
  'Views' => [
    'Auth/Login', 'Auth/Onboarding',
    'Attendee/Home', 'Attendee/Events', 'Attendee/Tickets',
    'Organizer/Home', 'Organizer/Events', 'Organizer/Notifications',
    'Organizer/Scanner', 'Organizer/Onboarding/Steps',
    'Profile', 'Notifications', 'Support', 'Shared',
    'Components/Cards', 'Components/Buttons', 'Components/Headers',
    'Components/Badges', 'Components/Media', 'Components/Timers',
    'Components/Overlays', 'Components/Loading',
    'Navigation'
  ],
  'DesignSystem' => ['Theme'],
  'Utilities' => [
    'Managers', 'Helpers/Date', 'Helpers/Image', 'Helpers/Device',
    'Helpers/Generators', 'Helpers/Validation', 'Helpers/UI', 'Debug'
  ],
  'Resources' => []
}

# Create all folder groups
puts "\n📁 Creating folder structure..."
folder_structure.each do |top_level, subfolders|
  top_group = create_folder_path(main_group, [top_level])
  subfolders.each do |subfolder|
    create_folder_path(top_group, subfolder.split('/'))
  end
  puts "  ✓ Created: #{top_level}/"
end

puts "\n📦 Moving files to new locations..."

# File migration mappings
project_root = File.dirname(File.dirname(project_path))
eventpassug_path = File.join(project_root, 'EventPassUG')

file_moves = {
  # App
  'EventPassUGApp.swift' => 'App',
  'ContentView.swift' => 'App',

  # Core - Configuration
  'Config/RoleConfig.swift' => 'Core/Configuration',

  # Core - Data
  'CoreData/PersistenceController.swift' => 'Core/Data/CoreData',
  'Utilities/AppStorage.swift' => 'Core/Data/Storage',
  'Utilities/AppStorageKeys.swift' => 'Core/Data/Storage',

  # Core - Extensions
  'Extensions/Event+TicketSales.swift' => 'Core/Extensions',

  # Models - Domain
  'Models/Event.swift' => 'Models/Domain',
  'Models/Ticket.swift' => 'Models/Domain',
  'Models/TicketType.swift' => 'Models/Domain',
  'Models/User.swift' => 'Models/Domain',
  'Models/OrganizerProfile.swift' => 'Models/Domain',

  # Models - Notifications
  'Models/NotificationModel.swift' => 'Models/Notifications',
  'Models/NotificationPreferences.swift' => 'Models/Notifications',

  # Models - Preferences
  'Models/UserPreferences.swift' => 'Models/Preferences',

  # Models - Support
  'Models/SupportModels.swift' => 'Models/Support',
  'Models/PosterConfiguration.swift' => 'Models/Support',

  # Services - Authentication
  'Services/AuthService.swift' => 'Services/Authentication',
  'Services/EnhancedAuthService.swift' => 'Services/Authentication',

  # Services - Events
  'Services/EventService.swift' => 'Services/Events',
  'Services/EventFilterService.swift' => 'Services/Events',

  # Services - Tickets
  'Services/TicketService.swift' => 'Services/Tickets',

  # Services - Notifications
  'Services/AppNotificationService.swift' => 'Services/Notifications',
  'Services/NotificationService.swift' => 'Services/Notifications',
  'Services/NotificationAnalytics.swift' => 'Services/Notifications',

  # Services - Other
  'Services/RecommendationService.swift' => 'Services/Recommendations',
  'Services/LocationService.swift' => 'Services/Location',
  'Services/UserLocationService.swift' => 'Services/Location',
  'Services/PaymentService.swift' => 'Services/Payment',
  'Services/CalendarService.swift' => 'Services/Calendar',
  'Services/UserPreferencesService.swift' => 'Services/UserPreferences',

  # ViewModels
  'ViewModels/AuthViewModel.swift' => 'ViewModels/Auth',
  'ViewModels/AttendeeHomeViewModel.swift' => 'ViewModels/Attendee',
  'ViewModels/DiscoveryViewModel.swift' => 'ViewModels/Attendee',
  'ViewModels/EventAnalyticsViewModel.swift' => 'ViewModels/Organizer',
  'ViewModels/NotificationSettingsViewModel.swift' => 'ViewModels/Settings',

  # Views - Auth
  'Views/Auth/ModernAuthView.swift' => 'Views/Auth/Login',
  'Views/Auth/PhoneVerificationView.swift' => 'Views/Auth/Login',
  'Views/Auth/AddContactMethodView.swift' => 'Views/Auth/Login',
  'Views/Auth/AuthComponents.swift' => 'Views/Auth/Login',
  'Views/Auth/OnboardingFlowView.swift' => 'Views/Auth/Onboarding',
  'Views/Onboarding/AppIntroSlidesView.swift' => 'Views/Auth/Onboarding',
  'Views/Onboarding/PermissionsView.swift' => 'Views/Auth/Onboarding',

  # Views - Attendee
  'Views/Attendee/AttendeeHomeView.swift' => 'Views/Attendee/Home',
  'Views/Attendee/EventDetailsView.swift' => 'Views/Attendee/Events',
  'Views/Attendee/SearchView.swift' => 'Views/Attendee/Events',
  'Views/Attendee/FavoriteEventsView.swift' => 'Views/Attendee/Events',
  'Views/Attendee/TicketsView.swift' => 'Views/Attendee/Tickets',
  'Views/Attendee/TicketDetailView.swift' => 'Views/Attendee/Tickets',
  'Views/Attendee/TicketPurchaseView.swift' => 'Views/Attendee/Tickets',
  'Views/Attendee/TicketSuccessView.swift' => 'Views/Attendee/Tickets',

  # Views - Organizer
  'Views/Organizer/OrganizerHomeView.swift' => 'Views/Organizer/Home',
  'Views/Organizer/OrganizerDashboardView.swift' => 'Views/Organizer/Home',
  'Views/Organizer/CreateEventWizard.swift' => 'Views/Organizer/Events',
  'Views/Organizer/EventAnalyticsView.swift' => 'Views/Organizer/Events',
  'Views/Organizer/OrganizerNotificationCenterView.swift' => 'Views/Organizer/Notifications',
  'Views/Organizer/QRScannerView.swift' => 'Views/Organizer/Scanner',
  'Views/Organizer/BecomeOrganizerFlow.swift' => 'Views/Organizer/Onboarding',
  'Views/Organizer/Steps/OrganizerContactInfoStep.swift' => 'Views/Organizer/Onboarding/Steps',
  'Views/Organizer/Steps/OrganizerIdentityVerificationStep.swift' => 'Views/Organizer/Onboarding/Steps',
  'Views/Organizer/Steps/OrganizerPayoutSetupStep.swift' => 'Views/Organizer/Onboarding/Steps',
  'Views/Organizer/Steps/OrganizerProfileCompletionStep.swift' => 'Views/Organizer/Onboarding/Steps',
  'Views/Organizer/Steps/OrganizerTermsAgreementStep.swift' => 'Views/Organizer/Onboarding/Steps',

  # Views - Profile
  'Views/Common/ProfileView.swift' => 'Views/Profile',
  'Views/Common/ProfileView+ContactVerification.swift' => 'Views/Profile',
  'Views/Common/EditProfileView.swift' => 'Views/Profile',
  'Views/Common/PaymentMethodsView.swift' => 'Views/Profile',
  'Views/Common/NotificationSettingsView.swift' => 'Views/Profile',
  'Views/Common/FavoriteEventCategoriesView.swift' => 'Views/Profile',

  # Views - Notifications
  'Views/Common/NotificationsView.swift' => 'Views/Notifications',

  # Views - Shared
  'Views/Common/CalendarConflictView.swift' => 'Views/Shared',
  'Views/Common/CardScanner.swift' => 'Views/Shared',
  'Views/Common/NationalIDVerificationView.swift' => 'Views/Shared',

  # Views - Components
  'Views/Components/EventCard.swift' => 'Views/Components/Cards',
  'Views/Components/CategoryTile.swift' => 'Views/Components/Cards',
  'Views/Components/AnimatedLikeButton.swift' => 'Views/Components/Buttons',
  'Views/Components/HeaderBar.swift' => 'Views/Components/Headers',
  'Views/Components/ProfileHeaderView.swift' => 'Views/Components/Headers',
  'Views/Components/NotificationBadge.swift' => 'Views/Components/Badges',
  'Views/Components/PulsingDot.swift' => 'Views/Components/Badges',
  'Views/Components/PosterView.swift' => 'Views/Components/Media',
  'Views/Components/QRCodeView.swift' => 'Views/Components/Media',
  'Views/Components/SalesCountdownTimer.swift' => 'Views/Components/Timers',
  'Views/Components/VerificationRequiredOverlay.swift' => 'Views/Components/Overlays',
  'Views/Components/LoadingView.swift' => 'Views/Components/Loading',

  # Design System
  'Config/AppDesignSystem.swift' => 'DesignSystem/Theme',

  # Utilities - Managers
  'Utilities/FavoriteManager.swift' => 'Utilities/Managers',
  'Utilities/FollowManager.swift' => 'Utilities/Managers',
  'Utilities/InAppNotificationManager.swift' => 'Utilities/Managers',
  'Utilities/ImageStorageManager.swift' => 'Utilities/Managers',
  'Utilities/PosterUploadManager.swift' => 'Utilities/Managers',

  # Utilities - Helpers
  'Utilities/DateUtilities.swift' => 'Utilities/Helpers/Date',
  'Utilities/ImageColorExtractor.swift' => 'Utilities/Helpers/Image',
  'Utilities/ImageCompressor.swift' => 'Utilities/Helpers/Image',
  'Utilities/ImageValidator.swift' => 'Utilities/Helpers/Image',
  'Utilities/DeviceOrientation.swift' => 'Utilities/Helpers/Device',
  'Utilities/HapticFeedback.swift' => 'Utilities/Helpers/Device',
  'Utilities/ResponsiveSize.swift' => 'Utilities/Helpers/Device',
  'Utilities/QRCodeGenerator.swift' => 'Utilities/Helpers/Generators',
  'Utilities/PDFGenerator.swift' => 'Utilities/Helpers/Generators',
  'Utilities/Validation.swift' => 'Utilities/Helpers/Validation',
  'Utilities/ScrollHelpers.swift' => 'Utilities/Helpers/UI',
  'Utilities/ShareSheet.swift' => 'Utilities/Helpers/UI',
  'Utilities/OnboardingDebugView.swift' => 'Utilities/Debug'
}

# Execute file moves
file_moves.each do |old_path, new_group_path|
  # Find the file reference in the old location
  file_ref = main_group.recursive_children_groups.flat_map(&:files).find do |file|
    file.path && file.path.include?(File.basename(old_path))
  end

  next unless file_ref

  # Get the target group
  new_group = create_folder_path(main_group, new_group_path.split('/'))

  # Move the file
  move_file_to_group(file_ref, new_group, eventpassug_path)
end

# Handle CoreData model directory (special case)
puts "\n📊 Moving CoreData model..."
coredata_group = main_group.find_subpath('EventPassUG.xcdatamodeld')
if coredata_group
  new_coredata_parent = create_folder_path(main_group, ['Core', 'Data', 'CoreData'])
  coredata_group.move(new_coredata_parent)

  # Move physical directory
  old_coredata_path = File.join(eventpassug_path, 'EventPassUG.xcdatamodeld')
  new_coredata_path = File.join(eventpassug_path, 'Core/Data/CoreData/EventPassUG.xcdatamodeld')

  if Dir.exist?(old_coredata_path)
    FileUtils.mkdir_p(File.dirname(new_coredata_path))
    FileUtils.mv(old_coredata_path, new_coredata_path)
    puts "  ✓ Moved: EventPassUG.xcdatamodeld"
  end
end

# Move Resources (Assets)
puts "\n🎨 Moving Resources..."
assets_group = main_group.find_subpath('Assets.xcassets')
if assets_group
  resources_group = create_folder_path(main_group, ['Resources'])
  assets_group.move(resources_group)

  # Move physical directory
  old_assets_path = File.join(eventpassug_path, 'Assets.xcassets')
  new_assets_path = File.join(eventpassug_path, 'Resources/Assets.xcassets')

  if Dir.exist?(old_assets_path)
    FileUtils.mkdir_p(File.dirname(new_assets_path))
    FileUtils.mv(old_assets_path, new_assets_path)
    puts "  ✓ Moved: Assets.xcassets"
  end
end

# Clean up empty old folders
puts "\n🧹 Cleaning up old folder structure..."
old_folders = ['Config', 'CoreData', 'Extensions', 'Onboarding']
old_folders.each do |folder_name|
  old_group = main_group.children.find { |child| child.display_name == folder_name }
  if old_group && old_group.children.empty?
    old_group.remove_from_project
    puts "  ✓ Removed empty: #{folder_name}/"

    # Remove physical directory if empty
    old_physical_path = File.join(eventpassug_path, folder_name)
    if Dir.exist?(old_physical_path) && Dir.empty?(old_physical_path)
      Dir.rmdir(old_physical_path)
    end
  end
end

# Also clean up old Views subfolders that are now empty
views_group = main_group.find_subpath('Views')
if views_group
  ['Attendee', 'Auth', 'Common', 'Organizer'].each do |subfolder|
    old_subfolder = views_group.children.find { |child| child.display_name == subfolder }
    if old_subfolder && old_subfolder.children.empty?
      old_subfolder.remove_from_project
      puts "  ✓ Removed empty: Views/#{subfolder}/"

      old_physical_path = File.join(eventpassug_path, 'Views', subfolder)
      if Dir.exist?(old_physical_path) && Dir.empty?(old_physical_path)
        Dir.rmdir(old_physical_path)
      end
    end
  end
end

# Save the project
puts "\n💾 Saving Xcode project..."
project.save

puts "\n" + "=" * 60
puts "✅ Project refactoring complete!"
puts "=" * 60
puts "\n📋 Summary:"
puts "  • #{file_moves.count} files moved"
puts "  • New clean folder structure created"
puts "  • Old empty folders removed"
puts "\n🔍 Next Steps:"
puts "  1. Open project in Xcode and verify structure"
puts "  2. Run a clean build (⌘ + Shift + K, then ⌘ + B)"
puts "  3. Review REFACTORING_PLAN.md for best practices"
puts "\n"
