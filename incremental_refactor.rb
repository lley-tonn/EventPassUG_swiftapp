#!/usr/bin/env ruby

require 'xcodeproj'
require 'fileutils'

# Comprehensive, phase-by-phase project refactoring script
# Migrates EventPass project to professional MVVM structure

class ProjectRefactorer
  attr_reader :project, :main_group, :target, :project_root

  def initialize(project_path = 'EventPassUG.xcodeproj')
    @project = Xcodeproj::Project.open(project_path)
    @main_group = @project.main_group.find_subpath('EventPassUG', true)
    @target = @project.targets.first
    @project_root = File.dirname(File.dirname(project_path))
  end

  # Helper: Create folder hierarchy
  def create_group_path(parent, path_array)
    current = parent
    path_array.each do |component|
      existing = current.children.find { |c| c.display_name == component && c.isa == 'PBXGroup' }
      current = existing || current.new_group(component)
    end
    current
  end

  # Helper: Get absolute filesystem path for a group
  def group_filesystem_path(group)
    components = []
    current = group

    while current && current.display_name != 'EventPassUG'
      components.unshift(current.display_name)
      current = current.parent
    end

    File.join(@project_root, 'EventPassUG', *components)
  end

  # Helper: Find file reference by name
  def find_file_ref(filename)
    @project.files.find { |f| f.display_name == filename }
  end

  # Helper: Move a single file
  def move_file(filename, target_group_path)
    file_ref = find_file_ref(filename)
    unless file_ref
      puts "  ⚠️  File not found: #{filename}"
      return false
    end

    # Get target group
    target_group = create_group_path(@main_group, target_group_path)

    # Get paths
    old_real_path = file_ref.real_path.to_s
    new_dir_path = group_filesystem_path(target_group)
    new_file_path = File.join(new_dir_path, filename)

    # Create directory
    FileUtils.mkdir_p(new_dir_path)

    # Move physical file (skip if already in target location)
    begin
      same_file = File.exist?(old_real_path) && File.exist?(new_file_path) && File.realpath(old_real_path) == File.realpath(new_file_path)
    rescue
      same_file = false
    end

    if File.exist?(old_real_path) && !same_file && !File.exist?(new_file_path)
      FileUtils.mv(old_real_path, new_file_path)
    end

    # Update Xcode reference
    file_ref.move(target_group)

    # Set relative path from group
    file_ref.path = filename
    file_ref.source_tree = '<group>'

    puts "  ✓ #{filename}"
    true
  end

  # Helper: Move multiple files
  def move_files(file_mappings)
    success_count = 0
    file_mappings.each do |filename, target_path|
      success_count += 1 if move_file(filename, target_path.split('/'))
    end
    success_count
  end

  # Save project
  def save
    @project.save
    puts "  💾 Project saved"
  end

  # Verify specific files exist
  def verify_files_exist(filenames)
    missing = filenames.reject { |f| find_file_ref(f) }
    if missing.any?
      puts "  ❌ Missing files: #{missing.join(', ')}"
      return false
    end
    true
  end

  # Clean up empty groups
  def cleanup_empty_groups(group_names)
    group_names.each do |name|
      group = @main_group.children.find { |c| c.display_name == name }
      if group && group.children.empty?
        group.remove_from_project

        # Remove physical directory if empty
        dir_path = File.join(@project_root, 'EventPassUG', name)
        Dir.rmdir(dir_path) if Dir.exist?(dir_path) && Dir.empty?(dir_path)

        puts "  ✓ Removed empty: #{name}/"
      end
    end
  end
end

# ============================================================================
# MAIN EXECUTION
# ============================================================================

puts "🚀 EventPass Incremental Refactoring"
puts "=" * 70

refactorer = ProjectRefactorer.new

# ============================================================================
# PHASE 1: App & Core Infrastructure
# ============================================================================

puts "\n📱 PHASE 1: App & Core Infrastructure"
puts "-" * 70

