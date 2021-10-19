import Foundation
import SwiftUI

struct OrderAddOnTopBanner: UIViewRepresentable {
    typealias Callback = () -> ()

    /// Desired `width` of the view.
    ///
    private let width: CGFloat

    /// Closure to be invoked when the "Give Feedback" button is pressed.
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

    func makeCoordinator() -> Coordinator {
        Coordinator(bannerWrapper: TopBannerWrapperView())
    }

    func makeUIView(context: Context) -> UIView {
        let topButton = TopBannerViewModel.TopButtonType.chevron {
            context.coordinator.bannerWrapper.invalidateIntrinsicContentSize() // Forces the view to recalculate it's size as it collapses/expands
        }
        let giveFeedbackButton = TopBannerViewModel.ActionButton(title: Localization.giveFeedback) { _ in
            onGiveFeedback?()
        }
        let dismissButton = TopBannerViewModel.ActionButton(title: Localization.dismiss) { _ in
            onDismiss?()
        }

        let viewModel = TopBannerViewModel(title: Localization.title,
                                           infoText: Localization.description,
                                           icon: .megaphoneIcon,
                                           topButton: topButton,
                                           actionButtons: [giveFeedbackButton, dismissButton])
        let mainBanner = TopBannerView(viewModel: viewModel)

        // Set the current super view width and the real view to be displayed inside the wrapper.
        context.coordinator.bannerWrapper.width = width
        context.coordinator.bannerWrapper.setBanner(mainBanner)
        return context.coordinator.bannerWrapper
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.bannerWrapper.width = width
    }

    /// Returns a copy of the view with `onDismiss` handling.
    ///
    func onDismiss(_ handler: @escaping Callback) -> OrderAddOnTopBanner {
        var copy = self
        copy.onDismiss = handler
        return copy
    }

    /// Returns a copy of the view with `onGiveFeedback` handling.
    ///
    func onGiveFeedback(_ handler: @escaping Callback) -> OrderAddOnTopBanner {
        var copy = self
        copy.onGiveFeedback = handler
        return copy
    }
}

extension OrderAddOnTopBanner {
    /// Hold state across `SwiftUI` lifecycle passes.
    ///
    struct Coordinator {
        /// Banner wrapper that will contain a `TopBannerView`.
        ///
        let bannerWrapper: TopBannerWrapperView
    }
}

private extension OrderAddOnTopBanner {
    enum Localization {
        static let title = NSLocalizedString("View add-ons from your device!", comment: "Title of the banner notice in the add-ons view")
        static let description = NSLocalizedString("We are working on making it easier for you to see product add-ons from your device! " +
                                                   "For now, you’ll be able to see the add-ons for your orders. " +
                                                   "You can create and edit these add-ons in your web dashboard.",
                                                   comment: "Content of the banner notice in the add-ons view")
        static let giveFeedback = NSLocalizedString("Give feedback", comment: "Title of the button to give feedback about the add-ons feature")
        static let dismiss = NSLocalizedString("Dismiss", comment: "Title of the button to dismiss the banner notice in the add-ons view")
    }
}
