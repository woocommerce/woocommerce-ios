import SwiftUI
import Yosemite

/// SwiftUI conformance for `ReviewDetailsViewController`
///
struct ReviewDetailView: UIViewControllerRepresentable {
    let productReview: ProductReview
    let product: Product?
    let notification: Note?

    typealias UIViewControllerType = ReviewDetailsViewController

    class Coordinator {
        var parentObserver: NSKeyValueObservation?
    }

    /// This is a UIKit solution for fixing Navigation Title and Bar Button Items ignored in NavigationView.
    /// This solution doesn't require making internal changes to the destination `UIViewController`
    /// and should be called once, when wrapped.
    /// Solution proposed here: https://stackoverflow.com/a/68567095/7241994
    ///
    func makeUIViewController(context: Self.Context) -> ReviewDetailsViewController {
        let viewController = ReviewDetailsViewController(productReview: productReview,
                                                         product: product,
                                                         notification: notification)
        context.coordinator.parentObserver = viewController.observe(\.parent, changeHandler: { vc, _ in
            vc.parent?.navigationItem.title = vc.title
            vc.parent?.navigationItem.rightBarButtonItems = vc.navigationItem.rightBarButtonItems
        })
        return viewController
    }

    func updateUIViewController(_ uiViewController: ReviewDetailsViewController, context: Context) {
        // nothing to do here
    }

    func makeCoordinator() -> Self.Coordinator { Coordinator() }
}
