import UIKit

/// Ability to show and hide a banner
///
protocol TopBannerPresenter {
    var topBannerView: TopBannerView? { get }

    func showTopBanner(_ topBannerView: TopBannerView, animated: Bool)
    func hideTopBanner(animated: Bool)
}
