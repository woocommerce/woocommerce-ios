import Foundation
import UIKit

final class OrdersBadgeController {

    /// Shows the Badge in the specified WooTab
    ///
    func showBadgeOn(_ tab: WooTab, in tabBar: UITabBar, withValue badgeText: String) {
        hideBadgeOn(tab, in: tabBar)

        let badgeView = badge(for: tab, with: badgeText)
        tabBar.subviews[tab.rawValue].subviews.first?.insertSubview(badgeView, at: 1)
        badgeView.fadeIn()
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
}

// MARK: - Constants!
//
private extension OrdersBadgeController {

    enum Constants {
        static let borderWidth = CGFloat(1)
        static let xOffset     = CGFloat(14)
        static let yOffset     = CGFloat(1)
        static let tagOffset   = 999
        static let width       = CGFloat(15)
        static let extendWidth = CGFloat(23)
        static let height      = CGFloat(15)
    }

    func badge(for tab: WooTab, with text: String) -> BadgeLabel {
        var width = Constants.width
        var horizontalPadding = CGFloat(2)

        let ninePlus = NSLocalizedString("9+", comment: "A badge with the number of orders. More than nine new orders.")
        if text == ninePlus {
            horizontalPadding = CGFloat(4)
            width = Constants.extendWidth
        }

        let returnValue = BadgeLabel(frame: CGRect(x: Constants.xOffset,
                                             y: Constants.yOffset,
                                             width: width,
                                             height: Constants.height))
        returnValue.tag = badgeTag(for: tab)
        returnValue.text = text
        returnValue.font = StyleManager.badgeFont
        returnValue.borderColor = StyleManager.wooWhite
        returnValue.borderWidth = 1
        returnValue.textColor = StyleManager.wooWhite
        returnValue.horizontalPadding = horizontalPadding
        returnValue.cornerRadius = 8
        returnValue.fillColor = StyleManager.wooCommerceBrandColor
        returnValue.isHidden = true
        returnValue.adjustsFontForContentSizeCategory = false

        return returnValue
    }

    func badgeTag(for tab: WooTab) -> Int {
        return tab.rawValue + Constants.tagOffset
    }
}
