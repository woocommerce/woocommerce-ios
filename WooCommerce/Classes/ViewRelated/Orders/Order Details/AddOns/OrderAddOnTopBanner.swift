import Foundation
import SwiftUI

struct OrderAddOnTopBanner: UIViewRepresentable {

    /// `UIKit` view state.
    ///
    private let state: State

    /// Initialize the wrapper with the desired `width` of the view. Needed to provide a correct view `height` later.
    ///
    init(width: CGFloat) {
        state = State(bannerWrapper: TopBannerWrapperView(width: width))
    }

    func makeUIView(context: Context) -> UIView {
        let viewModel = TopBannerViewModel(title: Localization.title,
                                           infoText: Localization.description,
                                           icon: .workInProgressBanner,
                                           topButton: .chevron {
                                            // Forces `SwiftUI` to recalculate it's size as the view collapses/expands
                                            state.bannerWrapper.invalidateIntrinsicContentSize()
                                           },
                                           actionButtons: [TopBannerViewModel.ActionButton(title: Localization.giveFeedback) {
                                            state.onGiveFeedback()
                                           },
                                           TopBannerViewModel.ActionButton(title: Localization.dismiss) {
                                            state.onDismissHandler()
                                           }
                                           ])

        let mainBanner = TopBannerView(viewModel: viewModel)

        state.bannerWrapper.setBanner(mainBanner)
        return state.bannerWrapper
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // No-op
    }

    /// Updates the closure to be called when the "dismiss" button is pressed.
    ///
    func onDismiss(_ handler: @escaping () -> Void) -> OrderAddOnTopBanner {
        state.onDismissHandler = handler
        return self
    }

    /// Updates the closure to be called when the "Give Feedback" button is pressed.
    ///
    func onGiveFeedback(_ handler: @escaping () -> Void) -> OrderAddOnTopBanner {
        state.onGiveFeedback = handler
        return self
    }
}

private extension OrderAddOnTopBanner {
    /// Hold necessary state that needs to be referenced from `TopBannerViewModel.init()`
    ///
    class State {
        /// Banner wrapper that will contain a `TopBannerView`.
        ///
        let bannerWrapper: TopBannerWrapperView

        /// Closure to be invoked when the "Dismiss" button is pressed.
        ///
        var onDismissHandler = {}

        /// Closure to be invoked when the "Give Feedback" button is pressed.
        ///
        var onGiveFeedback = {}

        init(bannerWrapper: TopBannerWrapperView) {
            self.bannerWrapper = bannerWrapper
        }
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
