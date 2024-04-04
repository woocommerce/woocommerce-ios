import SwiftUI

/// A simple SwiftUI wrapper for any view controller
struct ViewControllerContainer: UIViewControllerRepresentable {
    let content: UIViewController

    init(_ content: UIViewController) {
        self.content = content
    }

    func makeUIViewController(context: Context) -> UIViewController {
        return content
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // no-op
    }
}
