//
//  QRCodeGenerator.swift
//  EventPassUG
//
//  QR code generation using CoreImage
//

import UIKit
import CoreImage.CIFilterBuiltins

struct QRCodeGenerator {
    /// Generates a QR code image from string data
    /// - Parameters:
    ///   - string: The data to encode in the QR code
    ///   - size: The size of the output image (default: 200x200)
    /// - Returns: UIImage containing the QR code, or nil if generation fails
    static func generate(from string: String, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        // Convert string to data
        guard let data = string.data(using: .utf8) else {
            return nil
        }

        filter.message = data
        filter.correctionLevel = "M" // Medium error correction

        // Get the output image
        guard let ciImage = filter.outputImage else {
            return nil
        }

        // Scale the image to desired size
        let scaleX = size.width / ciImage.extent.width
        let scaleY = size.height / ciImage.extent.height
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        // Convert to CGImage then UIImage
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    /// Generates a styled QR code with custom colors
    /// - Parameters:
    ///   - string: The data to encode
    ///   - size: The size of the output image
    ///   - foregroundColor: The color of the QR code dots
    ///   - backgroundColor: The background color
    /// - Returns: UIImage containing the styled QR code, or nil if generation fails
    static func generateStyled(
        from string: String,
        size: CGSize = CGSize(width: 200, height: 200),
        foregroundColor: UIColor = .black,
        backgroundColor: UIColor = .white
    ) -> UIImage? {
        guard let baseImage = generate(from: string, size: size) else {
            return nil
        }

        // Create a new image context
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }

        // Fill background
        context.setFillColor(backgroundColor.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        // Draw QR code with foreground color
        context.setBlendMode(.normal)
        baseImage.draw(in: CGRect(origin: .zero, size: size), blendMode: .normal, alpha: 1.0)

        // Apply color using multiply blend mode
        context.setBlendMode(.multiply)
        context.setFillColor(foregroundColor.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
