import SwiftUI
import Yosemite

struct CouponListView: UIViewControllerRepresentable {
    let siteID: Int64
    let emptyStateCreateCouponAction: (() -> Void)
    let onCouponSelected: ((Coupon) -> Void)


    func makeUIViewController(context: Self.Context) -> CouponListViewController {
        let viewController = CouponListViewController(siteID: siteID, showFeedbackBannerIfAppropriate: false)
        viewController.onCouponSelected = onCouponSelected
        viewController.emptyStateCreateCouponAction = emptyStateCreateCouponAction
        return viewController
    }

    func updateUIViewController(_ uiViewController: CouponListViewController, context: Context) {}
}
