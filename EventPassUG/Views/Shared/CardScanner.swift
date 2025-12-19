//
//  CardScanner.swift
//  EventPassUG
//
//  Production-ready credit/debit card scanner using AVFoundation + Vision OCR
//  Performs all OCR on-device without storing card images
//

import SwiftUI
import AVFoundation
import Vision
import UIKit

// MARK: - Delegate Protocol

/// Protocol for receiving scanned card data
protocol CardScannerDelegate: AnyObject {
    /// Called when card details are successfully scanned and validated
    /// - Parameters:
    ///   - cardNumber: Validated card number (formatted with spaces)
    ///   - expiry: Expiry date in MM/YY format (optional)
    ///   - name: Cardholder name if detected (optional)
    func cardScannerDidScan(cardNumber: String, expiry: String?, name: String?)

    /// Called when user cancels scanning
    func cardScannerDidCancel()
}

// MARK: - Card Scanner View Controller

/// UIKit view controller that handles camera preview and Vision OCR for card scanning
final class CardScannerViewController: UIViewController {

    // MARK: - Properties

    weak var delegate: CardScannerDelegate?

    // AVFoundation components
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(label: "com.eventpassug.cardscanner.videoQueue", qos: .userInitiated)

    // Vision request for text recognition
    private lazy var textRecognitionRequest: VNRecognizeTextRequest = {
        let request = VNRecognizeTextRequest { [weak self] request, error in
            self?.processTextRecognitionResults(request: request, error: error)
        }
        // Use fast recognition for real-time scanning
        request.recognitionLevel = .fast
        request.usesLanguageCorrection = false
        request.recognitionLanguages = ["en-US"]
        // Minimum text height to reduce noise
        request.minimumTextHeight = 0.02
        return request
    }()

    // UI Components
    private var cardFrameView: UIView!
    private var instructionLabel: UILabel!
    private var cancelButton: UIButton!
    private var flashlightButton: UIButton!
    private var debugLabel: UILabel!

    // Scanning state
    private var isProcessing = false
    private var detectedCardNumber: String?
    private var detectedExpiry: String?
    private var detectedName: String?
    private var consecutiveDetections = 0
    private let requiredConsecutiveDetections = 2  // Lower threshold for faster detection
    private var lastProcessingTime: Date = .distantPast
    private let processingInterval: TimeInterval = 0.2  // Process every 200ms for responsiveness

    // Detection frame (card-sized rectangle)
    private var cardDetectionRect: CGRect = .zero

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCamera()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startScanning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        updateCardFramePosition()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .black

        // Card frame overlay
        cardFrameView = UIView()
        cardFrameView.backgroundColor = .clear
        cardFrameView.layer.borderColor = UIColor.white.cgColor
        cardFrameView.layer.borderWidth = 3
        cardFrameView.layer.cornerRadius = 12
        cardFrameView.translatesAutoresizingMaskIntoConstraints = false

        // Instruction label
        instructionLabel = UILabel()
        instructionLabel.text = "Position your card within the frame"
        instructionLabel.textColor = .white
        instructionLabel.font = .systemFont(ofSize: 16, weight: .medium)
        instructionLabel.textAlignment = .center
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false

