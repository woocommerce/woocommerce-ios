import Foundation
import UIKit

final class OrdersBadgeController {

    /// Shows the Badge in the specified WooTab
    ///
    func showBadgeOn(_ tab: WooTab, in tabBar: UITabBar, tabIndex: Int, withValue badgeText: String) {
        hideBadgeOn(tab, in: tabBar, tabIndex: tabIndex)

        let badgeView = badge(for: tab, with: badgeText, tabIndex: tabIndex)
        tabBar.orderedTabBarActionableViews[tabIndex].subviews.first?.insertSubview(badgeView, at: 1)
        updateBadgePosition(tab, in: tabBar, tabIndex: tabIndex)
        badgeView.fadeIn()
    }

    /// Hides the Dot in the specified WooTab
    ///
    func hideBadgeOn(_ tab: WooTab, in tabBar: UITabBar, tabIndex: Int) {
        let tag = badgeTag(for: tab)
        if let subviews = tabBar.orderedTabBarActionableViews[tabIndex].subviews.first?.subviews {
            for subview in subviews where subview.tag == tag {
                subview.fadeOut() { _ in
                    subview.removeFromSuperview()
                }
            }
        }
    }

    /// Updates the badge position in the specified WooTab
    ///
    func updateBadgePosition(_ tab: WooTab, in tabBar: UITabBar, tabIndex: Int) {
        guard let badgeLabel = badgeView(tab: tab, in: tabBar, tabIndex: tabIndex) as? BadgeLabel else {
            return
        }

        let tabAxis = tabLayoutAxis(tab: tab, in: tabBar, tabIndex: tabIndex)
        let showsNinePlusText = badgeLabel.text == Constants.ninePlus

        let xOffset: CGFloat
        let yOffset: CGFloat

        switch tabAxis {
        case .horizontal:
            xOffset = showsNinePlusText ? Constants.xOffsetForNinePlusLandscape: Constants.xOffsetLandscape
            yOffset = showsNinePlusText ? Constants.yOffsetForNinePlusLandscape: Constants.yOffsetLandscape
        case .vertical:
            xOffset = showsNinePlusText ? Constants.xOffsetForNinePlus: Constants.xOffset
            yOffset = showsNinePlusText ? Constants.yOffsetForNinePlus: Constants.yOffset
        }

        badgeLabel.frame.origin = CGPoint(x: xOffset, y: yOffset)
    }
}

private extension OrdersBadgeController {
    func badgeView(tab: WooTab, in tabBar: UITabBar, tabIndex: Int) -> UIView? {
        let tag = badgeTag(for: tab)
        let subviews = tabBar.orderedTabBarActionableViews[tabIndex].subviews.first?.subviews
            .filter({ $0.tag == tag })
        guard let subview = subviews?.first, subviews?.count == 1 else {
            return nil
        }
        return subview
    }

    /// Checks if a tab layout is vertical or horizontal, since there is no API to check for tab layout axis.
    /// The calculation is based on the following assumptions.
    /// If the two subviews assumption does not hold anymore with UIKit changes, `vertical` is returned.
    ///   1. The tab view (`UITabBarButton`) has two subviews - one for image and the other for text label
    ///   2. The tab layout is vertical if the subview with a larger min y has its min y larger than the max y of the other subview.
    func tabLayoutAxis(tab: WooTab, in tabBar: UITabBar, tabIndex: Int) -> UIView.Axis {
        return tabBar.orderedTabBarActionableViews[tabIndex].axisOfTwoSubviews() ?? .vertical
    }
}

// MARK: - Constants!
//
private extension OrdersBadgeController {

    enum Constants {
        static let borderWidth  = CGFloat(1)
        static let cornerRadius = CGFloat(8)

        static let width = CGFloat(18)
        static let xOffset = CGFloat(13)
        static let yOffset = CGFloat(-2)
        static let xOffsetLandscape = CGFloat(10)
        static let yOffsetLandscape = CGFloat(-4)
        static let horizontalPadding = CGFloat(2)

        // "9+" layout to account for longer text
        static let widthForNinePlus = CGFloat(25)
        static let xOffsetForNinePlus = CGFloat(10)
        static let yOffsetForNinePlus = CGFloat(-1)
        static let xOffsetForNinePlusLandscape = CGFloat(8)
        static let yOffsetForNinePlusLandscape = CGFloat(-4)
        static let horizontalPaddingForNinePlus = CGFloat(4)

        static let tagOffset = 999

        static let height = CGFloat(18)

        static let ninePlus = NSLocalizedString("9+", comment: "A badge with the number of orders. More than nine new orders.")
    }

    func badge(for tab: WooTab, with text: String, tabIndex: Int) -> BadgeLabel {
        let width: CGFloat
        let horizontalPadding: CGFloat // Badge inset

        if text == Constants.ninePlus {
            width = Constants.widthForNinePlus
            horizontalPadding = Constants.horizontalPaddingForNinePlus
        } else {
            width = Constants.width
            horizontalPadding = Constants.horizontalPadding
        }

        let returnValue = BadgeLabel(frame: CGRect(x: Constants.xOffset,
                                                   y: Constants.yOffset,
                                                   width: width,
                                                   height: Constants.height))

        returnValue.tag = badgeTag(for: tab)
        returnValue.text = text
        returnValue.font = StyleManager.badgeFont
        returnValue.borderColor = StyleManager.wooWhite
        returnValue.borderWidth = Constants.borderWidth
        returnValue.textColor = StyleManager.wooWhite
        returnValue.horizontalPadding = horizontalPadding
        returnValue.cornerRadius = Constants.cornerRadius

        // BUGFIX: Don't add the backgroundColor property, use this!
        // Labels with rounded borders and a background color will end
        // up with a fuzzy shadow / outline outside of the border color.
        returnValue.fillColor = StyleManager.wooCommerceBrandColor

        returnValue.isHidden = true
        returnValue.adjustsFontForContentSizeCategory = false

        return returnValue
    }

    func badgeTag(for tab: WooTab) -> Int {
        return tab.identifierNumber + Constants.tagOffset
    }
}
