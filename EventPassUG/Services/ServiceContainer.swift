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

    init(
        authService: AuthServiceProtocol,
        eventService: EventServiceProtocol,
        ticketService: TicketServiceProtocol,
        paymentService: PaymentServiceProtocol
    ) {
        self.authService = authService
        self.eventService = eventService
        self.ticketService = ticketService
        self.paymentService = paymentService
    }
}