        // Cancel button
        cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        // Flashlight button
        flashlightButton = UIButton(type: .system)
        flashlightButton.setImage(UIImage(systemName: "flashlight.off.fill"), for: .normal)
        flashlightButton.tintColor = .white
        flashlightButton.addTarget(self, action: #selector(toggleFlashlight), for: .touchUpInside)
        flashlightButton.translatesAutoresizingMaskIntoConstraints = false

        // Debug label to show scanning status
        debugLabel = UILabel()
        debugLabel.text = "Scanning..."
        debugLabel.textColor = .white.withAlphaComponent(0.8)
        debugLabel.font = .systemFont(ofSize: 12, weight: .regular)
        debugLabel.textAlignment = .center
        debugLabel.numberOfLines = 3
        debugLabel.translatesAutoresizingMaskIntoConstraints = false

        // Add semi-transparent overlay with cutout
        let overlayView = createOverlayView()
        view.addSubview(overlayView)
        view.addSubview(cardFrameView)
        view.addSubview(instructionLabel)
        view.addSubview(debugLabel)
        view.addSubview(cancelButton)
        view.addSubview(flashlightButton)

        // Layout constraints
        NSLayoutConstraint.activate([
            // Card frame (standard credit card aspect ratio: 85.6mm x 53.98mm ≈ 1.586:1)
            cardFrameView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardFrameView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            cardFrameView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            cardFrameView.heightAnchor.constraint(equalTo: cardFrameView.widthAnchor, multiplier: 0.63),

            // Instruction label
            instructionLabel.topAnchor.constraint(equalTo: cardFrameView.bottomAnchor, constant: 24),
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),

            // Debug label
            debugLabel.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 12),
            debugLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            debugLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            debugLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Cancel button
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            // Flashlight button
            flashlightButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            flashlightButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            flashlightButton.widthAnchor.constraint(equalToConstant: 44),
            flashlightButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    private func createOverlayView() -> UIView {
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.isUserInteractionEnabled = false

        // The cutout will be updated in viewDidLayoutSubviews
        return overlay
    }

    private func updateCardFramePosition() {
        // Update detection rect based on card frame position
        let frameInView = cardFrameView.frame

        // Convert to normalized coordinates for Vision (0,0 is bottom-left in Vision)
        let viewSize = view.bounds.size
        cardDetectionRect = CGRect(
            x: frameInView.minX / viewSize.width,
            y: 1 - (frameInView.maxY / viewSize.height),
            width: frameInView.width / viewSize.width,
            height: frameInView.height / viewSize.height
        )
    }

    // MARK: - Camera Setup

    private func setupCamera() {
        // Check camera permission
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.configureCamera()
                    } else {
                        self?.showPermissionDeniedAlert()
                    }
                }
            }
        default:
            showPermissionDeniedAlert()
        }
    }

    private func configureCamera() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .hd1920x1080

        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            captureSession.commitConfiguration()
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }

        // Configure video output
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        // Set video orientation
        if let connection = videoOutput.connection(with: .video) {
            connection.videoOrientation = .portrait
        }

        captureSession.commitConfiguration()

        // Setup preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)

        // Auto-focus configuration
        try? videoDevice.lockForConfiguration()
        if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
            videoDevice.focusMode = .continuousAutoFocus
        }
        if videoDevice.isAutoFocusRangeRestrictionSupported {
            videoDevice.autoFocusRangeRestriction = .near
        }
        videoDevice.unlockForConfiguration()
    }

    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Camera Access Required",
            message: "Please enable camera access in Settings to scan your card.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.delegate?.cardScannerDidCancel()
        })
        present(alert, animated: true)
    }

    // MARK: - Scanning Control

    private func startScanning() {
        videoQueue.async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    private func stopScanning() {
        videoQueue.async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        stopScanning()
        delegate?.cardScannerDidCancel()
    }

    @objc private func toggleFlashlight() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }

        do {
            try device.lockForConfiguration()

            if device.torchMode == .on {
                device.torchMode = .off
                flashlightButton.setImage(UIImage(systemName: "flashlight.off.fill"), for: .normal)
            } else {
                try device.setTorchModeOn(level: 0.5)
                flashlightButton.setImage(UIImage(systemName: "flashlight.on.fill"), for: .normal)
            }

            device.unlockForConfiguration()
        } catch {
            print("Flashlight error: \(error)")
        }
    }

    // MARK: - Text Recognition Processing

    private func processTextRecognitionResults(request: VNRequest, error: Error?) {
        guard error == nil,
              let observations = request.results as? [VNRecognizedTextObservation] else {
            return
        }

        // Extract all recognized text
        var recognizedStrings: [String] = []
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            recognizedStrings.append(topCandidate.string)
        }

        // Parse card details from recognized text
        parseCardDetails(from: recognizedStrings)
    }

    private func parseCardDetails(from strings: [String]) {
        var foundCardNumber: String?
        var foundExpiry: String?
        var foundName: String?

        // Update debug label with detected text count
        DispatchQueue.main.async { [weak self] in
            self?.debugLabel.text = "Found \(strings.count) text regions"
        }

        for text in strings {
            // Try to extract card number (13-19 digits)
            if foundCardNumber == nil {
                foundCardNumber = extractCardNumber(from: text)
            }

            // Try to extract expiry date
            if foundExpiry == nil {
                foundExpiry = extractExpiryDate(from: text)
            }

            // Try to extract cardholder name
            if foundName == nil {
                foundName = extractCardholderName(from: text)
            }
        }

        // Update debug info
        DispatchQueue.main.async { [weak self] in
            var debugInfo = "Scanning... (\(strings.count) regions)"
            if let num = foundCardNumber {
                debugInfo = "Number: \(num.prefix(4))... "
                if CardValidator.isValidLuhn(num) {
                    debugInfo += "✓ Valid"
                } else {
                    debugInfo += "✗ Invalid"
                }
            }
            if let exp = foundExpiry {
                debugInfo += "\nExpiry: \(exp)"
            }
            self?.debugLabel.text = debugInfo
        }

        // Validate and update state if card number found
        if let cardNumber = foundCardNumber {
            // Validate using Luhn algorithm
            if CardValidator.isValidLuhn(cardNumber) {
                // Check if this matches previous detection
                if cardNumber == detectedCardNumber {
                    consecutiveDetections += 1
                } else {
                    detectedCardNumber = cardNumber
                    consecutiveDetections = 1
                }

                // Update expiry and name if found
                if let expiry = foundExpiry {
                    detectedExpiry = expiry
                }
                if let name = foundName {
                    detectedName = name
                }

                // Update UI feedback
                DispatchQueue.main.async { [weak self] in
                    self?.updateInstructionLabel(cardNumber: cardNumber)
                }

                // If we have consistent detections, complete scanning
                if consecutiveDetections >= requiredConsecutiveDetections {
                    completeScan()
                }
            }
        }
    }

    private func updateInstructionLabel(cardNumber: String) {
        let maskedNumber = CardValidator.formatCardNumber(cardNumber)
        instructionLabel.text = "Detected: \(maskedNumber)\nHold steady..."
        cardFrameView.layer.borderColor = UIColor.green.cgColor
    }

    private func completeScan() {
        guard !isProcessing,
              let cardNumber = detectedCardNumber else { return }

        isProcessing = true
        stopScanning()

        // Format card number with spaces
        let formattedNumber = CardValidator.formatCardNumber(cardNumber)

        // Provide haptic feedback
        DispatchQueue.main.async { [weak self] in
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            self?.delegate?.cardScannerDidScan(
                cardNumber: formattedNumber,
                expiry: self?.detectedExpiry,
                name: self?.detectedName
            )
        }
    }

    // MARK: - Text Extraction Helpers

    /// Extracts card number from text (13-19 digits)
    private func extractCardNumber(from text: String) -> String? {
        // Remove all non-digits
        let digitsOnly = text.filter { $0.isNumber }

        // Valid card numbers are 13-19 digits
        if digitsOnly.count >= 13 && digitsOnly.count <= 19 {
            return digitsOnly
        }

        // Try to find card number pattern in text (with spaces or dashes)
        let pattern = "\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range, in: text) {
            let matched = String(text[range])
            let digits = matched.filter { $0.isNumber }
            if digits.count >= 13 && digits.count <= 19 {
                return digits
            }
        }

        return nil
    }

    /// Extracts expiry date (MM/YY or MM/YYYY)
    private func extractExpiryDate(from text: String) -> String? {
        // Pattern: MM/YY or MM/YYYY
        let patterns = [
            "\\b(0[1-9]|1[0-2])[/\\-](\\d{2})\\b",      // MM/YY
            "\\b(0[1-9]|1[0-2])[/\\-](20\\d{2})\\b",    // MM/YYYY
            "\\b(0[1-9]|1[0-2])(\\d{2})\\b"             // MMYY (no separator)
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {
                let matched = String(text[range])

                // Format as MM/YY
                let digitsOnly = matched.filter { $0.isNumber }
                if digitsOnly.count == 4 {
                    let month = String(digitsOnly.prefix(2))
                    let year = String(digitsOnly.suffix(2))

                    // Validate month
                    if let monthInt = Int(month), monthInt >= 1 && monthInt <= 12 {
                        // Validate year (should be current year or future)
                        if let yearInt = Int(year) {
                            let currentYear = Calendar.current.component(.year, from: Date()) % 100
                            if yearInt >= currentYear {
                                return "\(month)/\(year)"
                            }
                        }
                    }
                } else if digitsOnly.count == 6 {
                    let month = String(digitsOnly.prefix(2))
                    let year = String(digitsOnly.suffix(2))
                    return "\(month)/\(year)"
                }
            }
        }

        return nil
    }

    /// Extracts cardholder name (uppercase letters, possibly with spaces)
    private func extractCardholderName(from text: String) -> String? {
        // Cardholder names are typically all caps
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if text is all uppercase and contains only letters and spaces
        let uppercaseLettersAndSpaces = CharacterSet.uppercaseLetters.union(.whitespaces)
        if trimmed.unicodeScalars.allSatisfy({ uppercaseLettersAndSpaces.contains($0) }) {
            // Must have at least two parts (first and last name)
            let parts = trimmed.split(separator: " ")
            if parts.count >= 2 && trimmed.count >= 5 && trimmed.count <= 26 {
                // Exclude common non-name text
                let excludeWords = ["VISA", "MASTERCARD", "CREDIT", "DEBIT", "CARD", "VALID", "THRU", "EXPIRES", "END"]
                if !excludeWords.contains(where: { trimmed.contains($0) }) {
                    return trimmed
                }
            }
        }

        return nil
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CardScannerViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Skip if already processing a valid scan
        guard !isProcessing else { return }

        // Throttle processing to avoid overload
        let now = Date()
        guard now.timeIntervalSince(lastProcessingTime) >= processingInterval else { return }
        lastProcessingTime = now

        // Get pixel buffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Create request handler - use .up for portrait orientation
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])

        // Don't restrict region of interest - scan entire frame for better detection
        // The card frame is just a visual guide for the user
        textRecognitionRequest.regionOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)

        // Perform text recognition
        do {
            try requestHandler.perform([textRecognitionRequest])
        } catch {
            print("Vision error: \(error)")
        }
    }
}

