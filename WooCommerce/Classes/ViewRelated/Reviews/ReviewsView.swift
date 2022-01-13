import SwiftUI

/// SwiftUI conformance for `ReviewsViewController`
///
struct ReviewsView: UIViewControllerRepresentable {
    let siteID: Int64

    typealias UIViewControllerType = ReviewsViewController

    class Coordinator {
        var parentObserver: NSKeyValueObservation?
        var rightBarButtonItemObserver: NSKeyValueObservation?
    }

    /// This is a UIKit solution for fixing Navigation Title and Bar Button Items ignored in NavigationView.
    /// This solution doesn't require making internal changes to the destination `UIViewController`
    /// and should be called once, when wrapped.
    /// Solution proposed here: https://stackoverflow.com/a/68567095/7241994
    ///
    func makeUIViewController(context: Self.Context) -> ReviewsViewController {
        let viewController = ReviewsViewController(siteID: siteID)
        // This makes sure that the navigation item of the hosting controller
        // is in sync with that of the wrapped controller.
        context.coordinator.parentObserver = viewController.observe(\.parent, changeHandler: { vc, _ in
            vc.parent?.navigationItem.title = vc.title
            vc.parent?.navigationItem.rightBarButtonItems = vc.navigationItem.rightBarButtonItems
        })

        // This fixes the issue when `rightBarButtonItem` is updated in `ReviewsViewController`,
        // the hosting controller should be updated to reflect the change.
        context.coordinator.rightBarButtonItemObserver = viewController.observe(\.navigationItem.rightBarButtonItem, changeHandler: { vc, _ in
            vc.parent?.navigationItem.rightBarButtonItems = vc.navigationItem.rightBarButtonItems
        })
        return viewController
    }

    func updateUIViewController(_ uiViewController: ReviewsViewController, context: Context) {
        // nothing to do here
    }

    func makeCoordinator() -> Self.Coordinator { Coordinator() }
}
