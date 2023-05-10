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

    /// Returns a copy of the view with `onDismissTapped` handling.
    ///
    func onDismiss(_ handler: @escaping Callback) -> EUShippingNoticeBanner {
        var copy = self
        copy.onDismiss = handler
        return copy
    }

    /// Returns a copy of the view with `onLearnMoreTapped` handling.
    ///
    func onLearnMore(_ handler: @escaping Callback) -> EUShippingNoticeBanner {
        var copy = self
        copy.onGiveFeedback = handler
        return copy
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
