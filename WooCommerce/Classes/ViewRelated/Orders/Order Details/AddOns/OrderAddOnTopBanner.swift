import Foundation
import SwiftUI

struct OrderAddOnTopBanner: UIViewRepresentable {
    typealias Callback = () -> ()

    /// Banner wrapper that will contain a `TopBannerView`.
    ///
    private let bannerWrapper: TopBannerWrapperView

    /// Closure to be invoked when the "Give Feedback" button is pressed.
    ///
    private var onGiveFeedback: Callback? = nil

    /// Closure to be invoked when the "Dismiss" button is pressed.
    ///
    private var onDismiss: Callback? = nil

    /// Create a view with the desired `width`. Needed to calculate a correct view `height` later.
    ///
    init(width: CGFloat) {
        self.bannerWrapper = TopBannerWrapperView(width: width)
    }

    func makeUIView(context: Context) -> UIView {
        let topButton = TopBannerViewModel.TopButtonType.chevron {
            bannerWrapper.invalidateIntrinsicContentSize() // Forces the view to recalculate it's size as it collapses/expands
        }
        let giveFeedbackButton = TopBannerViewModel.ActionButton(title: Localization.giveFeedback) {
            onGiveFeedback?()
        }
        let dismissButton = TopBannerViewModel.ActionButton(title: Localization.dismiss) {
            onDismiss?()
        }

        let viewModel = TopBannerViewModel(title: Localization.title,
                                           infoText: Localization.description,
                                           icon: .megaphoneIcon,
                                           topButton: topButton,
                                           actionButtons: [giveFeedbackButton, dismissButton])
        let mainBanner = TopBannerView(viewModel: viewModel)

        // Set the real view to be displayed inside the wrapper.
        bannerWrapper.setBanner(mainBanner)
        return bannerWrapper
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // No-op
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

private extension OrderAddOnTopBanner {
    enum Localization {
        static let title = NSLocalizedString("View add-ons from your device!", comment: "Title of the banner notice in the add-ons view")
        static let description = NSLocalizedString("We are working on making it easier for you to see product add-ons from your device! " +
                                                   "For now, you’ll be able to see the add-ons for your orders. " +
                                                   "You can create and edit these add-ons in your web dashboard.",
                                                   comment: "Content of the banner notice in the add-ons view")
        static let giveFeedback = NSLocalizedString("Give Feedback", comment: "Title of the button to give feedback about the add-ons feature")
        static let dismiss = NSLocalizedString("Dismiss", comment: "Title of the button to dismiss the banner notice in the add-ons view")
    }
}
