//
//  ServiceContainer.swift
//  EventPassUG
//
//  Dependency injection container for services
//

import Foundation

class ServiceContainer: ObservableObject {
    let authService: AuthServiceProtocol
    let eventService: EventServiceProtocol
    let ticketService: TicketServiceProtocol
    let paymentService: PaymentServiceProtocol
    let notificationService: NotificationServiceProtocol
    let userPreferencesService: UserPreferencesServiceProtocol

    init(
        authService: AuthServiceProtocol,
        eventService: EventServiceProtocol,
        ticketService: TicketServiceProtocol,
        paymentService: PaymentServiceProtocol,
        notificationService: NotificationServiceProtocol = MockNotificationService(),
        userPreferencesService: UserPreferencesServiceProtocol = MockUserPreferencesService()
    ) {
        self.authService = authService
        self.eventService = eventService
        self.ticketService = ticketService
        self.paymentService = paymentService
        self.notificationService = notificationService
        self.userPreferencesService = userPreferencesService
    }
}
