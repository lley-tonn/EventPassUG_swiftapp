//
//  QRScannerView.swift
//  EventPassUG
//
//  QR code scanner using AVFoundation for ticket validation
//

import SwiftUI
import AVFoundation

struct QRScannerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var services: ServiceContainer

    @State private var scannedCode: String?
    @State private var scanResult: ScanResult?
    @State private var showingResult = false
    @State private var isScanning = true

    enum ScanResult {
        case success(Ticket)
        case error(String)
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Camera preview
                QRCodeScannerRepresentable(scannedCode: $scannedCode, isScanning: $isScanning)
                    .edgesIgnoringSafeArea(.all)

                // Overlay UI
                VStack {
                    Spacer()

                    // Scanning frame
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 280, height: 280)
                        .overlay(
                            VStack {
                                ForEach(0..<4) { _ in
                                    Rectangle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(height: 2)
                                        .padding(.vertical, 20)
                                }
                            }
                        )

                    Spacer()

                    // Instructions
                    VStack(spacing: AppSpacing.sm) {
                        Text("Scan QR Code")
                            .font(AppTypography.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Position the QR code within the frame")
                            .font(AppTypography.callout)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, AppSpacing.xxl)
                }

                // Result overlay
                if showingResult, let result = scanResult {
                    Color.black.opacity(0.9)
                        .edgesIgnoringSafeArea(.all)

                    ResultView(result: result) {
                        showingResult = false
                        scanResult = nil
                        scannedCode = nil
                        isScanning = true
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .principal) {
                    Text("Scan Ticket")
                        .font(AppTypography.headline)
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .onChange(of: scannedCode) { newValue in
            guard let code = newValue, isScanning else { return }
            isScanning = false
            validateTicket(code: code)
        }
    }

    private func validateTicket(code: String) {
        HapticFeedback.light()

        Task {
            do {
                let ticket = try await services.ticketService.scanTicket(qrCode: code)
                await MainActor.run {
                    scanResult = .success(ticket)
                    showingResult = true
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    scanResult = .error(error.localizedDescription)
                    showingResult = true
                    HapticFeedback.error()
                }
            }
        }
    }
}

struct ResultView: View {
    let result: QRScannerView.ScanResult
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            switch result {
            case .success(let ticket):
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)

                Text("Valid Ticket!")
                    .font(AppTypography.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                VStack(spacing: AppSpacing.sm) {
                    Text(ticket.eventTitle)
                        .font(AppTypography.title3)
                        .foregroundColor(.white)

                    Text(ticket.ticketType.name)
                        .font(AppTypography.callout)
                        .foregroundColor(.white.opacity(0.8))

                    if let seat = ticket.seatNumber {
                        Text("Seat: \(seat)")
                            .font(AppTypography.callout)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(AppCornerRadius.medium)

            case .error(let message):
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.red)

                Text("Invalid Ticket")
                    .font(AppTypography.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(message)
                    .font(AppTypography.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding()
            }

            Button(action: onDismiss) {
                Text("Scan Another")
                    .font(AppTypography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: 200)
                    .padding()
                    .background(RoleConfig.organizerPrimary)
                    .cornerRadius(AppCornerRadius.medium)
            }
        }
        .padding(AppSpacing.xl)
    }
}

// MARK: - Camera Representable

struct QRCodeScannerRepresentable: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    @Binding var isScanning: Bool

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {
        if isScanning {
            uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(scannedCode: $scannedCode)
    }

    class Coordinator: NSObject, QRScannerDelegate {
        @Binding var scannedCode: String?

        init(scannedCode: Binding<String?>) {
            _scannedCode = scannedCode
        }

        func didScanCode(_ code: String) {
            scannedCode = code
        }
    }
}

// MARK: - Scanner View Controller

protocol QRScannerDelegate: AnyObject {
    func didScanCode(_ code: String)
}

class QRScannerViewController: UIViewController {
    weak var delegate: QRScannerDelegate?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScanning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession?.canAddInput(videoInput) ?? false) {
            captureSession?.addInput(videoInput)
        } else {
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession?.canAddOutput(metadataOutput) ?? false) {
            captureSession?.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.frame = view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer!)
    }

    func startScanning() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    func stopScanning() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
}

extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            delegate?.didScanCode(stringValue)
        }
    }
}

#Preview {
    QRScannerView()
        .environmentObject(ServiceContainer(
            authService: MockAuthRepository(),
            eventService: MockEventRepository(),
            ticketService: MockTicketRepository(),
            paymentService: MockPaymentRepository()
        ))
}
