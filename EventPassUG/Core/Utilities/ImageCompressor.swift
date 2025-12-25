//
//  ImageCompressor.swift
//  EventPassUG
//
//  Handles image compression and optimization for uploads
//

import UIKit
import SwiftUI

struct ImageCompressor {

    // MARK: - Compression Result

    struct CompressionResult {
        let data: Data
        let originalSize: Int
        let compressedSize: Int
        let compressionRatio: Double

        var savingsPercentage: Double {
            let savings = Double(originalSize - compressedSize) / Double(originalSize)
            return savings * 100
        }

        var readableOriginalSize: String {
            ByteCountFormatter.string(fromByteCount: Int64(originalSize), countStyle: .file)
        }

        var readableCompressedSize: String {
            ByteCountFormatter.string(fromByteCount: Int64(compressedSize), countStyle: .file)
        }
    }

    // MARK: - Main Compression

    /// Compresses image to JPEG format with specified quality
    /// - Parameters:
    ///   - image: The UIImage to compress
    ///   - quality: Compression quality (0.0 - 1.0), default 0.85
    ///   - maxDimension: Maximum width/height, resizes if larger
    /// - Returns: CompressionResult with compressed data and statistics
    static func compressPoster(
        _ image: UIImage,
        quality: CGFloat = PosterConfiguration.compressionQuality,
        maxDimension: CGFloat? = nil
    ) -> Result<CompressionResult, ImageValidationError> {

        // Resize if needed
        let processedImage: UIImage
        if let maxDim = maxDimension {
            processedImage = resize(image, maxDimension: maxDim)
        } else {
            processedImage = image
        }

        // Get original size estimate (uncompressed)
        guard let originalData = processedImage.pngData() else {
            return .failure(.compressionFailed)
        }
        let originalSize = originalData.count

        // Compress to JPEG
        guard let compressedData = processedImage.jpegData(compressionQuality: quality) else {
            return .failure(.compressionFailed)
        }

        // Validate file size
        switch ImageValidator.validateFileSize(compressedData) {
        case .success:
            break
        case .failure(let error):
            return .failure(error)
        }

        let compressedSize = compressedData.count
        let ratio = Double(compressedSize) / Double(originalSize)

        let result = CompressionResult(
            data: compressedData,
            originalSize: originalSize,
            compressedSize: compressedSize,
            compressionRatio: ratio
        )

        return .success(result)
    }

    // MARK: - Adaptive Compression

    /// Compresses image adaptively to meet size requirements
    /// Automatically adjusts quality if file is too large
    static func compressAdaptively(
        _ image: UIImage,
        targetSize: Int = PosterConfiguration.maxFileSize
    ) -> Result<CompressionResult, ImageValidationError> {

        var quality: CGFloat = PosterConfiguration.compressionQuality
        var attempt = 0
        let maxAttempts = 5

        while attempt < maxAttempts {
            let result = compressPoster(image, quality: quality)

            switch result {
            case .success(let compressionResult):
                if compressionResult.compressedSize <= targetSize {
                    return .success(compressionResult)
                }
                // File too large, reduce quality
                quality -= 0.1

            case .failure(let error):
                return .failure(error)
            }

            attempt += 1
        }

        return .failure(.fileSizeTooLarge(
            actual: targetSize + 1,
            maximum: targetSize
        ))
    }

    // MARK: - Image Resizing

    /// Resizes image while maintaining aspect ratio
    /// - Parameters:
    ///   - image: Original image
    ///   - maxDimension: Maximum width or height
    /// - Returns: Resized UIImage
    private static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let aspectRatio = size.width / size.height

        let newSize: CGSize
        if size.width > size.height {
            // Landscape or square
            newSize = CGSize(
                width: min(maxDimension, size.width),
                height: min(maxDimension, size.width) / aspectRatio
            )
        } else {
            // Portrait
            newSize = CGSize(
                width: min(maxDimension, size.height) * aspectRatio,
                height: min(maxDimension, size.height)
            )
        }

        // Only resize if image is larger than max
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - Quick Compression

    /// Quick compression with default settings
    static func compress(_ image: UIImage) -> Data? {
        return image.jpegData(compressionQuality: PosterConfiguration.compressionQuality)
    }

    // MARK: - Compression Stats

    /// Gets compression statistics without saving the data
    static func getCompressionStats(_ image: UIImage) -> String {
        guard let original = image.pngData(),
              let compressed = image.jpegData(compressionQuality: PosterConfiguration.compressionQuality) else {
            return "Unable to calculate"
        }

        let savings = ((Double(original.count - compressed.count) / Double(original.count)) * 100)

        return String(format: "%.1f%% smaller", savings)
    }
}
