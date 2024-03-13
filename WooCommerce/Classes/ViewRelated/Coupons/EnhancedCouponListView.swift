import Combine
import SwiftUI

/// SwiftUI view for the coupon list screen.
///
struct EnhancedCouponListView: View {
    let siteID: Int64
    let navigationPublisher: AnyPublisher<Void, Never>

    var body: some View {
        EnhancedCouponListWrapperView(siteID: siteID, navigationPublisher: navigationPublisher)
            .navigationTitle(Localization.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
    }
}

private extension EnhancedCouponListView {
    enum Localization {
        static let navigationTitle = NSLocalizedString(
            "enhancedCouponListView.navigationTitle",
            value: "Coupons",
            comment: "Navigation title for the coupon list screen"
        )
    }
}

private struct EnhancedCouponListWrapperView: UIViewControllerRepresentable {
    let siteID: Int64
    let navigationPublisher: AnyPublisher<Void, Never>

    func makeUIViewController(context: Self.Context) -> EnhancedCouponListViewController {
        let viewController = EnhancedCouponListViewController(siteID: siteID, navigationPublisher: navigationPublisher)
        return viewController
    }

    func updateUIViewController(_ uiViewController: EnhancedCouponListViewController, context: Context) {
        // nothing to do here
    }
}
