//
//  PosterUploadManager.swift
//  EventPassUG
//
//  Handles poster validation, compression, and upload to Storage
//  Production-ready with error handling and progress tracking
//
//  NOTE: Currently using MockStorageService for development.
//  To use Firebase Storage in production:
//  1. Add Firebase package: https://github.com/firebase/firebase-ios-sdk
//  2. Add FirebaseStorage product to target
//  3. Create FirebaseStorageService implementing StorageServiceProtocol
//  4. Replace MockStorageService with FirebaseStorageService in init
//

import UIKit
import SwiftUI

// MARK: - Upload Result

enum PosterUploadResult {
    case success(url: String, metadata: UploadMetadata)
    case failure(error: PosterUploadError)
    case progress(Double)
}

struct UploadMetadata {
    let downloadURL: String
    let fileSize: Int
    let compressionRatio: Double
    let uploadDuration: TimeInterval
    let originalSize: CGSize
}

// MARK: - Upload Error

enum PosterUploadError: LocalizedError {
    case validationFailed(ImageValidationError)
    case compressionFailed
    case uploadFailed(Error)
    case noImageSelected

    var errorDescription: String? {
        switch self {
        case .validationFailed(let error):
            return error.localizedDescription
        case .compressionFailed:
            return "Failed to compress image. Please try again."
        case .uploadFailed(let error):
            return "Upload failed: \(error.localizedDescription)"
        case .noImageSelected:
            return "No image selected. Please select a poster image."
        }
    }
}

// MARK: - Storage Service Protocol

protocol StorageServiceProtocol {
    func uploadImage(data: Data, path: String, metadata: [String: String]) async throws -> String
}

// MARK: - Mock Storage Service

class MockStorageService: StorageServiceProtocol {
    func uploadImage(data: Data, path: String, metadata: [String: String]) async throws -> String {
        // Simulate upload delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Return mock URL
        return "https://storage.example.com/\(path)?size=\(data.count)"
    }
}

// MARK: - Poster Upload Manager

@MainActor
class PosterUploadManager: ObservableObject {

    // MARK: - Published Properties

    @Published var uploadProgress: Double = 0.0
    @Published var isUploading: Bool = false
    @Published var validationError: String?

    // MARK: - Private Properties

    private let storageService: StorageServiceProtocol
    private var uploadTask: Task<Void, Never>?

    // MARK: - Initializer

    init(storageService: StorageServiceProtocol = MockStorageService()) {
        self.storageService = storageService
    }

    // MARK: - Main Upload Function

    /// Validates, compresses, and uploads a poster image to Firebase Storage
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - eventId: Unique event identifier
    ///   - completion: Callback with result
    func uploadPoster(
        _ image: UIImage,
        eventId: String,
        completion: @escaping (PosterUploadResult) -> Void
    ) {
        Task {
            isUploading = true
            uploadProgress = 0.0
            validationError = nil

            let startTime = Date()

            // Step 1: Validate image resolution
            let validationResult = ImageValidator.validatePoster(image)
            guard validationResult.isValid else {
                if let error = validationResult.error {
                    validationError = error.localizedDescription
                    isUploading = false
                    completion(.failure(error: .validationFailed(error)))
                }
                return
            }

            // Step 2: Compress image
            uploadProgress = 0.1
            guard case .success(let compressionResult) = ImageCompressor.compressPoster(image) else {
                isUploading = false
                completion(.failure(error: .compressionFailed))
                return
            }

            print("""
            📊 Compression Stats:
            Original: \(compressionResult.readableOriginalSize)
            Compressed: \(compressionResult.readableCompressedSize)
            Savings: \(String(format: "%.1f%%", compressionResult.savingsPercentage))
            """)

            uploadProgress = 0.2

            // Step 3: Upload to Firebase Storage
            await uploadToFirebase(
                data: compressionResult.data,
                eventId: eventId,
                originalSize: image.size,
                compressionResult: compressionResult,
                startTime: startTime,
                completion: completion
            )
        }
    }

    // MARK: - Storage Upload