phase1_files = {
  'EventPassUGApp.swift' => 'App',
  'ContentView.swift' => 'App',
  'RoleConfig.swift' => 'Core/Configuration',
  'PersistenceController.swift' => 'Core/Data/CoreData',
  'AppStorage.swift' => 'Core/Data/Storage',
  'AppStorageKeys.swift' => 'Core/Data/Storage',
  'Event+TicketSales.swift' => 'Core/Extensions'
}

moved = refactorer.move_files(phase1_files)
refactorer.save

puts "✅ Phase 1 Complete: #{moved}/#{phase1_files.size} files moved"

# ============================================================================
# PHASE 2: Models (Domain Organization)
# ============================================================================

puts "\n📦 PHASE 2: Models"
puts "-" * 70

phase2_files = {
  'Event.swift' => 'Models/Domain',
  'Ticket.swift' => 'Models/Domain',
  'TicketType.swift' => 'Models/Domain',
  'User.swift' => 'Models/Domain',
  'OrganizerProfile.swift' => 'Models/Domain',
  'NotificationModel.swift' => 'Models/Notifications',
  'NotificationPreferences.swift' => 'Models/Notifications',
  'UserPreferences.swift' => 'Models/Preferences',
  'SupportModels.swift' => 'Models/Support',
  'PosterConfiguration.swift' => 'Models/Support'
}

moved = refactorer.move_files(phase2_files)
refactorer.save

puts "✅ Phase 2 Complete: #{moved}/#{phase2_files.size} files moved"

# ============================================================================
# PHASE 3: Services (Feature Grouping)
# ============================================================================

puts "\n🔧 PHASE 3: Services"
puts "-" * 70

phase3_files = {
  'AuthService.swift' => 'Services/Authentication',
  'EnhancedAuthService.swift' => 'Services/Authentication',
  'EventService.swift' => 'Services/Events',
  'EventFilterService.swift' => 'Services/Events',
  'TicketService.swift' => 'Services/Tickets',
  'AppNotificationService.swift' => 'Services/Notifications',
  'NotificationService.swift' => 'Services/Notifications',
  'NotificationAnalytics.swift' => 'Services/Notifications',
  'RecommendationService.swift' => 'Services/Recommendations',
  'LocationService.swift' => 'Services/Location',
  'UserLocationService.swift' => 'Services/Location',
  'PaymentService.swift' => 'Services/Payment',
  'CalendarService.swift' => 'Services/Calendar',
  'UserPreferencesService.swift' => 'Services/UserPreferences'
}

moved = refactorer.move_files(phase3_files)
refactorer.save

puts "✅ Phase 3 Complete: #{moved}/#{phase3_files.size} files moved"

# ============================================================================
# PHASE 4: ViewModels (Feature Grouping)
# ============================================================================

puts "\n🧠 PHASE 4: ViewModels"
puts "-" * 70

phase4_files = {
  'AuthViewModel.swift' => 'ViewModels/Auth',
  'AttendeeHomeViewModel.swift' => 'ViewModels/Attendee',
  'DiscoveryViewModel.swift' => 'ViewModels/Attendee',
  'EventAnalyticsViewModel.swift' => 'ViewModels/Organizer',
  'NotificationSettingsViewModel.swift' => 'ViewModels/Settings'
}

moved = refactorer.move_files(phase4_files)
refactorer.save

puts "✅ Phase 4 Complete: #{moved}/#{phase4_files.size} files moved"

# ============================================================================
# PHASE 5: Views - Auth & Onboarding
# ============================================================================

puts "\n🎨 PHASE 5a: Views - Auth"
puts "-" * 70

phase5a_files = {
  'ModernAuthView.swift' => 'Views/Auth/Login',
  'PhoneVerificationView.swift' => 'Views/Auth/Login',
  'AddContactMethodView.swift' => 'Views/Auth/Login',
  'AuthComponents.swift' => 'Views/Auth/Login',
  'OnboardingFlowView.swift' => 'Views/Auth/Onboarding',
  'AppIntroSlidesView.swift' => 'Views/Auth/Onboarding',
  'PermissionsView.swift' => 'Views/Auth/Onboarding'
}

