import UIKit

extension UITabBar {
    /// A sorted actionable subviews from the lowest to the highest frame x position.
    var orderedTabBarActionableViews: [UIView] {
        let actionableViews = subviews.filter({ $0.isUserInteractionEnabled })
        return actionableViews.sorted(by: { $0.frame.minX < $1.frame.minX })
    }
}
