import Foundation
import SwiftUI

struct OrderAddOnTopBanner: UIViewRepresentable {

    /// The `width` of the view. Needed to provide a correct view `height`.
    ///
    let width: CGFloat

    func makeUIView(context: Context) -> UIView {
        let vm = TopBannerViewModel(title: Localization.title,
                                    infoText: Localization.description,
                                    icon: .workInProgressBanner,
                                    topButton: .chevron(handler: nil),
                                    actionButtons: [TopBannerViewModel.ActionButton(title: Localization.dismiss, action: {})])
        let v = TopBannerView(viewModel: vm)
        return TopBannerWrapperView(bannerView: v, width: width)
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // TODO: Update view
    }

}

private extension OrderAddOnTopBanner {
    enum Localization {
        static let title = NSLocalizedString("Work in progress", comment: "Title of the banner notice in the add-ons view")
        static let dismiss = NSLocalizedString("Dismiss", comment: "Title of the button to dismiss the banner notice in the add-ons view")
        static let description = NSLocalizedString("View product add-ons is in beta. " +
                                                    "You can edit these add-ons in the web dashboard. " +
                                                   "By renaming an add-on, any old orders won’t show that add-on in the app.",
                                                   comment: "Content of the banner notice in the add-ons view")
    }
}

/// Class that wraps a `TopBannerView` instance in order to provide an explicit `intrinsicContentSize`.
/// Needed as `SwiftUI` fails to properly calculate it's dynamic height.
///
final class TopBannerWrapperView: UIView {
    /// BannerView to wrap
    ///
    let bannerView: TopBannerView

    /// Desired `width` of the view. Needed to calculate the view dynamic `height`.
    ///
    let width: CGFloat

    init(bannerView: TopBannerView, width: CGFloat) {
        self.bannerView = bannerView
        self.width = width
        super.init(frame: .zero)

        bannerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bannerView)
        bannerView.pinSubviewToAllEdges(self)
    }

    /// Returns the preferred size of the view using on a fixed width.
    ///
    override var intrinsicContentSize: CGSize {
        let targetSize =  CGSize(width: width, height: 0)
        return bannerView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultLow)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
