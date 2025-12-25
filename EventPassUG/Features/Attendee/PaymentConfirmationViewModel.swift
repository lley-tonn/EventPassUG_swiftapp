//
//  PaymentConfirmationViewModel.swift
//  EventPassUG
//
//  ViewModel for safe payment confirmation flow
//  Ensures users explicitly confirm mobile number before payment
//

import Foundation
import Combine

// MARK: - Payment Confirmation State

enum PaymentConfirmationState: Equatable {
    case idle
    case awaitingConfirmation
    case editingNumber
    case validating
    case processing
    case completed(paymentId: UUID)
    case failed(error: String)
    case cancelled
}

// MARK: - Payment Confirmation Result

enum PaymentConfirmationResult {
    case confirmed(mobileNumber: String, saveAsDefault: Bool)
    case cancelled
    case editNumber
}

// MARK: - Mobile Number Validation Error

enum MobileNumberValidationError: LocalizedError {
    case empty
    case invalidFormat
    case tooShort
    case tooLong
    case invalidProvider(PaymentMethod)

    var errorDescription: String? {
        switch self {
        case .empty:
            return "Please enter a mobile number"
        case .invalidFormat:
            return "Please enter a valid Ugandan mobile number"
        case .tooShort:
            return "Mobile number is too short"
        case .tooLong:
            return "Mobile number is too long"
        case .invalidProvider(let method):
            return "This number doesn't match \(method.rawValue)"
        }
    }
}

// MARK: - ViewModel

