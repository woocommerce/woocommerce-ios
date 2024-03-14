import SwiftUI

/// SwiftUI view for the review list screen.
///
struct ReviewsView: View {
    let siteID: Int64

    var body: some View {
        ReviewsWrapperView(siteID: siteID)
            .navigationTitle(Localization.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
    }
}

private extension ReviewsView {
    enum Localization {
        static let navigationTitle = NSLocalizedString(
            "reviewsView.navigationTitle",
            value: "Reviews",
            comment: "Navigation title for the review list screen"
        )
    }
}

/// SwiftUI wrapper for `ReviewsViewController`
///
private struct ReviewsWrapperView: UIViewControllerRepresentable {
    let siteID: Int64

    func makeUIViewController(context: Self.Context) -> ReviewsViewController {
        let viewController = ReviewsViewController(siteID: siteID)
        return viewController
    }

    func updateUIViewController(_ uiViewController: ReviewsViewController, context: Context) {
        // nothing to do here
    }
}
