import Foundation
import SwiftUI

struct EUShippingNoticeBanner: UIViewRepresentable {
    /// Desired `width` of the view.
    ///
    private let width: CGFloat

    /// Closure to be invoked when the "Learn more" button is pressed.
    ///
    private var onLearnMoreTapped: (() -> Void)? = nil

    /// Closure to be invoked when the "Dismiss" button is pressed.
    ///
    private var onDismissTapped: (() -> Void)? = nil

    /// Create a view with the desired `width`. Needed to calculate a correct view `height` later.
    ///
    init(width: CGFloat) {
        self.width = width
    }

    func makeUIView(context: Context) -> UIViewType {
        let topBannerView = EUShippingNoticeTopBannerFactory.createTopBanner(infoType: .instructions) {
            onDismissTapped?()
        } onLearnMorePressed: {
            onLearnMoreTapped?()
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
    func onDismiss(_ handler: @escaping () -> Void) -> EUShippingNoticeBanner {
        var copy = self
        copy.onDismissTapped = handler
        return copy
    }

    /// Returns a copy of the view with `onLearnMoreTapped` handling.
    ///
    func onLearnMore(_ handler: @escaping () -> Void) -> EUShippingNoticeBanner {
        var copy = self
        copy.onLearnMoreTapped = handler
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
