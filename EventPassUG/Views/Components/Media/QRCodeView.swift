//
//  QRCodeView.swift
//  EventPassUG
//
//  QR code display component
//

import SwiftUI

struct QRCodeView: View {
    let data: String
    let size: CGFloat
    let foregroundColor: Color
    let backgroundColor: Color

    init(
        data: String,
        size: CGFloat = 200,
        foregroundColor: Color = .black,
        backgroundColor: Color = .white
    ) {
        self.data = data
        self.size = size
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        Group {
            if let qrImage = generateQRCode() {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: size, height: size)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: size, height: size)
                    .overlay(
                        Text("QR Code Unavailable")
                            .font(.caption)
                            .foregroundColor(.gray)
                    )
            }
        }
        .accessibilityLabel("QR Code for ticket")
        .accessibilityHint("Show this code at the event entrance")
    }

    private func generateQRCode() -> UIImage? {
        QRCodeGenerator.generateStyled(
            from: data,
            size: CGSize(width: size, height: size),
            foregroundColor: UIColor(foregroundColor),
            backgroundColor: UIColor(backgroundColor)
        )
    }
}

#Preview {
    VStack(spacing: 30) {
        QRCodeView(data: "TICKET:12345-ABCDE")

        QRCodeView(
            data: "TICKET:67890-FGHIJ",
            size: 150,
            foregroundColor: RoleConfig.attendeePrimary,
            backgroundColor: .white
        )
    }
    .padding()
}
