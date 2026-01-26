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
                        GuestProfilePlaceholder()
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
    }
}

#Preview {
    MainTabView(userRole: .attendee)
        .environmentObject(MockAuthRepository())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
