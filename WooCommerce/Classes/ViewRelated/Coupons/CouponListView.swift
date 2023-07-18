import SwiftUI
import Yosemite

struct CouponListView: UIViewControllerRepresentable {
    let siteID: Int64
    let emptyStateActionTitle: String
    let emptyStateAction: (() -> Void)
    let onCouponSelected: ((Coupon) -> Void)

    func makeUIViewController(context: Self.Context) -> CouponListViewController {
        let viewController = CouponListViewController(siteID: siteID,
                                                      showFeedbackBannerIfAppropriate: false,
                                                      emptyStateActionTitle: emptyStateActionTitle,
                                                      emptyStateAction: emptyStateAction,
                                                      onCouponSelected: onCouponSelected)
        return viewController
    }

    func updateUIViewController(_ uiViewController: CouponListViewController, context: Context) {}
}
