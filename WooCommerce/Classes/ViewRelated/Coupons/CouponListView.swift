import SwiftUI
import Yosemite

struct CouponListView: UIViewControllerRepresentable {
    let siteID: Int64
    let onCouponSelected: ((Coupon) -> Void)

    func makeUIViewController(context: Self.Context) -> CouponListViewController {
        let viewController = CouponListViewController(siteID: siteID, showFeedbackBannerIfAppropriate: false)
        viewController.onCouponSelected = onCouponSelected
        return viewController
    }

    func updateUIViewController(_ uiViewController: CouponListViewController, context: Context) {}
}
