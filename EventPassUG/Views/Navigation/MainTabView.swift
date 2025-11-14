//
//  MainTabView.swift
//  EventPassUG
//
//  Main tab navigation for role-based UI
//

import SwiftUI

struct MainTabView: View {
    let userRole: UserRole
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            if userRole == .attendee {
                // Attendee tabs
                AttendeeHomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)

                TicketsView()
                    .tabItem {
                        Label("Tickets", systemImage: "ticket.fill")
                    }
                    .tag(1)

                ProfileView()
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
        .accentColor(RoleConfig.getPrimaryColor(for: userRole))
        .onChange(of: selectedTab) { _ in
            HapticFeedback.selection()
        }
    }
}

#Preview {
    MainTabView(userRole: .attendee)
        .environmentObject(MockAuthService())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
