import SwiftUI
import Yosemite

/// SwiftUI view for `ReviewDetailsViewController`
///
struct ReviewDetailView: View {
    let productReview: ProductReview
    let product: Product?
    let notification: Note?

    var body: some View {
        ReviewDetailWrapperView(productReview: productReview,
                                product: product,
                                notification: notification)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Localization.title)
    }
}

private extension ReviewDetailView {
    enum Localization {
        static let title = NSLocalizedString(
            "reviewDetailView.title",
            value: "Product Review",
            comment: "Title of the product review detail screen"
        )
    }
}

/// SwiftUI wrapper for `ReviewDetailsViewController`
///
private struct ReviewDetailWrapperView: UIViewControllerRepresentable {
    let productReview: ProductReview
    let product: Product?
    let notification: Note?

    func makeUIViewController(context: Self.Context) -> ReviewDetailsViewController {
        let viewController = ReviewDetailsViewController(productReview: productReview,
                                                         product: product,
                                                         notification: notification)
        return viewController
    }

    func updateUIViewController(_ uiViewController: ReviewDetailsViewController, context: Context) {
        // nothing to do here
    }
}
