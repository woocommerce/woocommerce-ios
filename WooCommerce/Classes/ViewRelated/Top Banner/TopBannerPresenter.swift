import UIKit

/// Ability to show and hide a banner
///
protocol TopBannerPresenter {
    var topBannerView: UIView? { get }

    func showTopBanner(_ topBannerView: UIView)
    func hideTopBanner(animated: Bool)
}
