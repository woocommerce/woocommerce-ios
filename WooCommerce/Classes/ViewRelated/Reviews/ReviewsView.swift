import SwiftUI

/// SwiftUI conformance for `ReviewsViewController`
///
struct ReviewsView: UIViewControllerRepresentable {
    let siteID: Int64

    typealias UIViewControllerType = ReviewsViewController

    func makeUIViewController(context: Self.Context) -> ReviewsViewController {
        let viewController = ReviewsViewController(siteID: siteID)
        return viewController
    }

    func updateUIViewController(_ uiViewController: ReviewsViewController, context: Context) {
        // nothing to do here
    }
}
