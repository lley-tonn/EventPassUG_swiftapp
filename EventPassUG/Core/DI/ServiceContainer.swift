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
    let refundService: RefundRepositoryProtocol
    let cancellationService: CancellationRepositoryProtocol

    init(
        authService: AuthRepositoryProtocol,
        eventService: EventRepositoryProtocol,
        ticketService: TicketRepositoryProtocol,
        paymentService: PaymentRepositoryProtocol,
        notificationService: NotificationRepositoryProtocol = MockNotificationRepository(),
        userPreferencesService: UserPreferencesRepositoryProtocol = MockUserPreferencesRepository(),
        refundService: RefundRepositoryProtocol = MockRefundRepository(),
        cancellationService: CancellationRepositoryProtocol = MockCancellationRepository()
    ) {
        self.authService = authService
        self.eventService = eventService
        self.ticketService = ticketService
        self.paymentService = paymentService
        self.notificationService = notificationService
        self.userPreferencesService = userPreferencesService
        self.refundService = refundService
        self.cancellationService = cancellationService
    }
}