moved = refactorer.move_files(phase5a_files)
refactorer.save

puts "✅ Phase 5a Complete: #{moved}/#{phase5a_files.size} files moved"

# ============================================================================
# PHASE 5b: Views - Attendee
# ============================================================================

puts "\n🎨 PHASE 5b: Views - Attendee"
puts "-" * 70

phase5b_files = {
  'AttendeeHomeView.swift' => 'Views/Attendee/Home',
  'EventDetailsView.swift' => 'Views/Attendee/Events',
  'SearchView.swift' => 'Views/Attendee/Events',
  'FavoriteEventsView.swift' => 'Views/Attendee/Events',
  'TicketsView.swift' => 'Views/Attendee/Tickets',
  'TicketDetailView.swift' => 'Views/Attendee/Tickets',
  'TicketPurchaseView.swift' => 'Views/Attendee/Tickets',
  'TicketSuccessView.swift' => 'Views/Attendee/Tickets'
}

moved = refactorer.move_files(phase5b_files)
refactorer.save

puts "✅ Phase 5b Complete: #{moved}/#{phase5b_files.size} files moved"

# ============================================================================
# PHASE 5c: Views - Organizer
# ============================================================================

puts "\n🎨 PHASE 5c: Views - Organizer"
puts "-" * 70

phase5c_files = {
  'OrganizerHomeView.swift' => 'Views/Organizer/Home',
  'OrganizerDashboardView.swift' => 'Views/Organizer/Home',
  'CreateEventWizard.swift' => 'Views/Organizer/Events',
  'EventAnalyticsView.swift' => 'Views/Organizer/Events',
  'OrganizerNotificationCenterView.swift' => 'Views/Organizer/Notifications',
  'QRScannerView.swift' => 'Views/Organizer/Scanner',
  'BecomeOrganizerFlow.swift' => 'Views/Organizer/Onboarding',
  'OrganizerContactInfoStep.swift' => 'Views/Organizer/Onboarding/Steps',
  'OrganizerIdentityVerificationStep.swift' => 'Views/Organizer/Onboarding/Steps',
  'OrganizerPayoutSetupStep.swift' => 'Views/Organizer/Onboarding/Steps',
  'OrganizerProfileCompletionStep.swift' => 'Views/Organizer/Onboarding/Steps',
  'OrganizerTermsAgreementStep.swift' => 'Views/Organizer/Onboarding/Steps'
}

moved = refactorer.move_files(phase5c_files)
refactorer.save

puts "✅ Phase 5c Complete: #{moved}/#{phase5c_files.size} files moved"

# ============================================================================
# PHASE 5d: Views - Profile, Notifications, Support, Shared
# ============================================================================

puts "\n🎨 PHASE 5d: Views - Profile, Shared, Support"
puts "-" * 70

phase5d_files = {
  'ProfileView.swift' => 'Views/Profile',
  'ProfileView+ContactVerification.swift' => 'Views/Profile',
  'EditProfileView.swift' => 'Views/Profile',
  'PaymentMethodsView.swift' => 'Views/Profile',
  'NotificationSettingsView.swift' => 'Views/Profile',
  'FavoriteEventCategoriesView.swift' => 'Views/Profile',
  'NotificationsView.swift' => 'Views/Notifications',
  'CalendarConflictView.swift' => 'Views/Shared',
  'CardScanner.swift' => 'Views/Shared',
  'NationalIDVerificationView.swift' => 'Views/Shared',
  'HelpCenterView.swift' => 'Views/Support',
  'SupportCenterView.swift' => 'Views/Support',
  'FAQSectionView.swift' => 'Views/Support',
  'AppGuidesView.swift' => 'Views/Support',
  'FeatureExplanationsView.swift' => 'Views/Support',
  'TroubleshootingView.swift' => 'Views/Support',
  'SubmitTicketView.swift' => 'Views/Support',
  'TermsAndPrivacyView.swift' => 'Views/Support',
  'TermsOfUseView.swift' => 'Views/Support',
  'PrivacyPolicyView.swift' => 'Views/Support',
  'SecurityInfoView.swift' => 'Views/Support'
}

