//
//  IDCameraView.swift
//  EventPassUG
//
//  Camera view with frame overlay for capturing ID documents
//

import SwiftUI
import AVFoundation

struct IDCameraView: View {
    let documentName: String
    let onCapture: (UIImage) -> Void
    let onCancel: () -> Void

    @StateObject private var cameraManager = CameraManager()
    @State private var showFlash = false

    var body: some View {
        ZStack {
            // Camera Preview
            CameraPreview(session: cameraManager.session)
                .ignoresSafeArea()

            // Dark overlay with cutout for ID frame
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .overlay(
                    GeometryReader { geometry in
                        let frameWidth = geometry.size.width * 0.85
                        let frameHeight = frameWidth * 0.63 // ID card aspect ratio (85.6mm x 53.98mm)

                        VStack {
                            Spacer()

                            // Frame for centering ID
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: frameWidth, height: frameHeight)
                                .overlay(
                                    // Corner guides
                                    CornerGuides()
                                )
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.clear)
                                        .blendMode(.destinationOut)
                                )

                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }
                )
                .compositingGroup()

            // UI Controls
            VStack {
                // Top bar
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.leading, AppSpacing.md)

                    Spacer()

                    Button(action: {
                        cameraManager.toggleFlash()
                    }) {
                        Image(systemName: cameraManager.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(cameraManager.isFlashOn ? .yellow : .white)
                            .padding(12)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, AppSpacing.md)
                }
                .padding(.top, 50)

                Spacer()

                // Instructions
                VStack(spacing: AppSpacing.sm) {
                    Text("Center your \(documentName)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 2)

                    Text("Make sure all text is clear and readable")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black, radius: 2)
                }
                .padding(.bottom, AppSpacing.lg)

                // Capture button
                Button(action: capturePhoto) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)

                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 80, height: 80)
                    }
                }
                .padding(.bottom, 50)
            }

            // Flash effect
            if showFlash {
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .onAppear {
            cameraManager.checkPermissionAndSetup()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }

    private func capturePhoto() {
        // Flash effect
        withAnimation(.easeInOut(duration: 0.2)) {
            showFlash = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showFlash = false
            }
        }

        cameraManager.capturePhoto { image in
            if let image = image {
                HapticFeedback.success()
                onCapture(image)
            } else {
                HapticFeedback.error()
            }
        }
    }
}

// MARK: - Corner Guides

struct CornerGuides: View {
    var body: some View {
        GeometryReader { geometry in
            let cornerLength: CGFloat = 20
            let cornerWidth: CGFloat = 3

            // Top-left
            Path { path in
                path.move(to: CGPoint(x: 0, y: cornerLength))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: cornerLength, y: 0))
            }
            .stroke(Color.green, lineWidth: cornerWidth)
            .position(x: cornerLength/2, y: cornerLength/2)

            // Top-right
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: cornerLength, y: 0))
                path.addLine(to: CGPoint(x: cornerLength, y: cornerLength))
            }
            .stroke(Color.green, lineWidth: cornerWidth)
            .position(x: geometry.size.width - cornerLength/2, y: cornerLength/2)

            // Bottom-left
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: cornerLength))
                path.addLine(to: CGPoint(x: cornerLength, y: cornerLength))
            }
            .stroke(Color.green, lineWidth: cornerWidth)
            .position(x: cornerLength/2, y: geometry.size.height - cornerLength/2)

            // Bottom-right
            Path { path in
                path.move(to: CGPoint(x: 0, y: cornerLength))
                path.addLine(to: CGPoint(x: cornerLength, y: cornerLength))
                path.addLine(to: CGPoint(x: cornerLength, y: 0))
            }
            .stroke(Color.green, lineWidth: cornerWidth)
            .position(x: geometry.size.width - cornerLength/2, y: geometry.size.height - cornerLength/2)
        }
    }
}

// MARK: - Camera Manager

class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var isFlashOn = false

    private var photoOutput = AVCapturePhotoOutput()
    private var captureCompletion: ((UIImage?) -> Void)?

    func checkPermissionAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setupCamera()
                    }
                }
            }
        default:
            break
        }
    }

    private func setupCamera() {
        session.beginConfiguration()

        // Set high quality preset
        session.sessionPreset = .photo

        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            session.commitConfiguration()
            return
        }

        session.addInput(videoInput)

        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            if #available(iOS 16.0, *) {
                photoOutput.maxPhotoDimensions = CMVideoDimensions(width: 4032, height: 3024)
            } else {
                photoOutput.isHighResolutionCaptureEnabled = true
            }
        }

        session.commitConfiguration()

        // Start session on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    func toggleFlash() {
        isFlashOn.toggle()
    }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        self.captureCompletion = completion

        let settings = AVCapturePhotoSettings()
        settings.flashMode = isFlashOn ? .on : .off

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func stopSession() {
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.stopRunning()
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            captureCompletion?(nil)
            return
        }

        captureCompletion?(image)
        captureCompletion = nil
    }
}

// MARK: - Camera Preview

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        context.coordinator.previewLayer = previewLayer

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}
