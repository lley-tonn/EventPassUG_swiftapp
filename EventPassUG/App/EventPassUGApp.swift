//
//  EventPassUGApp.swift
//  EventPassUG
//
//  Main app entry point with dependency injection and Core Data setup
//

import SwiftUI

@main
struct EventPassUGApp: App {
    // Core Data persistence controller
    let persistenceController = PersistenceController.shared

    // Service container for dependency injection
    let services: ServiceContainer

    init() {
        // Initialize services with mock implementations
        // TODO: Replace with real implementations when backend is ready
        services = ServiceContainer(
            authService: MockAuthRepository(),
            eventService: MockEventRepository(),
            ticketService: MockTicketRepository(),
            paymentService: MockPaymentRepository()
        )

        // Configure app-wide appearance
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(services)
                .environmentObject(services.authService as! MockAuthRepository)
        }
    }

    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()

        // Ensure title is visible in both light and dark modes
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}
