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
                                           icon: .workInProgressBanner,
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
        static let title = NSLocalizedString("Work in progress", comment: "Title of the banner notice in the add-ons view")
        static let description = NSLocalizedString("View product add-ons is in beta. " +
                                                    "You can edit these add-ons in the web dashboard. " +
                                                   "By renaming an add-on, any old orders won’t show that add-on in the app.",
                                                   comment: "Content of the banner notice in the add-ons view")
        static let giveFeedback = NSLocalizedString("Give Feedback", comment: "Title of the button to give feedback about the add-ons feature")
        static let dismiss = NSLocalizedString("Dismiss", comment: "Title of the button to dismiss the banner notice in the add-ons view")
    }
}

/// Class that wraps a `TopBannerView` instance in order to provide an explicit `intrinsicContentSize`.
/// Needed as `SwiftUI` fails to properly calculate it's dynamic height.
///
final class TopBannerWrapperView: UIView {
    /// BannerView to wrap
    ///
    var bannerView: TopBannerView?

    /// Desired `width` of the view. Needed to calculate the view dynamic `height`.
    ///
    let width: CGFloat

    init(width: CGFloat) {
        self.width = width
        super.init(frame: .zero)
    }

    /// Sets the main banner view and adds it as a subview.
    /// Discussion: The banner view is intentionally received as a function parameter(rather than in `init`) to allow consumer
    /// references to `TopBannerWrapperView` in  view model closures.
    ///
    func setBanner(_ bannerView: TopBannerView) {
        self.bannerView?.removeFromSuperview()

        bannerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bannerView)
        bannerView.pinSubviewToAllEdges(self)
        self.bannerView = bannerView
    }

    /// Returns the preferred size of the view using on a fixed width.
    ///
    override var intrinsicContentSize: CGSize {
        guard let bannerView = bannerView else {
            return .zero
        }

        let targetSize =  CGSize(width: width, height: 0)
        return bannerView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultLow)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
