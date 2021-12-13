import Foundation
import SwiftUI

struct ShippingLabelCarrierAndRatesTopBanner: UIViewRepresentable {
    typealias Callback = () -> ()

    /// Desired `width` of the view.
    ///
    private let width: CGFloat

    /// Insets to add to edges of the TopBannerView
    ///
    private let edgeInsets: EdgeInsets

    /// Shipping method
    ///
    private let shippingMethod: String

    /// Shipping cost
    ///
    private let shippingCost: String

    /// Create a view with the desired `width`. Needed to calculate a correct view `height` later.
    ///
    init(width: CGFloat, edgeInsets: EdgeInsets, shippingMethod: String, shippingCost: String) {
        self.width = width
        self.edgeInsets = edgeInsets
        self.shippingMethod = shippingMethod
        self.shippingCost = shippingCost
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(bannerWrapper: TopBannerWrapperView())
    }

    func makeUIView(context: Context) -> UIView {
        let viewModel = TopBannerViewModel(title: nil,
                                           infoText: String(format: Localization.title, shippingMethod, shippingCost),
                                           icon: .infoOutlineImage,
                                           topButton: .none,
                                           actionButtons: [],
                                           type: .info)
        let mainBanner = TopBannerView(viewModel: viewModel)

        // Set the current super view width and the real view to be displayed inside the wrapper.
        context.coordinator.bannerWrapper.width = width
        context.coordinator.bannerWrapper.edgeInsets = edgeInsets
        context.coordinator.bannerWrapper.setBanner(mainBanner, edgeInsets: edgeInsets)
        return context.coordinator.bannerWrapper
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.bannerWrapper.width = width
        context.coordinator.bannerWrapper.edgeInsets = edgeInsets
    }
}

extension ShippingLabelCarrierAndRatesTopBanner {
    /// Hold state across `SwiftUI` lifecycle passes.
    ///
    struct Coordinator {
        /// Banner wrapper that will contain a `TopBannerView`.
        ///
        let bannerWrapper: TopBannerWrapperView
    }
}

private extension ShippingLabelCarrierAndRatesTopBanner {
    enum Localization {
        static let title = NSLocalizedString("Customer paid a %1$@ of %2$@ for shipping",
                                             comment: "Title of the banner notice in Shipping Labels -> Carrier and Rates")
    }
}
