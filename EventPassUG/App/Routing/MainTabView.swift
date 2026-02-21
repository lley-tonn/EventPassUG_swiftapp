//
//  MainTabView.swift
//  EventPassUG
//
//  Main tab navigation for role-based UI
//

import SwiftUI

struct MainTabView: View {
    let userRole: UserRole?  // Now optional for guest mode
    @State private var selectedTab = 0
    @EnvironmentObject var authService: MockAuthRepository

    // Organizer signup flow state (shared across tabs)
    @State private var showingOrganizerSignup = false

    // Binding to tell parent view (ContentView) that organizer signup is in progress
    @Binding var organizerSignupInProgress: Bool

    // Effective role: default to attendee for guests
    private var effectiveRole: UserRole {
        userRole ?? .attendee
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            if effectiveRole == .attendee {
                // Attendee tabs (or guest)
                AttendeeHomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)

                // Tickets tab: Show placeholder for guests
                Group {
                    if authService.isAuthenticated {
                        TicketsView()
                    } else {
                        GuestTicketsPlaceholder()
                    }
                }
                .tabItem {
                    Label("Tickets", systemImage: "ticket.fill")
                }
                .tag(1)

                // Profile tab: Show placeholder for guests
                Group {
                    if authService.isAuthenticated {
                        ProfileView()
                    } else {
                        GuestProfilePlaceholder(showingOrganizerSignup: $showingOrganizerSignup)
                    }
                }
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
            } else {
                // Organizer tabs
                OrganizerHomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)

                OrganizerDashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "chart.bar.fill")
                    }
                    .tag(1)

                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                    .tag(2)
            }
        }
        .accentColor(RoleConfig.getPrimaryColor(for: effectiveRole))
        .onChange(of: selectedTab) { _ in
            HapticFeedback.selection()
        }
        // Organizer signup flow - presented at TabView level to persist across auth state changes
        .fullScreenCover(isPresented: $showingOrganizerSignup) {
            OrganizerSignupFlowView(authService: authService) {
                showingOrganizerSignup = false
                organizerSignupInProgress = false
            }
        }
        .onChange(of: showingOrganizerSignup) { isShowing in
            // Sync with parent ContentView so it doesn't switch views during signup
            organizerSignupInProgress = isShowing
        }
    }
}

// Convenience initializer for when no binding is needed
extension MainTabView {
    init(userRole: UserRole?) {
        self.userRole = userRole
        self._organizerSignupInProgress = .constant(false)
    }
}

#Preview {
    MainTabView(userRole: .attendee, organizerSignupInProgress: .constant(false))
        .environmentObject(MockAuthRepository())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
