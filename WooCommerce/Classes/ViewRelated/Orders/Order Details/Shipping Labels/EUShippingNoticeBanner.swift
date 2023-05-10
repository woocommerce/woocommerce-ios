import Foundation
import SwiftUI

struct EUShippingNoticeBanner: UIViewRepresentable {
    /// Desired `width` of the view.
    ///
    private let width: CGFloat

    func makeUIView(context: Context) -> UIViewType {
        fatalError("makeUIView(context:) has not been implemented")
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(bannerWrapper: TopBannerWrapperView())
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.bannerWrapper.width = width
    }
}

extension EUShippingNoticeBanner {
    /// Hold state across `SwiftUI` lifecycle passes.
    ///
    struct Coordinator {
        /// Banner wrapper that will contain a `TopBannerView`.
        ///
        let bannerWrapper: TopBannerWrapperView
    }
}
