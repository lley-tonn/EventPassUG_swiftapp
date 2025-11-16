//
//  PaymentMethodsView.swift
//  EventPassUG
//
//  Payment methods management with card scanning and mobile money
//

import SwiftUI
import AVFoundation

struct PaymentMethodsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: MockAuthService
    @StateObject private var preferencesService = MockUserPreferencesService()

    @State private var savedMethods: [SavedPaymentMethod] = []
    @State private var showingAddMethod = false
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showDeleteConfirmation = false
    @State private var methodToDelete: SavedPaymentMethod?

    var body: some View {
        List {
            if isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            } else if savedMethods.isEmpty {
                Section {
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)

                        Text("No Payment Methods")
                            .font(AppTypography.headline)

                        Text("Add a payment method to make purchasing tickets faster and easier.")
                            .font(AppTypography.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xl)
                }
            } else {
                Section {
                    ForEach(savedMethods) { method in
                        PaymentMethodRow(
                            method: method,
                            onSetDefault: {
                                setDefaultMethod(method.id)
                            },
                            onDelete: {
                                methodToDelete = method
                                showDeleteConfirmation = true
                            }
                        )
                    }
                } header: {
                    Text("Saved Methods")
                } footer: {
                    Text("The default method will be pre-selected during checkout.")
                }
            }

            Section {
                Button(action: {
                    showingAddMethod = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(RoleConfig.getPrimaryColor(for: authService.currentUser?.role ?? .attendee))

                        Text("Add Payment Method")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .navigationTitle("Payment Methods")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadPaymentMethods()
        }
        .sheet(isPresented: $showingAddMethod) {
            AddPaymentMethodView(preferencesService: preferencesService) {
                loadPaymentMethods()
            }
            .environmentObject(authService)
        }
        .confirmationDialog("Delete Payment Method?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            if let method = methodToDelete {
                Button("Delete \(method.displayName)", role: .destructive) {
                    deleteMethod(method.id)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private func loadPaymentMethods() {
        isLoading = true

        Task {
            do {
                try await preferencesService.fetchPreferences()

                await MainActor.run {
                    savedMethods = preferencesService.savedPaymentMethods
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func setDefaultMethod(_ methodId: UUID) {
        Task {
            do {
                try await preferencesService.setDefaultPaymentMethod(methodId)

                await MainActor.run {
                    savedMethods = preferencesService.savedPaymentMethods
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    HapticFeedback.error()
                }
            }
        }
    }

    private func deleteMethod(_ methodId: UUID) {
        Task {
            do {
                try await preferencesService.removePaymentMethod(methodId)

                await MainActor.run {
                    savedMethods = preferencesService.savedPaymentMethods
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    HapticFeedback.error()
                }
            }
        }
    }
}

// MARK: - Payment Method Row

struct PaymentMethodRow: View {
    let method: SavedPaymentMethod
    let onSetDefault: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Image(systemName: method.type.iconName)
                .font(.system(size: 24))
                .foregroundColor(method.isDefault ? .green : .gray)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(method.formattedDisplay)
                    .font(AppTypography.body)

                if method.type == .card, let month = method.expiryMonth, let year = method.expiryYear {
                    Text("Expires \(month)/\(year)")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }

                if method.isDefault {
                    Label("Default", systemImage: "checkmark.circle.fill")
                        .font(AppTypography.caption)
                        .foregroundColor(.green)
                }
            }

            Spacer()

            Menu {
                if !method.isDefault {
                    Button(action: onSetDefault) {
                        Label("Set as Default", systemImage: "star.fill")
                    }
                }

                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Payment Method View

struct AddPaymentMethodView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: MockAuthService
    @ObservedObject var preferencesService: MockUserPreferencesService

    let onSaved: () -> Void

    @State private var selectedType: PaymentMethodType = .mtnMomo
    @State private var mobileMoneyNumber: String = ""
    @State private var useProfileNumber = true
    @State private var cardholderName: String = ""
    @State private var cardNumber: String = ""
    @State private var expiryDate: String = ""
    @State private var cvv: String = ""
    @State private var setAsDefault = true
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showCardScanner = false

    private var userRole: UserRole {
        authService.currentUser?.currentActiveRole ?? authService.currentUser?.role ?? .attendee
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Payment Type Selection Cards
                    paymentTypeSelectionSection

                    // Type-specific fields
                    if selectedType == .mtnMomo || selectedType == .airtelMoney {
                        mobileMoneySection
                    } else if selectedType == .card {
                        cardSection
                    }

                    // Default toggle
                    defaultMethodSection

                    // Save button
                    saveButtonSection
                }
                .padding(AppSpacing.lg)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Add Payment Method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if let phone = authService.currentUser?.phoneNumber {
                mobileMoneyNumber = phone
            }
            if let user = authService.currentUser {
                cardholderName = user.fullName
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showCardScanner) {
            CardScannerSwiftUIView(
                onScanned: { number, expiry, name in
                    cardNumber = number
                    if let exp = expiry {
                        expiryDate = exp
                    }
                    if let cardName = name {
                        cardholderName = cardName
                    }
                },
                onCancel: {
                    // Scanner cancelled
                }
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Payment Type Selection

    private var paymentTypeSelectionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Payment Type")
                .font(AppTypography.headline)
                .foregroundColor(.primary)

            VStack(spacing: AppSpacing.sm) {
                // Mobile Money Option
                PaymentTypeCard(
                    icon: "phone.fill",
                    title: "Mobile Money",
                    subtitle: "MTN MoMo or Airtel Money",
                    isSelected: selectedType == .mtnMomo || selectedType == .airtelMoney,
                    accentColor: RoleConfig.getPrimaryColor(for: userRole)
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedType = .mtnMomo
                    }
                    HapticFeedback.selection()
                }

                // Card Option
                PaymentTypeCard(
                    icon: "creditcard.fill",
                    title: "Card",
                    subtitle: "Visa or Mastercard",
                    isSelected: selectedType == .card,
                    accentColor: RoleConfig.getPrimaryColor(for: userRole)
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedType = .card
                    }
                    HapticFeedback.selection()
                }
            }
        }
    }

    // MARK: - Mobile Money Section

    private var mobileMoneySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Provider selection
            Text("Select Provider")
                .font(AppTypography.headline)
                .foregroundColor(.primary)

            HStack(spacing: AppSpacing.sm) {
                MobileMoneyProviderButton(
                    title: "MTN MoMo",
                    color: .yellow,
                    isSelected: selectedType == .mtnMomo
                ) {
                    selectedType = .mtnMomo
                    HapticFeedback.selection()
                }

                MobileMoneyProviderButton(
                    title: "Airtel Money",
                    color: .red,
                    isSelected: selectedType == .airtelMoney
                ) {
                    selectedType = .airtelMoney
                    HapticFeedback.selection()
                }
            }

            // Phone number section
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Mobile Money Number")
                    .font(AppTypography.headline)
                    .foregroundColor(.primary)

                if let phone = authService.currentUser?.phoneNumber {
                    // Use account number option
                    VStack(spacing: AppSpacing.sm) {
                        Button(action: {
                            useProfileNumber = true
                            mobileMoneyNumber = phone
                        }) {
                            HStack {
                                Image(systemName: useProfileNumber ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(useProfileNumber ? RoleConfig.getPrimaryColor(for: userRole) : .gray)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Use account number")
                                        .font(AppTypography.body)
                                        .foregroundColor(.primary)

                                    Text(phone)
                                        .font(AppTypography.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(AppCornerRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                    .stroke(useProfileNumber ? RoleConfig.getPrimaryColor(for: userRole) : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            useProfileNumber = false
                        }) {
                            HStack {
                                Image(systemName: !useProfileNumber ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(!useProfileNumber ? RoleConfig.getPrimaryColor(for: userRole) : .gray)

                                Text("Enter different number")
                                    .font(AppTypography.body)
                                    .foregroundColor(.primary)

                                Spacer()
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(AppCornerRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                                    .stroke(!useProfileNumber ? RoleConfig.getPrimaryColor(for: userRole) : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    if !useProfileNumber {
                        TextField("Phone Number (e.g., 0771234567)", text: $mobileMoneyNumber)
                            .keyboardType(.phonePad)
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(AppCornerRadius.medium)

                        if !isValidUgandanPhone(mobileMoneyNumber) && !mobileMoneyNumber.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                Text("Enter a valid Ugandan phone number")
                                    .font(AppTypography.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                } else {
                    TextField("Phone Number (e.g., 0771234567)", text: $mobileMoneyNumber)
                        .keyboardType(.phonePad)
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(AppCornerRadius.medium)

                    if !isValidUgandanPhone(mobileMoneyNumber) && !mobileMoneyNumber.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text("Enter a valid Ugandan phone number")
                                .font(AppTypography.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(AppCornerRadius.medium)

            Text("You'll receive an STK push to approve payments with your PIN.")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Card Section

    private var cardSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Card Details")
                .font(AppTypography.headline)
                .foregroundColor(.primary)

            VStack(spacing: AppSpacing.md) {
                // Cardholder Name
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Cardholder Name")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)

                    TextField("Name on card", text: $cardholderName)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                        .cornerRadius(AppCornerRadius.small)
                }

                // Card Number
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Card Number")
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        TextField("1234 5678 9012 3456", text: $cardNumber)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.plain)
                            .onChange(of: cardNumber) { newValue in
                                cardNumber = formatCardNumber(newValue)
                            }

                        // Card brand icon
                        if !cardNumber.isEmpty {
                            Image(systemName: cardBrandIcon)
                                .foregroundColor(.gray)
                        }

                        Button(action: {
                            showCardScanner = true
                        }) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20))
                                .foregroundColor(RoleConfig.getPrimaryColor(for: userRole))
                        }
                    }
                    .padding()
                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                    .cornerRadius(AppCornerRadius.small)
                }

                // Expiry and CVV
                HStack(spacing: AppSpacing.md) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Expiry Date")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)

                        TextField("MM/YY", text: $expiryDate)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.center)
                            .onChange(of: expiryDate) { newValue in
                                expiryDate = formatExpiryDate(newValue)
                            }
                            .padding()
                            .background(Color(UIColor.tertiarySystemGroupedBackground))
                            .cornerRadius(AppCornerRadius.small)
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("CVV")
                            .font(AppTypography.caption)
                            .foregroundColor(.secondary)

                        SecureField("123", text: $cvv)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(Color(UIColor.tertiarySystemGroupedBackground))
                            .cornerRadius(AppCornerRadius.small)
                    }
                }

                // Scan Card Button
                Button(action: {
                    showCardScanner = true
                }) {
                    HStack {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 20))

                        Text("Scan Card Using Camera")
                            .font(AppTypography.body)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(RoleConfig.getPrimaryColor(for: userRole))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoleConfig.getPrimaryColor(for: userRole).opacity(0.1))
                    .cornerRadius(AppCornerRadius.medium)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(AppCornerRadius.medium)

            Text("Your card information is encrypted and securely stored.")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Default Method Section

    private var defaultMethodSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Button(action: {
                setAsDefault.toggle()
            }) {
                HStack {
                    Image(systemName: setAsDefault ? "checkmark.square.fill" : "square")
                        .foregroundColor(setAsDefault ? RoleConfig.getPrimaryColor(for: userRole) : .gray)
                        .font(.system(size: 22))

                    Text("Set as Default Payment Method")
                        .font(AppTypography.body)
                        .foregroundColor(.primary)

                    Spacer()
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(AppCornerRadius.medium)
            }
            .buttonStyle(.plain)

            Text("The default method will be pre-selected during checkout.")
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Save Button

    private var saveButtonSection: some View {
        Button(action: saveMethod) {
            HStack {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Save Payment Method")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid && !isSaving ? RoleConfig.getPrimaryColor(for: userRole) : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(AppCornerRadius.medium)
        }
        .disabled(!isFormValid || isSaving)
    }

    // MARK: - Helpers

    private var cardBrandIcon: String {
        let cleanNumber = cardNumber.replacingOccurrences(of: " ", with: "")
        if cleanNumber.hasPrefix("4") {
            return "creditcard.fill" // Visa
        } else if cleanNumber.hasPrefix("5") || cleanNumber.hasPrefix("2") {
            return "creditcard.fill" // Mastercard
        } else {
            return "creditcard"
        }
    }

    private func isValidUgandanPhone(_ number: String) -> Bool {
        let cleaned = number.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
        // Ugandan phone numbers: 07X, 03X, +2567X, +2563X
        if cleaned.hasPrefix("+256") {
            return cleaned.count >= 12 && cleaned.count <= 13
        } else if cleaned.hasPrefix("0") {
            return cleaned.count >= 10 && cleaned.count <= 10
        }
        return false
    }

    private var isFormValid: Bool {
        switch selectedType {
        case .mtnMomo, .airtelMoney:
            let number = useProfileNumber ? (authService.currentUser?.phoneNumber ?? "") : mobileMoneyNumber
            return !number.isEmpty && (isValidUgandanPhone(number) || number.count >= 10)
        case .card:
            let cleanNumber = cardNumber.replacingOccurrences(of: " ", with: "")
            return !cardholderName.isEmpty &&
                   cleanNumber.count >= 13 &&
                   expiryDate.count == 5 &&
                   cvv.count >= 3
        case .cash:
            return true
        }
    }

    private func formatCardNumber(_ number: String) -> String {
        let cleaned = number.replacingOccurrences(of: " ", with: "").prefix(16)
        var result = ""
        for (index, char) in cleaned.enumerated() {
            if index > 0 && index % 4 == 0 {
                result += " "
            }
            result += String(char)
        }
        return result
    }

    private func formatExpiryDate(_ date: String) -> String {
        let cleaned = date.replacingOccurrences(of: "/", with: "").prefix(4)
        if cleaned.count > 2 {
            let month = cleaned.prefix(2)
            let year = cleaned.suffix(cleaned.count - 2)
            return "\(month)/\(year)"
        }
        return String(cleaned)
    }

    private func saveMethod() {
        isSaving = true

        var newMethod: SavedPaymentMethod

        switch selectedType {
        case .mtnMomo, .airtelMoney:
            let number = useProfileNumber ? (authService.currentUser?.phoneNumber ?? "") : mobileMoneyNumber
            newMethod = SavedPaymentMethod(
                id: UUID(),
                type: selectedType,
                isDefault: setAsDefault,
                displayName: "\(selectedType.rawValue) - \(number)",
                mobileMoneyNumber: number
            )

        case .card:
            let cleanNumber = cardNumber.replacingOccurrences(of: " ", with: "")
            let lastFour = String(cleanNumber.suffix(4))
            let brand = detectCardBrand(cleanNumber)
            let expiryParts = expiryDate.split(separator: "/")
            let month = Int(expiryParts.first ?? "") ?? 0
            let year = Int(expiryParts.last ?? "") ?? 0

            newMethod = SavedPaymentMethod(
                id: UUID(),
                type: .card,
                isDefault: setAsDefault,
                displayName: "\(brand) •••• \(lastFour)",
                lastFourDigits: lastFour,
                cardBrand: brand,
                expiryMonth: month,
                expiryYear: 2000 + year,
                cardholderName: cardholderName
            )

        case .cash:
            newMethod = SavedPaymentMethod(
                id: UUID(),
                type: .cash,
                isDefault: setAsDefault,
                displayName: "Cash"
            )
        }

        Task {
            do {
                try await preferencesService.savePaymentMethod(newMethod)

                await MainActor.run {
                    isSaving = false
                    HapticFeedback.success()
                    onSaved()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showError = true
                    HapticFeedback.error()
                }
            }
        }
    }

    private func detectCardBrand(_ number: String) -> String {
        if number.hasPrefix("4") {
            return "Visa"
        } else if number.hasPrefix("5") || number.hasPrefix("2") {
            return "Mastercard"
        } else if number.hasPrefix("37") || number.hasPrefix("34") {
            return "Amex"
        } else {
            return "Card"
        }
    }
}

// MARK: - Payment Type Selection Card

struct PaymentTypeCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? accentColor : .gray)
                    .frame(width: 50)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTypography.headline)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(accentColor)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 24))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(AppCornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(isSelected ? accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mobile Money Provider Button

struct MobileMoneyProviderButton: View {
    let title: String
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "phone.fill")
                    .foregroundColor(isSelected ? .white : color)

                Text(title)
                    .font(AppTypography.body)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? color : Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(AppCornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .stroke(color.opacity(0.5), lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationView {
        PaymentMethodsView()
            .environmentObject(MockAuthService())
    }
}
