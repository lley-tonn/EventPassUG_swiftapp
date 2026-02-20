//
//  PairingQRGenerator.swift
//  EventPassUG
//
//  Utility for generating QR codes for scanner device pairing
//

import Foundation
import UIKit
import CoreImage.CIFilterBuiltins
import SwiftUI

// MARK: - QR Generator

enum PairingQRGenerator {

    /// Generates a QR code image from pairing session data
    /// - Parameters:
    ///   - pairingSession: The pairing session to encode
    ///   - size: The desired size of the QR code image
    /// - Returns: A UIImage of the QR code, or nil if generation fails
    static func generateQRCode(for pairingSession: PairingSession, size: CGSize = CGSize(width: 250, height: 250)) -> UIImage? {
        generateQRCode(from: pairingSession.qrCodeData, size: size)
    }

    /// Generates a QR code image from a string
    /// - Parameters:
    ///   - string: The string to encode in the QR code
    ///   - size: The desired size of the QR code image
    /// - Returns: A UIImage of the QR code, or nil if generation fails
    static func generateQRCode(from string: String, size: CGSize = CGSize(width: 250, height: 250)) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }

        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // High error correction

        guard let outputImage = filter.outputImage else { return nil }

        // Scale the image to the desired size
        let scaleX = size.width / outputImage.extent.size.width
        let scaleY = size.height / outputImage.extent.size.height
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }

    /// Generates a styled QR code with branding colors
    static func generateStyledQRCode(
        for pairingSession: PairingSession,
        size: CGSize = CGSize(width: 250, height: 250),
        foregroundColor: UIColor = .black,
        backgroundColor: UIColor = .white
    ) -> UIImage? {
        guard let data = pairingSession.qrCodeData.data(using: .utf8) else { return nil }

        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else { return nil }

        // Apply colors
        let colorFilter = CIFilter.falseColor()
        colorFilter.inputImage = outputImage
        colorFilter.color0 = CIColor(color: backgroundColor)
        colorFilter.color1 = CIColor(color: foregroundColor)

        guard let coloredImage = colorFilter.outputImage else { return nil }

        // Scale the image
        let scaleX = size.width / coloredImage.extent.size.width
        let scaleY = size.height / coloredImage.extent.size.height
        let scaledImage = coloredImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }
}

// MARK: - SwiftUI QR Code View

/// A SwiftUI view that displays a QR code for pairing
struct PairingQRCodeView: View {
    let pairingSession: PairingSession
    let size: CGFloat

    @State private var qrImage: UIImage?

    init(pairingSession: PairingSession, size: CGFloat = 200) {
        self.pairingSession = pairingSession
        self.size = size
    }

    var body: some View {
        Group {
            if let qrImage = qrImage {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .background(Color.white)
                    .cornerRadius(AppCornerRadius.md)
            } else {
                ProgressView()
                    .frame(width: size, height: size)
            }
        }
        .onAppear {
            generateQRCode()
        }
        .onChange(of: pairingSession.id) { _ in
            generateQRCode()
        }
    }

    private func generateQRCode() {
        qrImage = PairingQRGenerator.generateQRCode(
            for: pairingSession,
            size: CGSize(width: size * 2, height: size * 2) // Higher resolution
        )
    }
}

// MARK: - Preview

#Preview("QR Code") {
    VStack(spacing: 20) {
        let mockSession = PairingSession(
            eventId: UUID(),
            organizerId: UUID()
        )

        PairingQRCodeView(pairingSession: mockSession, size: 200)

        Text("Pairing Code: \(mockSession.pairingCode)")
            .font(.headline)
            .monospacedDigit()

        Text("Expires in \(mockSession.formattedTimeRemaining)")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
    .padding()
}
