//
//  ImageValidator.swift
//  EventPassUG
//
//  Validates image quality and resolution before upload
//

import UIKit
import SwiftUI

enum ImageValidationError: LocalizedError {
    case resolutionTooLow(actual: CGSize, required: CGSize)
    case fileSizeTooLarge(actual: Int, maximum: Int)
    case invalidFormat
    case compressionFailed

    var errorDescription: String? {
        switch self {
        case .resolutionTooLow(let actual, let required):
            return """
            Image resolution is too low.
            Current: \(Int(actual.width))×\(Int(actual.height)) pixels
            Required: \(Int(required.width))×\(Int(required.height)) pixels
            Please select a higher quality image.
            """

        case .fileSizeTooLarge(let actual, let maximum):
            let actualMB = actual / 1024 / 1024
            let maxMB = maximum / 1024 / 1024
            return """
            Image file size is too large.
            Current: \(actualMB) MB
            Maximum: \(maxMB) MB
            Please select a smaller image.
            """

        case .invalidFormat:
            return "Invalid image format. Please select a JPEG or PNG image."

        case .compressionFailed:
            return "Failed to compress image. Please try a different image."
        }
    }
}

struct ImageValidator {

    // MARK: - Validation Result

    struct ValidationResult {
        let isValid: Bool
        let image: UIImage
        let error: ImageValidationError?

        var actualSize: CGSize {
            image.size
        }

        var actualWidth: CGFloat {
            image.size.width
        }

        var actualHeight: CGFloat {
            image.size.height
        }
    }

    // MARK: - Main Validation

    /// Validates an image for poster upload
    /// - Parameters:
    ///   - image: The UIImage to validate
    ///   - minimumWidth: Minimum required width (default: from config)
    ///   - minimumHeight: Minimum required height (default: from config)
    /// - Returns: ValidationResult with isValid flag and error if any
    static func validatePoster(
        _ image: UIImage,
        minimumWidth: CGFloat = PosterConfiguration.minimumWidth,
        minimumHeight: CGFloat = PosterConfiguration.minimumHeight
    ) -> ValidationResult {

        // Get actual image size
        let imageSize = image.size

        // Check resolution
        if imageSize.width < minimumWidth || imageSize.height < minimumHeight {
            let requiredSize = CGSize(width: minimumWidth, height: minimumHeight)
            let error = ImageValidationError.resolutionTooLow(
                actual: imageSize,
                required: requiredSize
            )
            return ValidationResult(isValid: false, image: image, error: error)
        }

        // All validations passed
        return ValidationResult(isValid: true, image: image, error: nil)
    }

    // MARK: - Resolution Checks

    /// Checks if image meets minimum resolution requirements
    static func meetsMinimumResolution(_ image: UIImage) -> Bool {
        let size = image.size
        return size.width >= PosterConfiguration.minimumWidth &&
               size.height >= PosterConfiguration.minimumHeight
    }

    /// Checks if image meets recommended resolution
    static func meetsRecommendedResolution(_ image: UIImage) -> Bool {
        let size = image.size
        return size.width >= PosterConfiguration.recommendedWidth &&
               size.height >= PosterConfiguration.recommendedHeight
    }

    /// Gets a quality rating for the image
    static func getQualityRating(_ image: UIImage) -> String {
        let size = image.size

        if size.width >= PosterConfiguration.recommendedWidth {
            return "Excellent Quality ✨"
        } else if size.width >= PosterConfiguration.minimumWidth * 1.2 {
            return "Good Quality ✅"
        } else if size.width >= PosterConfiguration.minimumWidth {
            return "Acceptable Quality ⚠️"
        } else {
            return "Low Quality ❌"
        }
    }

    // MARK: - File Size Validation

    /// Validates compressed file size
    static func validateFileSize(_ data: Data) -> Result<Data, ImageValidationError> {
        if data.count > PosterConfiguration.maxFileSize {
            return .failure(.fileSizeTooLarge(
                actual: data.count,
                maximum: PosterConfiguration.maxFileSize
            ))
        }
        return .success(data)
    }

    // MARK: - Aspect Ratio Validation

    /// Checks if image has the correct aspect ratio (with tolerance)
    static func hasCorrectAspectRatio(
        _ image: UIImage,
        tolerance: CGFloat = 0.1
    ) -> Bool {
        let actualRatio = image.size.width / image.size.height
        let targetRatio = PosterConfiguration.defaultAspectRatio
        let difference = abs(actualRatio - targetRatio)
        return difference <= tolerance
    }

    /// Gets aspect ratio of image
    static func getAspectRatio(_ image: UIImage) -> CGFloat {
        return image.size.width / image.size.height
    }
}
