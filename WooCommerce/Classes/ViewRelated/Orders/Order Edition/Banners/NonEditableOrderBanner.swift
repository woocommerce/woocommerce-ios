import Foundation
import SwiftUI

/// Banner to inform that an order is not editable.
///
struct NonEditableOrderBanner: UIViewRepresentable {
    typealias Callback = () -> ()

    /// Desired `width` of the view.
    ///
    private let width: CGFloat

    /// Create a view with the desired `width`. Needed to calculate a correct view `height` later.
    ///
    init(width: CGFloat) {
        self.width = width
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(bannerWrapper: TopBannerWrapperView())
    }

    func makeUIView(context: Context) -> UIView {
        let expandButton = TopBannerViewModel.TopButtonType.chevron {
            context.coordinator.bannerWrapper.invalidateIntrinsicContentSize() // Forces the view to recalculate it's size as it collapses/expands
        }

        let viewModel = TopBannerViewModel(title: Localization.title,
                                           infoText: Localization.description,
                                           icon: UIImage.gridicon(.lock),
                                           iconTintColor: .brand,
                                           isExpanded: false,
                                           topButton: expandButton)
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

// MARK: Coordinator
extension NonEditableOrderBanner {
    /// Hold state across `SwiftUI` lifecycle passes.
    ///
    struct Coordinator {
        /// Banner wrapper that will contain a `TopBannerView`.
        ///
        let bannerWrapper: TopBannerWrapperView
    }
}

// MARK: Localization
private extension NonEditableOrderBanner {
    enum Localization {
        static let title = NSLocalizedString("Parts of this order are not currently editable", comment: "Title of the banner when the order is not editable")
        static let description = NSLocalizedString("To edit Products or Payment Details, please change the status to Pending Payment.",
                                                   comment: "Content of the banner when the order is not editable")
    }
}
