import SwiftUI

/// SwiftUI conformance for `ReviewsViewController`
///
struct ReviewsView: UIViewControllerRepresentable {
    let siteID: Int64

    typealias UIViewControllerType = ReviewsViewController

    func makeUIViewController(context: Context) -> ReviewsViewController {
        ReviewsViewController(siteID: siteID)
    }

    func updateUIViewController(_ uiViewController: ReviewsViewController, context: Context) {
        // nothing to do here
    }
}
