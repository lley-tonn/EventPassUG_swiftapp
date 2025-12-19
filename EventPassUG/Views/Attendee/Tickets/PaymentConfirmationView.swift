//
//  PaymentConfirmationView.swift
//  EventPassUG
//
//  Safe payment confirmation UI with mobile number verification
//  Prevents accidental payments with wrong numbers
//

import SwiftUI

struct PaymentConfirmationView: View {
    let event: Event
    let ticketType: TicketType
    let quantity: Int
    let totalAmount: Double
    let paymentMethod: PaymentMethod
    let userPhoneNumber: String?

    @StateObject private var viewModel = PaymentConfirmationViewModel()
    @Environment(\.dismiss) var dismiss

    var onConfirm: (String, Bool) -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Header section
                        headerSection

                        // Main content based on state
                        if viewModel.isEditingNumber {
                            editNumberSection
                        } else {
                            confirmationSection
                        }

                        // Payment details
                        paymentDetailsSection

                        // Security notice
                        securityNoticeSection
                    }
                    .padding(AppSpacing.lg)
                }
            }
            .navigationTitle("Confirm Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        handleCancel()
                    }
                    .disabled(viewModel.isProcessing)
                }
            }
            .onAppear {
                viewModel.initializeWith(
                    mobileNumber: userPhoneNumber,
                    paymentMethod: paymentMethod,
                    userPhoneNumber: userPhoneNumber
                )
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(AppDesign.Colors.primary.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: paymentMethod.iconName)
                    .font(.system(size: 40))
                    .foregroundColor(AppDesign.Colors.primary)
            }

            // Title
            Text("Confirm Your Payment")
                .font(AppDesign.Typography.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Subtitle
            Text("Please verify your mobile money number before proceeding")
                .font(AppDesign.Typography.secondary)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.bottom, AppSpacing.md)
    }

    // MARK: - Confirmation Section

    private var confirmationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Payment method label
            Text("Payment Method")
                .font(AppDesign.Typography.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .fontWeight(.semibold)

            // Payment method card
            HStack(spacing: AppSpacing.md) {
                Image(systemName: paymentMethod.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(AppDesign.Colors.primary)
                    .frame(width: 40)

                Text(paymentMethod.rawValue)
                    .font(AppDesign.Typography.body)
                    .fontWeight(.medium)

                Spacer()
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(AppCornerRadius.medium)

            Divider()
                .padding(.vertical, AppSpacing.xs)

            // Mobile number section
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Payment will be requested from:")
                    .font(AppDesign.Typography.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .fontWeight(.semibold)

                // Number display
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "phone.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(AppDesign.Colors.primary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.maskedNumber)
                            .font(AppDesign.Typography.cardTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text(paymentMethod.numberFormatHelp)
                            .font(AppDesign.Typography.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                        .fill(AppDesign.Colors.primary.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                        .stroke(AppDesign.Colors.primary.opacity(0.3), lineWidth: 1.5)
                )

                // Edit number button
                Button(action: {
                    viewModel.startEditingNumber()
                    HapticFeedback.selection()
                }) {
                    HStack {
                        Image(systemName: "pencil.circle.fill")
                        Text("Use a different number")
                            .fontWeight(.medium)
                    }
                    .font(AppDesign.Typography.body)
                    .foregroundColor(AppDesign.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(AppCornerRadius.medium)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isProcessing)
            }

            // Confirmation prompt
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(.green)

                    Text("Is this the correct number?")
                        .font(AppDesign.Typography.body)
                        .fontWeight(.semibold)
                }
                .padding(.top, AppSpacing.md)

                Text("You'll receive an STK push notification to approve the payment with your PIN.")
                    .font(AppDesign.Typography.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.green.opacity(0.05))
            .cornerRadius(AppCornerRadius.medium)

            // Confirm button
            Button(action: handleConfirm) {
                HStack(spacing: AppSpacing.sm) {
                    if viewModel.isProcessing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Yes, Proceed with Payment")
                            .fontWeight(.semibold)
                    }
                }
                .font(AppDesign.Typography.buttonPrimary)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canProceed ? AppDesign.Colors.primary : Color.gray)
                .cornerRadius(AppCornerRadius.medium)
                .shadow(color: viewModel.canProceed ? AppDesign.Colors.primary.opacity(0.3) : Color.clear, radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canProceed)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(AppCornerRadius.large)
    }

    // MARK: - Edit Number Section

    private var editNumberSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Title
            HStack {
                Image(systemName: "pencil.circle.fill")
                    .foregroundColor(AppDesign.Colors.primary)
                Text("Enter Mobile Money Number")
                    .font(AppDesign.Typography.headline)
                    .fontWeight(.semibold)
            }

            // Provider info
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text(paymentMethod.numberFormatHelp)
                    .font(AppDesign.Typography.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(AppCornerRadius.small)

            // Number input
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                TextField("e.g., 077 1234567", text: $viewModel.mobileNumber)
                    .keyboardType(.phonePad)
                    .font(AppDesign.Typography.cardTitle)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(AppCornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                            .stroke(
                                viewModel.validationError != nil ? Color.red : AppDesign.Colors.primary.opacity(0.3),
                                lineWidth: 1.5
                            )
                    )
                    .onChange(of: viewModel.mobileNumber) { _ in
                        viewModel.validateNumber()
                    }

                // Validation error
                if let error = viewModel.validationError {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(error.localizedDescription)
                            .font(AppDesign.Typography.caption)
                    }
                    .foregroundColor(.red)
                }
            }

            // Save as default option
            Button(action: {
                viewModel.saveAsDefault.toggle()
                HapticFeedback.selection()
            }) {
                HStack {
                    Image(systemName: viewModel.saveAsDefault ? "checkmark.square.fill" : "square")
                        .foregroundColor(viewModel.saveAsDefault ? AppDesign.Colors.primary : .gray)
                        .font(.system(size: 22))

                    Text("Remember this number for future payments")
                        .font(AppDesign.Typography.body)
                        .foregroundColor(.primary)

                    Spacer()
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(AppCornerRadius.medium)
            }
            .buttonStyle(.plain)

            // Action buttons
            HStack(spacing: AppSpacing.md) {
                // Cancel edit button
                Button(action: {
                    viewModel.cancelEditingNumber()
                    HapticFeedback.light()
                }) {
                    Text("Cancel")
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(AppCornerRadius.medium)
                }
                .buttonStyle(.plain)

                // Confirm edit button
                Button(action: {
                    viewModel.confirmEditedNumber()
                    HapticFeedback.success()
                }) {
                    Text("Confirm Number")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            viewModel.validationError == nil && !viewModel.mobileNumber.isEmpty
                                ? AppDesign.Colors.primary
                                : Color.gray
                        )
                        .cornerRadius(AppCornerRadius.medium)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.validationError != nil || viewModel.mobileNumber.isEmpty)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(AppCornerRadius.large)
    }

    // MARK: - Payment Details Section

    private var paymentDetailsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Payment Summary")
                .font(AppDesign.Typography.headline)
                .fontWeight(.semibold)

            VStack(spacing: AppSpacing.sm) {
                // Event name
                HStack {
                    Text("Event")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(event.title)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .font(AppDesign.Typography.body)

                Divider()

                // Ticket type
                HStack {
                    Text("Ticket")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(ticketType.name)
                        .fontWeight(.medium)
                }
                .font(AppDesign.Typography.body)

                Divider()

                // Quantity
                HStack {
                    Text("Quantity")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(quantity)")
                        .fontWeight(.medium)
                }
                .font(AppDesign.Typography.body)

                Divider()

                // Total amount
                HStack {
                    Text("Total Amount")
                        .fontWeight(.bold)
                    Spacer()
                    Text("UGX \(Int(totalAmount).formatted())")
                        .font(AppDesign.Typography.cardTitle)
                        .fontWeight(.bold)
                        .foregroundColor(AppDesign.Colors.primary)
                }
                .font(AppDesign.Typography.body)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(AppCornerRadius.large)
    }

    // MARK: - Security Notice

    private var securityNoticeSection: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: "lock.shield.fill")
                .foregroundColor(.green)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 4) {
                Text("Secure Payment")
                    .font(AppDesign.Typography.body)
                    .fontWeight(.semibold)

                Text("Your payment is processed securely. You'll receive an STK push to your phone to complete the transaction.")
                    .font(AppDesign.Typography.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.05))
        .cornerRadius(AppCornerRadius.medium)
    }

    // MARK: - Actions

    private func handleConfirm() {
        guard viewModel.canProceed else { return }

        viewModel.confirmPayment()
        HapticFeedback.success()

        // Call the completion handler
        onConfirm(viewModel.mobileNumber, viewModel.saveAsDefault)

        // Dismiss after a short delay to show processing state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }

    private func handleCancel() {
        viewModel.cancelPayment()
        HapticFeedback.light()
        onCancel()
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    PaymentConfirmationView(
        event: Event.samples[0],
        ticketType: Event.samples[0].ticketTypes[0],
        quantity: 2,
        totalAmount: 100000,
        paymentMethod: .mtnMomo,
        userPhoneNumber: "+256771234567",
        onConfirm: { number, save in
            print("Confirmed: \(number), Save: \(save)")
        },
        onCancel: {
            print("Cancelled")
        }
    )
}
