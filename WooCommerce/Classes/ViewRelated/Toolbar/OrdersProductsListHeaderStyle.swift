import UIKit

/// Shared background and scroll behavior for list headers that extend below the navigation bar.
@available(iOS 26.0, *)
@MainActor
enum OrdersProductsListHeaderStyle {
    static func makeBackgroundView() -> UIView {
        let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        backgroundView.isUserInteractionEnabled = false
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        return backgroundView
    }

    static func configureNavigationAppearance(navigationItem: UINavigationItem,
                                             scrollView: UIScrollView,
                                             isHeaderVisible: Bool = true) {
        // A single blur spans the navigation bar and header. Restore UIKit's background when the header is hidden.
        let appearance: UINavigationBarAppearance? = isHeaderVisible ? UINavigationBarAppearance() : nil
        appearance?.configureWithTransparentBackground()
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.compactScrollEdgeAppearance = appearance
        scrollView.topEdgeEffect.isHidden = isHeaderVisible
    }

    static func updateScrollPosition(backgroundView: UIView?,
                                     headerViews: [UIView],
                                     scrollView: UIScrollView,
                                     isHeaderHidden: Bool = false) {
        // One shared blur removes the navigation/filter background seam, but can also blur UIKit's table-hosted large title.
        // Hide it at the top to keep the title sharp; 0.5 allows for layout rounding.
        // Related reports: FB21613303 (SwiftUI large-title blur) and FB20756572 (UIKit edge-effect sizing):
        // https://github.com/jensvansteen/ScrollEdgeBar#pull-requests
        // https://developer.apple.com/forums/thread/803378
        backgroundView?.isHidden = isHeaderHidden || scrollView.contentOffset.y + scrollView.adjustedContentInset.top <= 0.5
        let transform = CGAffineTransform(translationX: 0, y: scrollView.topOverscrollDistance)
        backgroundView?.transform = transform
        headerViews.forEach { $0.transform = transform }
    }
}