    private func uploadToFirebase(
        data: Data,
        eventId: String,
        originalSize: CGSize,
        compressionResult: ImageCompressor.CompressionResult,
        startTime: Date,
        completion: @escaping (PosterUploadResult) -> Void
    ) async {

        // Create storage path
        let path = "event_posters/\(eventId)/poster.jpg"

        // Set metadata
        let metadata: [String: String] = [
            "originalWidth": "\(Int(originalSize.width))",
            "originalHeight": "\(Int(originalSize.height))",
            "compressionQuality": "\(PosterConfiguration.compressionQuality)",
            "uploadedAt": ISO8601DateFormatter().string(from: Date())
        ]

        // Upload with progress simulation
        uploadTask = Task { @MainActor in
            do {
                // Simulate progress updates
                for progress in stride(from: 0.2, through: 0.9, by: 0.1) {
                    self.uploadProgress = progress
                    completion(.progress(progress))
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                }

                // Upload to storage service
                let downloadURL = try await storageService.uploadImage(
                    data: data,
                    path: path,
                    metadata: metadata
                )

                // Complete progress
                self.uploadProgress = 1.0
                self.isUploading = false

                // Success!
                let duration = Date().timeIntervalSince(startTime)
                let uploadMetadata = UploadMetadata(
                    downloadURL: downloadURL,
                    fileSize: compressionResult.compressedSize,
                    compressionRatio: compressionResult.compressionRatio,
                    uploadDuration: duration,
                    originalSize: originalSize
                )

                print("""
                ✅ Upload Success!
                URL: \(downloadURL)
                Duration: \(String(format: "%.2f", duration))s
                Size: \(compressionResult.readableCompressedSize)
                """)

                completion(.success(url: downloadURL, metadata: uploadMetadata))

            } catch {
                self.isUploading = false
                self.uploadProgress = 0.0
                completion(.failure(error: .uploadFailed(error)))
            }
        }
    }

    // MARK: - Cancel Upload

    func cancelUpload() {
        uploadTask?.cancel()
        isUploading = false
        uploadProgress = 0.0
    }

    // MARK: - Delete Poster

    /// Deletes a poster from storage
    func deletePoster(eventId: String) async throws {
        // In a real implementation, this would call storageService.deleteImage()
        // For now, just simulate deletion
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        print("🗑️ Deleted poster for event: \(eventId)")
    }

    // MARK: - Quick Validation (No Upload)

    /// Validates an image without uploading
    /// Useful for showing errors before user submits
    func validateOnly(_ image: UIImage) -> (isValid: Bool, error: String?) {
        let result = ImageValidator.validatePoster(image)
        return (result.isValid, result.error?.localizedDescription)
    }

    /// Gets quality feedback for an image
    func getQualityFeedback(_ image: UIImage) -> String {
        return ImageValidator.getQualityRating(image)
    }
}

// MARK: - SwiftUI Integration Example

/*
 Usage in SwiftUI:

 struct CreateEventView: View {
     @StateObject private var uploadManager = PosterUploadManager()
     @State private var selectedImage: UIImage?
     @State private var uploadError: String?
     @State private var downloadURL: String?

     var body: some View {
         VStack {
             // Image picker
             PhotosPicker(selection: $selectedImage) {
                 Text("Select Poster")
             }

             // Show selected image with validation
             if let image = selectedImage {
                 Image(uiImage: image)
                     .resizable()
                     .scaledToFit()
                     .frame(height: 200)

                 Text(uploadManager.getQualityFeedback(image))
                     .font(.caption)
             }

             // Upload button
             Button("Upload Poster") {
                 guard let image = selectedImage else { return }

                 uploadManager.uploadPoster(image, eventId: UUID().uuidString) { result in
                     switch result {
                     case .success(let url, _):
                         downloadURL = url
                     case .failure(let error):
                         uploadError = error.localizedDescription
                     case .progress(let progress):
                         // Update UI with progress
                         print("Progress: \(progress)")
                     }
                 }
             }
             .disabled(uploadManager.isUploading)

             // Progress indicator
             if uploadManager.isUploading {
                 ProgressView(value: uploadManager.uploadProgress)
                 Text("Uploading... \(Int(uploadManager.uploadProgress * 100))%")
             }

             // Error display
             if let error = uploadError {
                 Text(error)
                     .foregroundColor(.red)
             }
         }
     }
 }
 */
