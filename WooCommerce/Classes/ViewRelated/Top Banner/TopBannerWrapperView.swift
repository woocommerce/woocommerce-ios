import SwiftUI
import UIKit

/// Class that wraps a `TopBannerView` instance in order to provide an explicit `intrinsicContentSize`.
/// Needed as `SwiftUI` fails to properly calculate it's dynamic height.
///
final class TopBannerWrapperView: UIView {
    /// Desired `width` of the view. Needed to calculate the view dynamic `height`.
    ///
    var width: CGFloat = 0.0

    /// BannerView to wrap
    ///
    var bannerView: TopBannerView?

    /// SwiftUI edge insets to add to paddings of the banner view
    ///
    var edgeInsets: EdgeInsets = .zero {
        didSet {
            removeConstraints(constraints)
            bannerView?.pinSubviewToAllEdges(self, insets: contentInsets)
        }
    }

    /// Calculated paddings for the banner view based on edge insets
    ///
    private var contentInsets: UIEdgeInsets {
        let direction = UIApplication.shared.userInterfaceLayoutDirection
        let orientation = UIDevice.current.orientation
        let contentInsets: UIEdgeInsets
        switch (orientation, direction) {
        case (.landscapeLeft, .rightToLeft),
             (.landscapeRight, .rightToLeft):
            contentInsets = .init(top: edgeInsets.top, left: -edgeInsets.trailing, bottom: edgeInsets.bottom, right: -edgeInsets.leading)
        case (.landscapeLeft, .leftToRight),
             (.landscapeRight, .leftToRight):
            contentInsets = .init(top: edgeInsets.top, left: -edgeInsets.leading, bottom: edgeInsets.bottom, right: -edgeInsets.trailing)
        default:
            contentInsets = .zero
        }
        return contentInsets
    }

    init() {
        super.init(frame: .zero)
    }

    /// Sets the main banner view and adds it as a subview.
    /// Discussion: The banner view is intentionally received as a function parameter(rather than in `init`) to allow consumer
    /// references to `TopBannerWrapperView` in  view model closures.
    ///
    func setBanner(_ bannerView: TopBannerView, edgeInsets: EdgeInsets = .zero) {
        self.bannerView?.removeFromSuperview()

        bannerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bannerView)
        self.bannerView = bannerView
        self.edgeInsets = edgeInsets
        self.backgroundColor = bannerView.backgroundColor
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
