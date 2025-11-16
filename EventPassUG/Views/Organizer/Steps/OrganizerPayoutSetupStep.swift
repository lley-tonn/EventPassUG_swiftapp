//
//  OrganizerPayoutSetupStep.swift
//  EventPassUG
//
//  Step 4: Payout method setup for organizer onboarding
//

import SwiftUI

struct OrganizerPayoutSetupStep: View {
    @EnvironmentObject var authService: MockAuthService
    @Binding var profile: OrganizerProfile
    let onNext: () -> Void
    let onBack: () -> Void

    @State private var selectedPayoutType: PayoutMethodType = .mtnMomo
    @State private var useAccountPhone = true
    @State private var customPhoneNumber = ""
    @State private var bankName = ""
    @State private var accountNumber = ""
    @State private var accountName = ""

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Header
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 60))
                        .foregroundColor(RoleConfig.organizerPrimary)

                    Text("Payout Setup")
                        .font(AppTypography.title2)
                        .fontWeight(.bold)

                    Text("Choose how you want to receive payments from ticket sales.")
                        .font(AppTypography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AppSpacing.xl)

                // Payout method selection
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Select Payout Method")
                        .font(AppTypography.headline)

                    ForEach(PayoutMethodType.allCases, id: \.self) { method in
                        PayoutMethodOptionRow(
                            method: method,
                            isSelected: selectedPayoutType == method,
                            onSelect: { selectedPayoutType = method }
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.md)

                // Method-specific fields
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Account Details")
                        .font(AppTypography.headline)

                    switch selectedPayoutType {
                    case .mtnMomo, .airtelMoney:
                        mobileMoneyFields

                    case .bankAccount:
                        bankAccountFields
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(AppCornerRadius.medium)
                .padding(.horizontal, AppSpacing.md)

                // Info box
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Label("Important", systemImage: "info.circle.fill")
                        .font(AppTypography.headline)
                        .foregroundColor(.blue)

                    Text("Payouts are processed within 3-5 business days after each event ends. You can change your payout method anytime from your organizer settings.")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(AppCornerRadius.medium)
                .padding(.horizontal, AppSpacing.md)

                Spacer(minLength: AppSpacing.xl)

                // Navigation buttons
                VStack(spacing: AppSpacing.sm) {
                    Button(action: saveAndContinue) {
                        HStack {
                            Text("Continue")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? RoleConfig.organizerPrimary : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(AppCornerRadius.medium)
                    }
                    .disabled(!isFormValid)

                    Button(action: onBack) {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("Back")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(AppCornerRadius.medium)
                    }
                }
                .padding(.horizontal, AppSpacing.md)

                if !isFormValid {
                    Text("Please complete all required payout fields")
                        .font(AppTypography.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(.bottom, AppSpacing.lg)
        }
    }

    @ViewBuilder
    private var mobileMoneyFields: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Mobile Money Number")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)

            if let accountPhone = authService.currentUser?.phoneNumber {
                Toggle("Use my account number: \(accountPhone)", isOn: $useAccountPhone)
                    .tint(RoleConfig.organizerPrimary)
            }

            if !useAccountPhone || authService.currentUser?.phoneNumber == nil {
                TextField("+256 700 000 000", text: $customPhoneNumber)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.phonePad)
            }

            Text("Make sure this number is registered with \(selectedPayoutType.displayName)")
                .font(AppTypography.caption)
                .foregroundColor(.orange)
        }
    }

    @ViewBuilder
    private var bankAccountFields: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Bank Name")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)

                TextField("e.g., Stanbic Bank, Centenary Bank", text: $bankName)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Account Number")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)

                TextField("Your bank account number", text: $accountNumber)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Account Holder Name")
                    .font(AppTypography.caption)
                    .foregroundColor(.secondary)

                TextField("Name as it appears on account", text: $accountName)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var isFormValid: Bool {
        switch selectedPayoutType {
        case .mtnMomo, .airtelMoney:
            if useAccountPhone {
                return authService.currentUser?.phoneNumber != nil
            } else {
                return customPhoneNumber.count >= 10
            }

        case .bankAccount:
            return !bankName.isEmpty && !accountNumber.isEmpty && !accountName.isEmpty
        }
    }

    private func saveAndContinue() {
        var payoutMethod: PayoutMethod

        switch selectedPayoutType {
        case .mtnMomo, .airtelMoney:
            let phone = useAccountPhone ? authService.currentUser?.phoneNumber : customPhoneNumber
            payoutMethod = PayoutMethod(
                type: selectedPayoutType,
                phoneNumber: phone,
                isVerified: false
            )

        case .bankAccount:
            payoutMethod = PayoutMethod(
                type: selectedPayoutType,
                bankName: bankName,
                accountNumber: accountNumber,
                accountName: accountName,
                isVerified: false
            )
        }

        profile.payoutMethod = payoutMethod
        onNext()
    }
}

struct PayoutMethodOptionRow: View {
    let method: PayoutMethodType
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? RoleConfig.organizerPrimary : .gray)

                Image(systemName: method.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(methodColor)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(method.displayName)
                        .font(AppTypography.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(methodDescription)
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(isSelected ? RoleConfig.organizerPrimary.opacity(0.1) : Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(AppCornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(isSelected ? RoleConfig.organizerPrimary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var methodColor: Color {
        switch method {
        case .mtnMomo: return .yellow
        case .airtelMoney: return .red
        case .bankAccount: return .blue
        }
    }

    private var methodDescription: String {
        switch method {
        case .mtnMomo: return "Receive payments via MTN Mobile Money"
        case .airtelMoney: return "Receive payments via Airtel Money"
        case .bankAccount: return "Direct bank transfer (3-5 days)"
        }
    }
}

#Preview {
    OrganizerPayoutSetupStep(
        profile: .constant(OrganizerProfile()),
        onNext: {},
        onBack: {}
    )
    .environmentObject(MockAuthService())
}
