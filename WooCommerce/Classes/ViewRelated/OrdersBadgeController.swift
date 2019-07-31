import Foundation
import UIKit

final class OrdersBadgeController {

    /// Shows the Badge in the specified WooTab
    ///
    func showBadgeOn(_ tab: WooTab, in tabBar: UITabBar, withValue badgeText: String) {
        hideBadgeOn(tab, in: tabBar)
        let badge = BadgeLabel(frame: CGRect(x: Constants.xOffset,
                                             y: Constants.yOffset,
                                             width: Constants.width,
                                             height: Constants.height))
        badge.tag = badgeTag(for: tab)
        badge.font = StyleManager.badgeFont
        badge.backgroundColor = StyleManager.wooCommerceBrandColor
        badge.borderColor = StyleManager.wooWhite
        badge.borderWidth = 1
        badge.textColor = StyleManager.wooWhite
        badge.horizontalPadding = 2
        badge.cornerRadius = 8
        badge.textAlignment = .center
        badge.text = badgeText
        badge.isHidden = true
        tabBar.subviews[tab.rawValue].subviews.first?.insertSubview(badge, at: 1)
        badge.fadeIn()
    }

    /// Hides the Dot in the specified WooTab
    ///
    func hideBadgeOn(_ tab: WooTab, in tabBar: UITabBar) {
        let tag = badgeTag(for: tab)
        if let subviews = tabBar.subviews[tab.rawValue].subviews.first?.subviews {
            for subview in subviews where subview.tag == tag {
                subview.fadeOut() { _ in
                    subview.removeFromSuperview()
                }
            }
        }
    }

    /// Returns the DotView's Tag for the specified WooTab
    ///
    func badgeTag(for tab: WooTab) -> Int {
        return tab.rawValue + Constants.tagOffset
    }
}

// MARK: - Constants!
//
private extension OrdersBadgeController {

    enum Constants {
        static let diameter    = CGFloat(10)
        static let borderWidth = CGFloat(1)
        static let xOffset     = CGFloat(14)
        static let yOffset     = CGFloat(1)
        static let tagOffset   = 999
        static let width       = CGFloat(23)
        static let height      = CGFloat(17)
    }
}
