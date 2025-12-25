//
//  AppIntroSlidesView.swift
//  EventPassUG
//
//  First-time app intro slides shown before authentication
//

import SwiftUI

struct AppIntroSlidesView: View {
    @Binding var isComplete: Bool
    @State private var currentPage = 0
    @State private var autoAdvanceTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < 2 {
                        Button(action: complete) {
                            Text("Skip")
                                .font(AppTypography.callout)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, AppSpacing.sm)
                        }
                    }
                }
                .padding(.top, AppSpacing.md)
                .padding(.trailing, AppSpacing.md)

                // Slides
                TabView(selection: $currentPage) {
                    IntroSlide1()
                        .tag(0)

                    IntroSlide2()
                        .tag(1)

                    IntroSlide3()
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .onChange(of: currentPage) { _ in
                    startAutoAdvanceTimer()
                }

                // Navigation buttons
                HStack(spacing: AppSpacing.md) {
                    // Show Next or Get Started button
                    if currentPage < 2 {
                        Button(action: nextPage) {
                            Text("Next")
                                .font(AppTypography.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [RoleConfig.attendeePrimary, Color(hex: "FF9500")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(AppCornerRadius.medium)
                                .shadow(color: RoleConfig.attendeePrimary.opacity(0.4), radius: 15, y: 8)
                        }
                    } else {
                        Button(action: complete) {
                            Text("Get Started")
                                .font(AppTypography.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [RoleConfig.attendeePrimary, Color(hex: "FF9500")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(AppCornerRadius.medium)
                                .shadow(color: RoleConfig.attendeePrimary.opacity(0.4), radius: 15, y: 8)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            startAutoAdvanceTimer()
        }
        .onDisappear {
            autoAdvanceTask?.cancel()
        }
    }

    private func startAutoAdvanceTimer() {
        // Cancel existing timer
        autoAdvanceTask?.cancel()

        // Don't start timer on last slide
        guard currentPage < 2 else { return }

        // Start new timer for 5 seconds
        autoAdvanceTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds

            // Check if task was cancelled
            guard !Task.isCancelled else { return }

            // Auto-advance to next slide
            await MainActor.run {
                withAnimation {
                    if currentPage < 2 {
                        currentPage += 1
                    }
                }
            }
        }
    }

    private func nextPage() {
        autoAdvanceTask?.cancel()
        withAnimation {
            HapticFeedback.light()
            if currentPage < 2 {
                currentPage += 1
            }
        }
    }

    private func complete() {
        autoAdvanceTask?.cancel()
        withAnimation {
            HapticFeedback.success()
            isComplete = true
        }
    }
}

// MARK: - Slide 1: Discover Events

struct IntroSlide1: View {
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            // Icon illustration
            ZStack {
                // Background circles
                Circle()
                    .fill(RoleConfig.attendeePrimary.opacity(0.2))
                    .frame(width: 220, height: 220)

                Circle()
                    .fill(RoleConfig.attendeePrimary.opacity(0.12))
                    .frame(width: 180, height: 180)

                // Icons
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 40))
                            .foregroundColor(RoleConfig.attendeePrimary)
                            .rotationEffect(.degrees(-15))

                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 35))
                            .foregroundColor(.yellow.opacity(0.9))

                        Image(systemName: "theatermasks.fill")
                            .font(.system(size: 40))
                            .foregroundColor(RoleConfig.organizerPrimary)
                            .rotationEffect(.degrees(15))
                    }
                }
            }
            .padding(.bottom, AppSpacing.lg)

            // Title
            Text("Find the Hottest Events\nAround You")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            // Subtitle
            Text("Concerts, festivals, parties, conferences — whatever you're into, it's all here.\nSwipe, explore, and never miss a vibe again.")
                .font(AppTypography.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, AppSpacing.xl)

            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
    }
}

// MARK: - Slide 2: Fast Ticketing

struct IntroSlide2: View {
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            // Icon illustration
            ZStack {
                // Background circles
                Circle()
                    .fill(RoleConfig.organizerPrimary.opacity(0.2))
                    .frame(width: 220, height: 220)

                Circle()
                    .fill(RoleConfig.organizerPrimary.opacity(0.12))
                    .frame(width: 180, height: 180)

                // Icons
                VStack(spacing: 16) {
                    // QR Code
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white)
                            .frame(width: 90, height: 90)

                        Image(systemName: "qrcode")
                            .font(.system(size: 60))
                            .foregroundColor(.black)
                    }
                    .shadow(color: RoleConfig.attendeePrimary.opacity(0.3), radius: 12)

                    // Payment icons
                    HStack(spacing: 16) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 30))
                            .foregroundColor(.green)

                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 30))
                            .foregroundColor(RoleConfig.attendeePrimary)

                        Image(systemName: "phone.badge.waveform.fill")
                            .font(.system(size: 30))
                            .foregroundColor(RoleConfig.organizerPrimary)
                    }
                }
            }
            .padding(.bottom, AppSpacing.lg)

            // Title
            Text("Buy Tickets in Seconds")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Subtitle
            Text("Pay with Mobile Money or cards using our secure Flutterwave checkout.\nYour ticket comes with a QR code — no printing, no stress.")
                .font(AppTypography.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, AppSpacing.xl)

            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
    }
}

// MARK: - Slide 3: Become an Organizer

struct IntroSlide3: View {
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            // Icon illustration
            ZStack {
                // Background circles
                Circle()
                    .fill(RoleConfig.attendeePrimary.opacity(0.2))
                    .frame(width: 220, height: 220)

                Circle()
                    .fill(RoleConfig.attendeePrimary.opacity(0.12))
                    .frame(width: 180, height: 180)

                // Icons
                VStack(spacing: 12) {
                    Image(systemName: "megaphone.fill")
                        .font(.system(size: 50))
                        .foregroundColor(RoleConfig.attendeePrimary)

                    HStack(spacing: 16) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 35))
                            .foregroundColor(RoleConfig.organizerPrimary)

                        Image(systemName: "ticket.fill")
                            .font(.system(size: 35))
                            .foregroundColor(.yellow)

                        Image(systemName: "person.3.fill")
                            .font(.system(size: 35))
                            .foregroundColor(Color(hex: "FFB84D"))
                    }
                }
            }
            .padding(.bottom, AppSpacing.lg)

            // Title
            Text("Host Events Like a Pro")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Subtitle
            Text("Create events, track sales in real time, and reach thousands of attendees.\nEverything you need to grow your show — all in one app.")
                .font(AppTypography.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, AppSpacing.xl)

            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
    }
}

#Preview {
    AppIntroSlidesView(isComplete: .constant(false))
}
