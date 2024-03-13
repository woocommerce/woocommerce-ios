import SwiftUI
import Yosemite

/// SwiftUI conformance for `ReviewDetailsViewController`
///
struct ReviewDetailView: UIViewControllerRepresentable {
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

    func makeCoordinator() -> Self.Coordinator { Coordinator() }
}
