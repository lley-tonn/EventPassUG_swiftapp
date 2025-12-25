//
//  PosterConfiguration.swift
//  EventPassUG
//
//  Centralized poster sizing and quality configuration
//

import Foundation
import UIKit

struct PosterConfiguration {

    // MARK: - Aspect Ratios

    /// Standard event poster aspect ratio (4:5)
    /// This matches most professional event posters and movie posters
    static let standardAspectRatio: CGFloat = 4.0 / 5.0

    /// Alternative aspect ratio (1:1.4) - slightly taller
    static let alternativeAspectRatio: CGFloat = 1.0 / 1.4

    /// Default aspect ratio used throughout the app
    static let defaultAspectRatio: CGFloat = standardAspectRatio

    // MARK: - Minimum Image Requirements

    /// Minimum width for high-quality posters
    /// This ensures posters look sharp on all devices
    static let minimumWidth: CGFloat = 900

    /// Minimum height for high-quality posters
    static let minimumHeight: CGFloat = minimumWidth / defaultAspectRatio // 1125px

    /// Recommended width for optimal quality
    static let recommendedWidth: CGFloat = 1200

    /// Recommended height for optimal quality
    static let recommendedHeight: CGFloat = recommendedWidth / defaultAspectRatio // 1500px

    // MARK: - Compression Settings

    /// JPEG compression quality (0.0 - 1.0)
    /// 0.85 provides excellent quality with good file size reduction
    static let compressionQuality: CGFloat = 0.85

    /// Maximum file size in bytes (5 MB)
    static let maxFileSize: Int = 5 * 1024 * 1024

    // MARK: - UI Display Settings

    /// Corner radius for poster images
    static let cornerRadius: CGFloat = 12

    /// Shadow radius for posters
    static let shadowRadius: CGFloat = 8

    /// Shadow opacity
    static let shadowOpacity: Double = 0.2

    // MARK: - Validation Messages

    static let lowResolutionMessage = """
        Image resolution is too low.
        Minimum required: \(Int(minimumWidth))×\(Int(minimumHeight)) pixels.
        Please select a higher quality image.
        """

    static let fileSizeTooLargeMessage = """
        Image file size is too large.
        Maximum allowed: \(maxFileSize / 1024 / 1024) MB.
        Please select a smaller image or try a different format.
        """
}