moved = refactorer.move_files(phase5d_files)
refactorer.save

puts "✅ Phase 5d Complete: #{moved}/#{phase5d_files.size} files moved"

# ============================================================================
# PHASE 5e: Views - Components
# ============================================================================

puts "\n🎨 PHASE 5e: Views - Components"
puts "-" * 70

phase5e_files = {
  'EventCard.swift' => 'Views/Components/Cards',
  'CategoryTile.swift' => 'Views/Components/Cards',
  'AnimatedLikeButton.swift' => 'Views/Components/Buttons',
  'HeaderBar.swift' => 'Views/Components/Headers',
  'ProfileHeaderView.swift' => 'Views/Components/Headers',
  'NotificationBadge.swift' => 'Views/Components/Badges',
  'PulsingDot.swift' => 'Views/Components/Badges',
  'PosterView.swift' => 'Views/Components/Media',
  'QRCodeView.swift' => 'Views/Components/Media',
  'SalesCountdownTimer.swift' => 'Views/Components/Timers',
  'VerificationRequiredOverlay.swift' => 'Views/Components/Overlays',
  'LoadingView.swift' => 'Views/Components/Loading'
}

moved = refactorer.move_files(phase5e_files)
refactorer.save

puts "✅ Phase 5e Complete: #{moved}/#{phase5e_files.size} files moved"

# ============================================================================
# PHASE 6: Design System & Utilities
# ============================================================================

puts "\n🎨 PHASE 6a: Design System"
puts "-" * 70

phase6a_files = {
  'AppDesignSystem.swift' => 'DesignSystem/Theme'
}

moved = refactorer.move_files(phase6a_files)
refactorer.save

puts "✅ Phase 6a Complete: #{moved}/#{phase6a_files.size} files moved"

puts "\n🛠️  PHASE 6b: Utilities - Managers"
puts "-" * 70

phase6b_files = {
  'FavoriteManager.swift' => 'Utilities/Managers',
  'FollowManager.swift' => 'Utilities/Managers',
  'InAppNotificationManager.swift' => 'Utilities/Managers',
  'ImageStorageManager.swift' => 'Utilities/Managers',
  'PosterUploadManager.swift' => 'Utilities/Managers'
}

moved = refactorer.move_files(phase6b_files)
refactorer.save

puts "✅ Phase 6b Complete: #{moved}/#{phase6b_files.size} files moved"

puts "\n🛠️  PHASE 6c: Utilities - Helpers"
puts "-" * 70

phase6c_files = {
  'DateUtilities.swift' => 'Utilities/Helpers/Date',
  'ImageColorExtractor.swift' => 'Utilities/Helpers/Image',
  'ImageCompressor.swift' => 'Utilities/Helpers/Image',
  'ImageValidator.swift' => 'Utilities/Helpers/Image',
  'DeviceOrientation.swift' => 'Utilities/Helpers/Device',
  'HapticFeedback.swift' => 'Utilities/Helpers/Device',
  'ResponsiveSize.swift' => 'Utilities/Helpers/Device',
  'QRCodeGenerator.swift' => 'Utilities/Helpers/Generators',
  'PDFGenerator.swift' => 'Utilities/Helpers/Generators',
  'Validation.swift' => 'Utilities/Helpers/Validation',
  'ScrollHelpers.swift' => 'Utilities/Helpers/UI',
  'ShareSheet.swift' => 'Utilities/Helpers/UI',
  'OnboardingDebugView.swift' => 'Utilities/Debug'
}

moved = refactorer.move_files(phase6c_files)
refactorer.save

puts "✅ Phase 6c Complete: #{moved}/#{phase6c_files.size} files moved"

# ============================================================================
# PHASE 7: Special Cases - CoreData & Resources
# ============================================================================

