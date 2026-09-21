import SwiftUI
import SafariServices

/// SwiftUI interface for UIKit SFSafariViewController
/// Provides a visible interface for web browsing, and Safari features
///
public struct SafariView: UIViewControllerRepresentable {

    private let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    public func updateUIViewController(_ uiViewController: SFSafariViewController,
                                       context: UIViewControllerRepresentableContext<SafariView>) {
    }
}
