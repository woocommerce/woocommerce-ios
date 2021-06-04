import Foundation
import SwiftUI

struct ShippingLabelPaymentMethodsTopBanner: UIViewRepresentable {

    /// Desired `width` of the view.
    ///
    private let width: CGFloat

    /// Store owner's display name
    ///
    private let storeOwnerDisplayName: String

    /// Store owner's username
    ///
    private let storeOwnerUsername: String

    /// Create a view with the desired `width`. Needed to calculate a correct view `height` later.
    ///
    init(width: CGFloat,
         storeOwnerDisplayName: String,
         storeOwnerUsername: String) {
        self.width = width
        self.storeOwnerDisplayName = storeOwnerDisplayName
        self.storeOwnerUsername = storeOwnerUsername
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(bannerWrapper: TopBannerWrapperView())
    }

    func makeUIView(context: Context) -> UIView {
        let infoText = String.localizedStringWithFormat(Localization.description, storeOwnerDisplayName, storeOwnerUsername)
        let viewModel = TopBannerViewModel(title: nil,
                                           infoText: infoText,
                                           icon: .infoOutlineImage,
                                           topButton: .none,
                                           type: .warning)
        let mainBanner = TopBannerView(viewModel: viewModel)

        // Set the current super view width and the real view to be displayed inside the wrapper.
        context.coordinator.bannerWrapper.width = width
        context.coordinator.bannerWrapper.setBanner(mainBanner)
        return context.coordinator.bannerWrapper
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.bannerWrapper.width = width
    }
}

extension ShippingLabelPaymentMethodsTopBanner {
    /// Hold state across `SwiftUI` lifecycle passes.
    ///
    struct Coordinator {
        /// Banner wrapper that will contain a `TopBannerView`.
        ///
        let bannerWrapper: TopBannerWrapperView
    }
}

private extension ShippingLabelPaymentMethodsTopBanner {
    enum Localization {
        static let description = NSLocalizedString(
            "Only the site owner can manage the shipping label payment methods. Please contact %1$@ (%2$@) to manage payment methods.",
            comment: "Content of the banner notice on the Payment Method screen when user does not have permission to change the payment method. "
            + "%1$@ is a placeholder for the store owner's name. %2$@ is a placeholder for the store owner's username."
        )
    }
}
