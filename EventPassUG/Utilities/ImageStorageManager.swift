//
//  ImageStorageManager.swift
//  EventPassUG
//
//  Manages saving and loading event poster images
//

import UIKit
import SwiftUI

class ImageStorageManager {
    static let shared = ImageStorageManager()

    private init() {}

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // Save UIImage to documents directory
    func saveImage(_ image: UIImage, withName name: String) -> Bool {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return false
        }

        let fileURL = documentsDirectory.appendingPathComponent(name)

        do {
            try data.write(to: fileURL)
            return true
        } catch {
            print("Error saving image: \(error)")
            return false
        }
    }

    // Load UIImage from documents directory
    func loadImage(withName name: String) -> UIImage? {
        let fileURL = documentsDirectory.appendingPathComponent(name)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        return UIImage(contentsOfFile: fileURL.path)
    }

    // Delete image from documents directory
    func deleteImage(withName name: String) {
        let fileURL = documentsDirectory.appendingPathComponent(name)

        try? FileManager.default.removeItem(at: fileURL)
    }

    // Check if image exists in documents directory
    func imageExists(withName name: String) -> Bool {
        let fileURL = documentsDirectory.appendingPathComponent(name)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }
}

// Helper view for loading event posters with proper fallback
struct EventPosterImage: View {
    let posterURL: String?
    var height: CGFloat = 250
    var cornerRadius: CGFloat = 0

    var body: some View {
        Group {
            if let posterURL = posterURL,
               let uiImage = ImageStorageManager.shared.loadImage(withName: posterURL) {
                // Successfully loaded from documents
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fill)
            } else if let posterURL = posterURL,
                      UIImage(named: posterURL) != nil {
                // Try loading from assets
                Image(posterURL)
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fill)
            } else {
                // Show placeholder
                Rectangle()
                    .fill(Color(UIColor.systemGray5))
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .cornerRadius(cornerRadius)
        .clipped()
    }
}

// Extension to SwiftUI Image to load from storage or assets
extension Image {
    init(eventPoster name: String) {
        // Try to load from documents directory first
        if let uiImage = ImageStorageManager.shared.loadImage(withName: name) {
            print("✅ Loaded poster from documents: \(name)")
            self.init(uiImage: uiImage)
        } else if UIImage(named: name) != nil {
            // Try asset catalog
            print("⚠️ Loaded poster from assets: \(name)")
            self.init(name)
        } else {
            // Fallback to system icon
            print("❌ Poster not found, using placeholder: \(name)")
            self.init(systemName: "photo")
        }
    }
}
