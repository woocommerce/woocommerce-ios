import Foundation
import SwiftUI

struct EUShippingNoticeBanner: UIViewRepresentable {
    /// Desired `width` of the view.
    ///
    private let width: CGFloat

    /// Closure to be invoked when the "Learn more" button is pressed.
    ///
    private var onLearnMoreTapped: ((URL?) -> Void)? = nil

    /// Closure to be invoked when the "Dismiss" button is pressed.
    ///
    private var onDismissTapped: (() -> Void)? = nil

    /// Create a view with the desired `width`. Needed to calculate a correct view `height` later.
    ///
    init(width: CGFloat) {
        self.width = width
    }

    func makeUIView(context: Context) -> UIViewType {
        let topBannerView = EUShippingNoticeTopBannerFactory.createTopBanner {
            onDismissTapped?()
        } onLearnMorePressed: { instructionsURL in
            onLearnMoreTapped?(instructionsURL)
        }

        context.coordinator.bannerWrapper.width = width
        context.coordinator.bannerWrapper.setBanner(topBannerView)
        return context.coordinator.bannerWrapper
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
