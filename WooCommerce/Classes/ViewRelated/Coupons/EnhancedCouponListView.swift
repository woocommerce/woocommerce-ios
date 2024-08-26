import SwiftUI

struct EnhancedCouponListView: UIViewControllerRepresentable {
    let siteID: Int64

    func makeUIViewController(context: Self.Context) -> EnhancedCouponListViewController {
        let viewController = EnhancedCouponListViewController(siteID: siteID)
        return viewController
    }

    func updateUIViewController(_ uiViewController: EnhancedCouponListViewController, context: Context) {
        // nothing to do here
    }
}