puts "\n📊 PHASE 7: Special Cases"
puts "-" * 70

# Handle CoreData model
coredata_group = refactorer.main_group.find_subpath('EventPassUG.xcdatamodeld')
if coredata_group
  core_data_parent = refactorer.create_group_path(refactorer.main_group, ['Core', 'Data', 'CoreData'])
  coredata_group.move(core_data_parent)

  old_path = File.join(refactorer.project_root, 'EventPassUG', 'EventPassUG.xcdatamodeld')
  new_path = File.join(refactorer.project_root, 'EventPassUG', 'Core', 'Data', 'CoreData', 'EventPassUG.xcdatamodeld')

  if Dir.exist?(old_path) && !Dir.exist?(new_path)
    FileUtils.mkdir_p(File.dirname(new_path))
    FileUtils.mv(old_path, new_path)
    puts "  ✓ EventPassUG.xcdatamodeld"
  end

  # Update file reference
  coredata_ref = refactorer.project.files.find { |f| f.path && f.path.include?('EventPassUG.xcdatamodeld') }
  if coredata_ref
    coredata_ref.path = 'Core/Data/CoreData/EventPassUG.xcdatamodeld'
  end
end

# Handle Assets
assets_group = refactorer.main_group.find_subpath('Assets.xcassets')
if assets_group
  resources_group = refactorer.create_group_path(refactorer.main_group, ['Resources'])
  assets_group.move(resources_group)

  old_path = File.join(refactorer.project_root, 'EventPassUG', 'Assets.xcassets')
  new_path = File.join(refactorer.project_root, 'EventPassUG', 'Resources', 'Assets.xcassets')

  if Dir.exist?(old_path) && !Dir.exist?(new_path)
    FileUtils.mkdir_p(File.dirname(new_path))
    FileUtils.mv(old_path, new_path)
    puts "  ✓ Assets.xcassets"
  end

  # Update file reference
  assets_ref = refactorer.project.files.find { |f| f.path && f.path.include?('Assets.xcassets') }
  if assets_ref
    assets_ref.path = 'Resources/Assets.xcassets'
  end
end

refactorer.save

puts "✅ Phase 7 Complete: Special cases handled"

# ============================================================================
# PHASE 8: Cleanup
# ============================================================================

puts "\n🧹 PHASE 8: Cleanup"
puts "-" * 70

refactorer.cleanup_empty_groups(['Config', 'CoreData', 'Extensions', 'Onboarding'])

# Clean up old Views subfolders if empty
views_group = refactorer.main_group.find_subpath('Views')
if views_group
  ['Common'].each do |name|
    subgroup = views_group.children.find { |c| c.display_name == name }
    if subgroup && subgroup.children.empty?
      subgroup.remove_from_project

      dir_path = File.join(refactorer.project_root, 'EventPassUG', 'Views', name)
      Dir.rmdir(dir_path) if Dir.exist?(dir_path) && Dir.empty?(dir_path)

      puts "  ✓ Removed empty: Views/#{name}/"
    end
  end
end

refactorer.save

puts "✅ Phase 8 Complete: Cleanup done"

# ============================================================================
# FINAL SUMMARY
# ============================================================================

puts "\n" + "=" * 70
puts "🎉 REFACTORING COMPLETE!"
puts "=" * 70

total_files = phase1_files.size + phase2_files.size + phase3_files.size +
              phase4_files.size + phase5a_files.size + phase5b_files.size +
              phase5c_files.size + phase5d_files.size + phase5e_files.size +
              phase6a_files.size + phase6b_files.size + phase6c_files.size

puts "\n📊 Summary:"
puts "  • Total files migrated: ~#{total_files}"
puts "  • New folder structure created"
puts "  • Old empty folders removed"
puts "  • Special cases handled (CoreData, Assets)"

puts "\n🔍 Next Step:"
puts "  Run: xcodebuild -project EventPassUG.xcodeproj -scheme EventPassUG -sdk iphonesimulator build"
puts "\n"