@MainActor
class PaymentConfirmationViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var state: PaymentConfirmationState = .idle
    @Published var mobileNumber: String = ""
    @Published var originalMobileNumber: String = ""
    @Published var isEditingNumber: Bool = false
    @Published var saveAsDefault: Bool = false
    @Published var validationError: MobileNumberValidationError?
    @Published var paymentMethod: PaymentMethod = .mtnMomo

    // MARK: - Computed Properties

    var isProcessing: Bool {
        state == .processing || state == .validating
    }

    var canProceed: Bool {
        !isProcessing && validationError == nil && !mobileNumber.isEmpty
    }

    var maskedNumber: String {
        maskMobileNumber(mobileNumber)
    }

    var displayNumber: String {
        isEditingNumber ? mobileNumber : maskedNumber
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Public Methods

    /// Initialize confirmation with saved mobile number
    func initializeWith(
        mobileNumber: String?,
        paymentMethod: PaymentMethod,
        userPhoneNumber: String?
    ) {
        self.paymentMethod = paymentMethod

        // Determine which number to use
        if let savedNumber = mobileNumber, !savedNumber.isEmpty {
            self.mobileNumber = savedNumber
            self.originalMobileNumber = savedNumber
        } else if let userPhone = userPhoneNumber {
            self.mobileNumber = userPhone
            self.originalMobileNumber = userPhone
        } else {
            self.mobileNumber = ""
            self.originalMobileNumber = ""
            self.isEditingNumber = true
        }

        self.state = .awaitingConfirmation
        validateNumber()
    }

    /// User confirmed payment with current number
    func confirmPayment() {
        guard canProceed else { return }

        state = .validating
        validationError = nil

        // Validate one more time before proceeding
        if let error = validateMobileNumber(mobileNumber, for: paymentMethod) {
            validationError = error
            state = .failed(error: error.localizedDescription)
            return
        }

        // Proceed to processing
        state = .processing
    }

    /// User wants to edit the mobile number
    func startEditingNumber() {
        isEditingNumber = true
        state = .editingNumber
        validationError = nil
    }

    /// User confirmed the edited number
    func confirmEditedNumber() {
        guard !mobileNumber.isEmpty else {
            validationError = .empty
            return
        }

        if let error = validateMobileNumber(mobileNumber, for: paymentMethod) {
            validationError = error
            return
        }

        isEditingNumber = false
        state = .awaitingConfirmation
        validationError = nil
    }

    /// Cancel editing and revert to original number
    func cancelEditingNumber() {
        mobileNumber = originalMobileNumber
        isEditingNumber = false
        state = .awaitingConfirmation
        validationError = nil
    }

    /// User cancelled the entire payment
    func cancelPayment() {
        state = .cancelled
    }

    /// Mark payment as completed
    func markCompleted(paymentId: UUID) {
        state = .completed(paymentId: paymentId)
    }

    /// Mark payment as failed
    func markFailed(error: String) {
        state = .failed(error: error)
    }

    /// Reset to initial state
    func reset() {
        state = .idle
        mobileNumber = ""
        originalMobileNumber = ""
        isEditingNumber = false
        saveAsDefault = false
        validationError = nil
    }

    // MARK: - Validation

    /// Real-time validation as user types
    func validateNumber() {
        guard !mobileNumber.isEmpty else {
            validationError = nil
            return
        }

        validationError = validateMobileNumber(mobileNumber, for: paymentMethod)
    }

    /// Comprehensive mobile number validation
    private func validateMobileNumber(
        _ number: String,
        for method: PaymentMethod
    ) -> MobileNumberValidationError? {
        let cleaned = number.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")

        // Empty check
        if cleaned.isEmpty {
            return .empty
        }

        // Length checks
        if cleaned.hasPrefix("+256") {
            if cleaned.count < 12 {
                return .tooShort
            }
            if cleaned.count > 13 {
                return .tooLong
            }
        } else if cleaned.hasPrefix("0") {
            if cleaned.count < 10 {
                return .tooShort
            }
            if cleaned.count > 10 {
                return .tooLong
            }
        } else {
            return .invalidFormat
        }

        // Provider-specific validation
        switch method {
        case .mtnMomo:
            // MTN: 077, 078, +25677, +25678
            if cleaned.hasPrefix("+256") {
                let prefix = cleaned.prefix(7)
                if prefix != "+25677" && prefix != "+25678" {
                    return .invalidProvider(method)
                }
            } else {
                let prefix = cleaned.prefix(3)
                if prefix != "077" && prefix != "078" {
                    return .invalidProvider(method)
                }
            }

        case .airtelMoney:
            // Airtel: 070, 075, +25670, +25675
            if cleaned.hasPrefix("+256") {
                let prefix = cleaned.prefix(7)
                if prefix != "+25670" && prefix != "+25675" {
                    return .invalidProvider(method)
                }
            } else {
                let prefix = cleaned.prefix(3)
                if prefix != "070" && prefix != "075" {
                    return .invalidProvider(method)
                }
            }

        case .card:
            // Cards don't use mobile numbers
            break
        }

        return nil
    }

    // MARK: - Formatting & Masking

    /// Mask mobile number for display (e.g., +256 77* *** 123)
    func maskMobileNumber(_ number: String) -> String {
        let cleaned = number.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")

        if cleaned.hasPrefix("+256") {
            // +256 77* *** 123
            let countryCode = "+256"
            let visible = String(cleaned.suffix(3))
            if cleaned.count >= 12 {
                let firstDigit = cleaned.dropFirst(4).prefix(1)
                return "\(countryCode) \(firstDigit)** *** \(visible)"
            }
            return cleaned
        } else if cleaned.hasPrefix("0") {
            // 077* *** 123
            if cleaned.count >= 10 {
                let prefix = cleaned.prefix(3)
                let suffix = String(cleaned.suffix(3))
                return "\(prefix)* *** \(suffix)"
            }
            return cleaned
        }

        return number
    }

    /// Format mobile number with proper spacing
    func formatMobileNumber(_ number: String) -> String {
        let cleaned = number.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")

        if cleaned.hasPrefix("+256") {
            // +256 77 1234567
            if cleaned.count > 4 {
                let countryCode = "+256"
                let rest = cleaned.dropFirst(4)
                if rest.count > 2 {
                    let part1 = rest.prefix(2)
                    let part2 = rest.dropFirst(2)
                    return "\(countryCode) \(part1) \(part2)"
                }
                return "\(countryCode) \(rest)"
            }
            return cleaned
        } else if cleaned.hasPrefix("0") {
            // 077 1234567
            if cleaned.count > 3 {
                let prefix = cleaned.prefix(3)
                let rest = cleaned.dropFirst(3)
                return "\(prefix) \(rest)"
            }
            return cleaned
        }

        return number
    }
}

// MARK: - Helper Extensions

extension PaymentMethod {
    /// Provider-specific help text for mobile numbers
    var numberFormatHelp: String {
        switch self {
        case .mtnMomo:
            return "MTN MoMo: 077* or 078*"
        case .airtelMoney:
            return "Airtel Money: 070* or 075*"
        case .card:
            return "Card payment"
        }
    }

    /// Whether this payment method requires mobile number
    var requiresMobileNumber: Bool {
        switch self {
        case .mtnMomo, .airtelMoney:
            return true
        case .card:
            return false
        }
    }
}