// MARK: - Card Validator (Luhn Algorithm)

enum CardValidator {
    /// Validates card number using Luhn algorithm
    static func isValidLuhn(_ cardNumber: String) -> Bool {
        let digits = cardNumber.compactMap { Int(String($0)) }
        guard digits.count >= 13 && digits.count <= 19 else { return false }

        var sum = 0
        let reversedDigits = digits.reversed().enumerated()

        for (index, digit) in reversedDigits {
            if index % 2 == 1 {
                let doubled = digit * 2
                sum += doubled > 9 ? doubled - 9 : doubled
            } else {
                sum += digit
            }
        }

        return sum % 10 == 0
    }

    /// Formats card number with spaces (#### #### #### ####)
    static func formatCardNumber(_ number: String) -> String {
        let digits = number.filter { $0.isNumber }
        var formatted = ""

        for (index, char) in digits.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted += String(char)
        }

        return formatted
    }

    /// Detects card brand from number
    static func detectCardBrand(_ number: String) -> String {
        let digits = number.filter { $0.isNumber }

        if digits.hasPrefix("4") {
            return "Visa"
        } else if digits.hasPrefix("5") || digits.hasPrefix("2") {
            return "Mastercard"
        } else if digits.hasPrefix("34") || digits.hasPrefix("37") {
            return "Amex"
        } else if digits.hasPrefix("6011") || digits.hasPrefix("65") {
            return "Discover"
        } else {
            return "Card"
        }
    }
}

