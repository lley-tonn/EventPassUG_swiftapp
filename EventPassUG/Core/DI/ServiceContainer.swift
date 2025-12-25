//
//  ServiceContainer.swift
//  EventPassUG
//
//  Dependency injection container for services
//

import Foundation

class ServiceContainer: ObservableObject {
    let authService: AuthRepositoryProtocol
    let eventService: EventRepositoryProtocol
    let ticketService: TicketRepositoryProtocol
    let paymentService: PaymentRepositoryProtocol
    let notificationService: NotificationRepositoryProtocol
    let userPreferencesService: UserPreferencesRepositoryProtocol

    init(
        authService: AuthRepositoryProtocol,
        eventService: EventRepositoryProtocol,
        ticketService: TicketRepositoryProtocol,
        paymentService: PaymentRepositoryProtocol,
        notificationService: NotificationRepositoryProtocol = MockNotificationRepository(),
        userPreferencesService: UserPreferencesRepositoryProtocol = MockUserPreferencesRepository()
    ) {
        self.authService = authService
        self.eventService = eventService
        self.ticketService = ticketService
        self.paymentService = paymentService
        self.notificationService = notificationService
        self.userPreferencesService = userPreferencesService
    }
}
