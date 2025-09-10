import Foundation
import SwiftUI
import UIKit

final class ShareImageService {
    static func snapshot<V: View>(of view: V, scale: CGFloat = 2) -> UIImage? {
        if #available(iOS 16.0, *) {
            let renderer = ImageRenderer(content: view)
            renderer.scale = scale
            return renderer.uiImage
        } else {
            let controller = UIHostingController(rootView: view)
            let size = controller.view.intrinsicContentSize
            controller.view.bounds = CGRect(origin: .zero, size: size)
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { ctx in
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

