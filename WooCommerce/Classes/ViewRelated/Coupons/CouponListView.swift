import SwiftUI

struct CouponListView: UIViewControllerRepresentable {
    let siteID: Int64

    func makeUIViewController(context: Self.Context) -> CouponListViewController {
        let viewController = CouponListViewController(siteID: siteID, showFeedbackBannerIfAppropriate: false)
        return viewController
    }

    func updateUIViewController(_ uiViewController: CouponListViewController, context: Context) {}
}
