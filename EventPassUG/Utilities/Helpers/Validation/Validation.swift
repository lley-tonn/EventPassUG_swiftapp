//
//  Validation.swift
//  EventPassUG
//
//  Email and form validation utilities
//

import Foundation

struct ValidationUtils {
    // MARK: - Email Validation

    static func isValidEmail(_ email: String) -> Bool {
        guard !email.isEmpty else { return false }

        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }

    static func emailValidationMessage(_ email: String) -> String? {
        guard !email.isEmpty else { return nil }

        if !email.contains("@") {
            return "Email must contain @"
        }

        if !isValidEmail(email) {
            return "Please enter a valid email address"
        }

        return nil
    }

    // MARK: - Password Validation

    static func isValidPassword(_ password: String) -> Bool {
        password.count >= 6
    }

    static func passwordValidationMessage(_ password: String) -> String? {
        guard !password.isEmpty else { return nil }

        if password.count < 6 {
            return "Password must be at least 6 characters"
        }

        return nil
    }

    // MARK: - Name Validation

    static func isValidName(_ name: String) -> Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
