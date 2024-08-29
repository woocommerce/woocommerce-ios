import SwiftUI

struct EnhancedCouponListView: UIViewControllerRepresentable {
    let siteID: Int64

    class Coordinator {
        var parentObserver: NSKeyValueObservation?
    }

    /// This is a UIKit solution for fixing Bar Button Items ignored in NavigationView.
    /// This solution doesn't require making internal changes to the destination `UIViewController`
    /// and should be called once, when wrapped.
    /// Solution proposed here: https://stackoverflow.com/a/68567095/7241994
    ///
    func makeUIViewController(context: Self.Context) -> EnhancedCouponListViewController {
        let viewController = EnhancedCouponListViewController(siteID: siteID)

        // This makes sure that the navigation item of the hosting controller
        // is in sync with that of the wrapped controller.
        context.coordinator.parentObserver = viewController.observe(\.parent, changeHandler: { vc, _ in
            vc.parent?.navigationItem.rightBarButtonItems = vc.navigationItem.rightBarButtonItems
        })

        return viewController
    }

    func updateUIViewController(_ uiViewController: EnhancedCouponListViewController, context: Context) {
        // nothing to do here
    }

    func makeCoordinator() -> Self.Coordinator { Coordinator() }
}
