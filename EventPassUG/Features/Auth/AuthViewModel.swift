//
//  AuthViewModel.swift
//  EventPassUG
//
//  Production-grade authentication state management
//  Handles login, register, OTP, and social authentication
//

import SwiftUI
import Combine

// MARK: - Auth Mode

enum AuthMode {
    case login
    case register
    case otp
}

// MARK: - Auth Method

enum AuthMethod {
    case email
    case phone
    case apple
    case google
    case facebook
}

// MARK: - Auth State

enum AuthState: Equatable {
    case idle
    case loading
    case success
    case error(String)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}

// MARK: - Auth ViewModel

@MainActor
class AuthViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var mode: AuthMode = .login
    @Published var state: AuthState = .idle

    // Login/Register fields
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""

    // OTP fields
    @Published var phoneNumber: String = ""
    @Published var otpCode: String = ""
    @Published var otpTimer: Int = 0
    @Published var canResendOTP: Bool = true

    // Validation
    @Published var emailError: String?
    @Published var passwordError: String?
    @Published var confirmPasswordError: String?
    @Published var fullNameError: String?
    @Published var phoneError: String?

    // Dependencies
    private let authService: any AuthRepositoryProtocol
    private var otpTimerCancellable: AnyCancellable?

    // MARK: - Initialization

    init(authService: any AuthRepositoryProtocol) {
        self.authService = authService
    }

    // MARK: - Mode Switching

    func switchMode(to newMode: AuthMode) {
        withAnimation(AppDesign.Animation.spring) {
            mode = newMode
            clearErrors()
            state = .idle
        }
    }

    // MARK: - Validation

    var isLoginValid: Bool {
        isValidEmail(email) && password.count >= 6
    }

    var isRegisterValid: Bool {
        !fullName.isEmpty &&
        isValidEmail(email) &&
        password.count >= 6 &&
        password == confirmPassword
    }

    var isOTPPhoneValid: Bool {
        isValidPhone(phoneNumber)
    }

    var isOTPCodeValid: Bool {
        otpCode.count == 6 && otpCode.allSatisfy { $0.isNumber }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPred.evaluate(with: email)
    }

    private func isValidPhone(_ phone: String) -> Bool {
        let cleaned = phone.filter { $0.isNumber || $0 == "+" }
        return cleaned.count >= 10 && cleaned.count <= 15
    }

    func validateFields() {
        emailError = email.isEmpty ? nil : (isValidEmail(email) ? nil : "Invalid email format")

        if mode == .register {
            fullNameError = fullName.isEmpty ? "Full name is required" : nil
            passwordError = password.isEmpty ? nil : (password.count >= 6 ? nil : "Password must be at least 6 characters")
            confirmPasswordError = confirmPassword.isEmpty ? nil : (password == confirmPassword ? nil : "Passwords do not match")
        } else {
            passwordError = password.isEmpty ? nil : (password.count >= 6 ? nil : "Password must be at least 6 characters")
        }

        if mode == .otp {
            phoneError = phoneNumber.isEmpty ? nil : (isValidPhone(phoneNumber) ? nil : "Invalid phone number")
        }
    }

    private func clearErrors() {
        emailError = nil
        passwordError = nil
        confirmPasswordError = nil
        fullNameError = nil
        phoneError = nil
    }

    // MARK: - Authentication Actions

    func signIn() async {
        guard isLoginValid else {
            validateFields()
            return
        }

        state = .loading
        HapticFeedback.light()

        do {
            _ = try await authService.signIn(
                email: email,
                password: password
            )

            state = .success
            HapticFeedback.success()
        } catch {
            state = .error(error.localizedDescription)
            HapticFeedback.error()
        }
    }

    func signUp() async {
        guard isRegisterValid else {
            validateFields()
            return
        }

        state = .loading
        HapticFeedback.light()

        do {
            let names = fullName.components(separatedBy: " ")
            let firstName = names.first ?? fullName
            let lastName = names.dropFirst().joined(separator: " ")

            _ = try await authService.signUp(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName.isEmpty ? firstName : lastName,
                role: .attendee
            )

            state = .success
            HapticFeedback.success()
        } catch {
            state = .error(error.localizedDescription)
            HapticFeedback.error()
        }
    }

    func sendOTP() async {
        guard isOTPPhoneValid else {
            validateFields()
            return
        }

        state = .loading
        HapticFeedback.light()

        do {
            _ = try await authService.signInWithPhone(
                phoneNumber: phoneNumber,
                firstName: "User",
                lastName: "Phone",
                role: .attendee
            )

            startOTPTimer()
            state = .idle
            HapticFeedback.success()
        } catch {
            state = .error(error.localizedDescription)
            HapticFeedback.error()
        }
    }

    func verifyOTP() async {
        guard isOTPCodeValid else {
            state = .error("Please enter a valid 6-digit code")
            return
        }

        state = .loading
        HapticFeedback.light()

        do {
            _ = try await authService.verifyPhoneCode(
                verificationId: "mock-verification-id",
                code: otpCode
            )

            state = .success
            HapticFeedback.success()
        } catch {
            state = .error(error.localizedDescription)
            HapticFeedback.error()
        }
    }

    func signInWithApple() async {
        state = .loading
        HapticFeedback.light()

        // Simulate Apple Sign In
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        do {
            // Parse full name or use defaults
            let nameParts = fullName.isEmpty ? ["User"] : fullName.components(separatedBy: " ")
            let firstName = nameParts.first ?? "User"
            let lastName = nameParts.dropFirst().joined(separator: " ").isEmpty ? "AppleID" : nameParts.dropFirst().joined(separator: " ")

            _ = try await authService.signInWithApple(
                firstName: firstName,
                lastName: lastName,
                role: .attendee // Social auth users default to attendee role
            )
            state = .success
            HapticFeedback.success()
        } catch {
            state = .error(error.localizedDescription)
            HapticFeedback.error()
        }
    }

    func signInWithGoogle() async {
        state = .loading
        HapticFeedback.light()

        // Simulate Google Sign In
        try? await Task.sleep(nanoseconds: 1_000_000_000)

        do {
            // Parse full name or use defaults
            let nameParts = fullName.isEmpty ? ["User"] : fullName.components(separatedBy: " ")
            let firstName = nameParts.first ?? "User"
            let lastName = nameParts.dropFirst().joined(separator: " ").isEmpty ? "Google" : nameParts.dropFirst().joined(separator: " ")

            _ = try await authService.signInWithGoogle(
                firstName: firstName,
                lastName: lastName,
                role: .attendee // Social auth users default to attendee role
            )
            state = .success
            HapticFeedback.success()
        } catch {
            state = .error(error.localizedDescription)
            HapticFeedback.error()
        }
    }

    // MARK: - OTP Timer

    private func startOTPTimer() {
        otpTimer = 60
        canResendOTP = false

        otpTimerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }

                if self.otpTimer > 0 {
                    self.otpTimer -= 1
                } else {
                    self.canResendOTP = true
                    self.otpTimerCancellable?.cancel()
                }
            }
    }

    // MARK: - Reset

    func reset() {
        fullName = ""
        email = ""
        password = ""
        confirmPassword = ""
        phoneNumber = ""
        otpCode = ""
        clearErrors()
        state = .idle
    }
}
