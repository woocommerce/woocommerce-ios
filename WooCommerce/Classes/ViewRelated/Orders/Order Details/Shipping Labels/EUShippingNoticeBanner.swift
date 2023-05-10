import Foundation
import SwiftUI

struct EUShippingNoticeBanner: UIViewRepresentable {
    /// Desired `width` of the view.
    ///
    private let width: CGFloat

    /// Closure to be invoked when the "Learn more" button is pressed.
    ///
    private var onGiveFeedback: Callback? = nil

    /// Closure to be invoked when the "Dismiss" button is pressed.
    ///
    private var onDismiss: Callback? = nil

    /// Create a view with the desired `width`. Needed to calculate a correct view `height` later.
    ///
    init(width: CGFloat) {
        self.width = width
    }

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