// MARK: - SwiftUI Wrapper

/// SwiftUI wrapper for CardScannerViewController
struct CardScannerSwiftUIView: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss

    /// Callback when card is successfully scanned
    var onScanned: (String, String?, String?) -> Void

    /// Callback when user cancels
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> CardScannerViewController {
        let viewController = CardScannerViewController()
        viewController.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: CardScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CardScannerDelegate {
        var parent: CardScannerSwiftUIView

        init(_ parent: CardScannerSwiftUIView) {
            self.parent = parent
        }

        func cardScannerDidScan(cardNumber: String, expiry: String?, name: String?) {
            parent.onScanned(cardNumber, expiry, name)
            parent.dismiss()
        }

        func cardScannerDidCancel() {
            parent.onCancel()
            parent.dismiss()
        }
    }
}

// MARK: - Usage Instructions

/*
 HOW TO USE THE CARD SCANNER IN YOUR SWIFTUI PAYMENT SCREEN:

 1. Add a state variable to control the scanner presentation:
    @State private var showCardScanner = false

 2. Add the scanner sheet modifier to your view:
    .sheet(isPresented: $showCardScanner) {
        CardScannerSwiftUIView(
            onScanned: { cardNumber, expiry, name in
                // Handle scanned data
                self.cardNumber = cardNumber
                if let exp = expiry {
                    self.expiryDate = exp
                }
                if let cardName = name {
                    self.cardholderName = cardName
                }
            },
            onCancel: {
                // Handle cancellation
            }
        )
        .ignoresSafeArea()
    }

 3. Add a button to trigger the scanner:
    Button(action: {
        showCardScanner = true
    }) {
        HStack {
            Image(systemName: "camera.viewfinder")
            Text("Scan Card")
        }
    }

 IMPORTANT NOTES:
 - Requires camera permission in Info.plist (NSCameraUsageDescription)
 - All OCR is performed on-device using Vision framework
 - No card images are stored or transmitted
 - Card number is validated using Luhn algorithm before returning
 - Minimum iOS 16 required for optimal Vision performance
 - Works in portrait orientation only
 */
