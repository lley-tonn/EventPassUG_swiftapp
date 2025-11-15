//
//  ShareSheet.swift
//  EventPassUG
//
//  UIActivityViewController wrapper for SwiftUI
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let onComplete: ((Bool) -> Void)?

    init(items: [Any], onComplete: ((Bool) -> Void)? = nil) {
        self.items = items
        self.onComplete = onComplete
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            onComplete?(completed)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
