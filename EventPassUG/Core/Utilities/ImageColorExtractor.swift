//
//  ImageColorExtractor.swift
//  EventPassUG
//
//  Utility for extracting dominant colors from images
//

import UIKit

struct ImageColorExtractor {

    struct ColorScheme {
        let primary: UIColor
        let secondary: UIColor
        let accent: UIColor
        let background: UIColor

        static var `default`: ColorScheme {
            ColorScheme(
                primary: UIColor.systemBlue,
                secondary: UIColor.systemIndigo,
                accent: UIColor.systemPurple,
                background: UIColor.systemGray6
            )
        }
    }

    static func extractColors(from imageName: String) -> ColorScheme {
        guard let image = UIImage(named: imageName) else {
            return .default
        }
        return extractColors(from: image)
    }

    static func extractColors(from image: UIImage) -> ColorScheme {
        guard image.cgImage != nil else {
            return .default
        }

        // Resize image for faster processing
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        image.draw(in: CGRect(origin: .zero, size: size))
        guard let resizedImage = UIGraphicsGetImageFromCurrentImageContext(),
              let resizedCGImage = resizedImage.cgImage else {
            UIGraphicsEndImageContext()
            return .default
        }
        UIGraphicsEndImageContext()

        // Extract pixels
        let width = resizedCGImage.width
        let height = resizedCGImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return .default
        }

        context.draw(resizedCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Count colors
        var colorCounts: [String: (color: UIColor, count: Int)] = [:]

        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * bytesPerPixel
                let r = CGFloat(pixelData[offset]) / 255.0
                let g = CGFloat(pixelData[offset + 1]) / 255.0
                let b = CGFloat(pixelData[offset + 2]) / 255.0
                let a = CGFloat(pixelData[offset + 3]) / 255.0

                // Skip very transparent or very light/dark pixels
                guard a > 0.5,
                      !(r > 0.9 && g > 0.9 && b > 0.9),
                      !(r < 0.1 && g < 0.1 && b < 0.1) else {
                    continue
                }

                // Quantize colors to reduce variations
                let quantizedR = round(r * 8) / 8
                let quantizedG = round(g * 8) / 8
                let quantizedB = round(b * 8) / 8

                let color = UIColor(red: quantizedR, green: quantizedG, blue: quantizedB, alpha: 1.0)
                let key = "\(quantizedR)-\(quantizedG)-\(quantizedB)"

                if let existing = colorCounts[key] {
                    colorCounts[key] = (color: existing.color, count: existing.count + 1)
                } else {
                    colorCounts[key] = (color: color, count: 1)
                }
            }
        }

        // Sort by count
        let sortedColors = colorCounts.values.sorted { $0.count > $1.count }

        guard !sortedColors.isEmpty else {
            return .default
        }

        // Extract dominant colors
        let primary = sortedColors.first?.color ?? UIColor.systemBlue

        // Find secondary (different hue from primary)
        var secondary = UIColor.systemIndigo
        for colorData in sortedColors.dropFirst() {
            if !areColorsSimilar(primary, colorData.color) {
                secondary = colorData.color
                break
            }
        }

        // Find accent (different from both)
        var accent = UIColor.systemPurple
        for colorData in sortedColors.dropFirst(2) {
            if !areColorsSimilar(primary, colorData.color) && !areColorsSimilar(secondary, colorData.color) {
                accent = colorData.color
                break
            }
        }

        // Create lighter background based on primary
        let background = primary.withAlphaComponent(0.1)

        return ColorScheme(
            primary: primary,
            secondary: secondary,
            accent: accent,
            background: background
        )
    }

    private static func areColorsSimilar(_ color1: UIColor, _ color2: UIColor) -> Bool {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        let threshold: CGFloat = 0.2
        return abs(r1 - r2) < threshold && abs(g1 - g2) < threshold && abs(b1 - b2) < threshold
    }
}

extension UIColor {
    func lighter(by percentage: CGFloat = 0.3) -> UIColor {
        return adjustBrightness(by: abs(percentage))
    }

    func darker(by percentage: CGFloat = 0.3) -> UIColor {
        return adjustBrightness(by: -abs(percentage))
    }

    private func adjustBrightness(by percentage: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0

        if getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            return UIColor(hue: h, saturation: s, brightness: min(max(b + percentage, 0), 1), alpha: a)
        }
        return self
    }
}
