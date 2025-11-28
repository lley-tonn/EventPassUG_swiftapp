//
//  PosterView.swift
//  EventPassUG
//
//  Responsive event poster component with perfect aspect ratio
//  Production-ready with placeholder, error handling, and scaling
//

import SwiftUI

// MARK: - Poster View (Local Images)

struct PosterView: View {
    let image: UIImage?
    let aspectRatio: CGFloat
    let cornerRadius: CGFloat
    let showShadow: Bool

    // MARK: - Initializers

    init(
        image: UIImage?,
        aspectRatio: CGFloat = PosterConfiguration.defaultAspectRatio,
        cornerRadius: CGFloat = PosterConfiguration.cornerRadius,
        showShadow: Bool = true
    ) {
        self.image = image
        self.aspectRatio = aspectRatio
        self.cornerRadius = cornerRadius
        self.showShadow = showShadow
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            Group {
                if let image = image {
                    // Display actual image
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.width / aspectRatio
                        )
                        .clipped()
                } else {
                    // Placeholder
                    placeholderView
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.width / aspectRatio
                        )
                }
            }
            .cornerRadius(cornerRadius)
            .shadow(
                color: showShadow ? Color.black.opacity(PosterConfiguration.shadowOpacity) : .clear,
                radius: showShadow ? PosterConfiguration.shadowRadius : 0,
                y: showShadow ? 4 : 0
            )
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
    }

    // MARK: - Placeholder

    private var placeholderView: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(UIColor.systemGray5),
                        Color(UIColor.systemGray6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)

                    Text("No Poster")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            )
    }
}

// MARK: - Async Poster View (Remote URLs)

struct AsyncPosterView: View {
    let url: String?
    let aspectRatio: CGFloat
    let cornerRadius: CGFloat
    let showShadow: Bool

    @State private var isLoading = true

    // MARK: - Initializers

    init(
        url: String?,
        aspectRatio: CGFloat = PosterConfiguration.defaultAspectRatio,
        cornerRadius: CGFloat = PosterConfiguration.cornerRadius,
        showShadow: Bool = true
    ) {
        self.url = url
        self.aspectRatio = aspectRatio
        self.cornerRadius = cornerRadius
        self.showShadow = showShadow
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            Group {
                if let urlString = url,
                   let imageURL = URL(string: urlString) {
                    // Load image asynchronously
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            loadingView
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(
                                    width: geometry.size.width,
                                    height: geometry.size.width / aspectRatio
                                )
                                .clipped()
                                .onAppear { isLoading = false }
                        case .failure:
                            errorView
                        @unknown default:
                            placeholderView
                        }
                    }
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.width / aspectRatio
                    )
                } else {
                    // No URL provided
                    placeholderView
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.width / aspectRatio
                        )
                }
            }
            .cornerRadius(cornerRadius)
            .shadow(
                color: showShadow ? Color.black.opacity(PosterConfiguration.shadowOpacity) : .clear,
                radius: showShadow ? PosterConfiguration.shadowRadius : 0,
                y: showShadow ? 4 : 0
            )
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        Rectangle()
            .fill(Color(UIColor.systemGray6))
            .overlay(
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.gray)

                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            )
    }

    // MARK: - Error View

    private var errorView: some View {
        Rectangle()
            .fill(Color.red.opacity(0.1))
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.red)

                    Text("Failed to Load")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            )
    }

    // MARK: - Placeholder View

    private var placeholderView: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(UIColor.systemGray5),
                        Color(UIColor.systemGray6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)

                    Text("No Poster")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            )
    }
}

// MARK: - Poster Card (With Event Details)

struct PosterCard: View {
    let posterURL: String?
    let title: String
    let date: String
    let venue: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Poster image
            AsyncPosterView(url: posterURL)

            // Event details
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                    Text(venue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding()
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(PosterConfiguration.cornerRadius)
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 8,
            y: 4
        )
    }
}

// MARK: - Preview

#Preview("Local Image") {
    ScrollView {
        VStack(spacing: 20) {
            Text("Local Poster")
                .font(.title)

            // With image
            PosterView(image: UIImage(systemName: "photo"))
                .frame(height: 300)
                .padding()

            // Without image (placeholder)
            PosterView(image: nil)
                .frame(height: 300)
                .padding()
        }
    }
}

#Preview("Remote URL") {
    ScrollView {
        VStack(spacing: 20) {
            Text("Remote Poster")
                .font(.title)

            // With URL
            AsyncPosterView(url: "https://example.com/poster.jpg")
                .frame(height: 300)
                .padding()

            // Without URL (placeholder)
            AsyncPosterView(url: nil)
                .frame(height: 300)
                .padding()
        }
    }
}

#Preview("Poster Card") {
    ScrollView {
        VStack(spacing: 20) {
            PosterCard(
                posterURL: nil,
                title: "Summer Music Festival 2025",
                date: "June 15, 2025",
                venue: "Kampala City Square"
            )
            .padding()

            PosterCard(
                posterURL: "https://example.com/poster.jpg",
                title: "Tech Conference Uganda",
                date: "July 20, 2025",
                venue: "Sheraton Hotel"
            )
            .padding()
        }
    }
    .background(Color(UIColor.systemGroupedBackground))
}
