import UIKit

/// Container view for the Products tab top banner that handles updates on the top banner.
final class ProductsTopBannerContainerView: UIView {
    private var topBannerView: UIView?

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateTopBanner(_ topBanner: UIView) {
        topBannerView?.removeFromSuperview()

        addSubview(topBanner)
        topBannerView = topBanner
        pinSubviewToAllEdges(topBanner, insets: .zero)
    }
}
