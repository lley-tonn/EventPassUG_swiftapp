//
//  SalesCountdownTimer.swift
//  EventPassUG
//
//  Real-time countdown timer for ticket sales
//  Updates automatically and shows urgency
//

import SwiftUI
import Combine

struct SalesCountdownTimer: View {
    let event: Event
    let style: CountdownStyle

    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer.TimerPublisher = Timer.publish(every: 1, on: .main, in: .common)
    @State private var cancellable: AnyCancellable?

    enum CountdownStyle {
        case badge      // Compact badge style
        case inline     // Inline with icon
        case card       // Card with full details
    }

    var body: some View {
        Group {
            if event.isTicketSalesOpen {
                switch style {
                case .badge:
                    badgeView
                case .inline:
                    inlineView
                case .card:
                    cardView
                }
            } else {
                closedView
            }
        }
        .onAppear {
            updateTime()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    // MARK: - Badge Style

    private var badgeView: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.fill")
                .font(AppDesign.Typography.caption)

            if let countdown = event.shortCountdown {
                Text(countdown)
                    .font(AppDesign.Typography.captionEmphasized)
            }
        }
        .foregroundColor(urgencyColor)
        .padding(.horizontal, AppDesign.Spacing.sm)
        .padding(.vertical, 4)
        .background(urgencyColor.opacity(0.15))
        .cornerRadius(AppDesign.CornerRadius.badge)
    }

    // MARK: - Inline Style

    private var inlineView: some View {
        HStack(spacing: AppDesign.Spacing.xs) {
            Image(systemName: "clock.fill")
                .font(AppDesign.Typography.callout)

            Text("Sales end in")
                .font(AppDesign.Typography.callout)

            if let countdown = event.formattedTimeUntilSalesClose {
                Text(countdown)
                    .font(AppDesign.Typography.calloutEmphasized)
            }
        }
        .foregroundColor(urgencyColor)
    }

    // MARK: - Card Style

    private var cardView: some View {
        HStack(spacing: AppDesign.Spacing.md) {
            Image(systemName: "clock.badge.exclamationmark.fill")
                .font(AppDesign.Typography.title2)
                .foregroundColor(urgencyColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("Ticket sales ending soon")
                    .font(AppDesign.Typography.calloutEmphasized)
                    .foregroundColor(AppDesign.Colors.textPrimary)

                if let countdown = event.formattedTimeUntilSalesClose {
                    Text("\(countdown) remaining")
                        .font(AppDesign.Typography.secondary)
                        .foregroundColor(AppDesign.Colors.textSecondary)
                }
            }

            Spacer()
        }
        .padding(AppDesign.Spacing.md)
        .background(urgencyColor.opacity(0.1))
        .cornerRadius(AppDesign.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppDesign.CornerRadius.md)
                .stroke(urgencyColor.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Closed View

    private var closedView: some View {
        HStack(spacing: AppDesign.Spacing.xs) {
            Image(systemName: "xmark.circle.fill")
                .font(AppDesign.Typography.callout)

            Text(event.ticketSalesStatusMessage)
                .font(AppDesign.Typography.callout)
        }
        .foregroundColor(AppDesign.Colors.error)
    }

    // MARK: - Helpers

    private var urgencyColor: Color {
        guard let remaining = event.timeUntilSalesClose else {
            return AppDesign.Colors.textSecondary
        }

        if remaining < 3600 { // Less than 1 hour
            return AppDesign.Colors.error
        } else if remaining < 86400 { // Less than 1 day
            return AppDesign.Colors.warning
        } else {
            return AppDesign.Colors.success
        }
    }

    private func updateTime() {
        if let remaining = event.timeUntilSalesClose {
            timeRemaining = remaining
        }
    }

    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
        cancellable = timer
            .autoconnect()
            .sink { _ in
                updateTime()

                // Stop timer if sales have closed
                if !event.isTicketSalesOpen {
                    stopTimer()
                }
            }
    }

    private func stopTimer() {
        cancellable?.cancel()
        cancellable = nil
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AppDesign.Spacing.lg) {
        // Create a sample event that starts in 2 hours
        let event = Event.samples.first!

        SalesCountdownTimer(event: event, style: .badge)
        SalesCountdownTimer(event: event, style: .inline)
        SalesCountdownTimer(event: event, style: .card)
    }
    .padding()
}
