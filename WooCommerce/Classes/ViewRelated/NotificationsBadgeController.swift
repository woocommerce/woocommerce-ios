import Foundation
import UIKit

final class NotificationsBadgeController {
    /// Displays or Hides the Dot, depending on the new Badge Value
    ///
    func badgeCountWasUpdated(newValue: Int, in tabBar: UITabBar) {
        guard newValue > 0 else {
            hideDotOn(.notifications, in: tabBar)
            return
        }

        showDotOn(.notifications, in: tabBar)
    }

    /// Shows the dot in the specified WooTab
    ///
    func showDotOn(_ tab: WooTab, in tabBar: UITabBar) {
        hideDotOn(tab, in: tabBar)
        let dot = GreenDotView(frame: CGRect(x: DotConstants.xOffset,
                                             y: DotConstants.yOffset,
                                             width: DotConstants.diameter,
                                             height: DotConstants.diameter), borderWidth: DotConstants.borderWidth)
        dot.tag = dotTag(for: tab)
        dot.isHidden = true
        tabBar.subviews[tab.rawValue].subviews.first?.insertSubview(dot, at: 1)
        dot.fadeIn()
    }

    /// Hides the Dot in the specified WooTab
    ///
    func hideDotOn(_ tab: WooTab, in tabBar: UITabBar) {
        let tag = dotTag(for: tab)
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
    func dotTag(for tab: WooTab) -> Int {
        return tab.rawValue + DotConstants.tagOffset
    }
}


// MARK: - Constants!
//
private extension NotificationsBadgeController {

    enum DotConstants {
        static let diameter    = CGFloat(10)
        static let borderWidth = CGFloat(1)
        static let xOffset     = CGFloat(2)
        static let yOffset     = CGFloat(0)
        static let tagOffset   = 999
    }
}


// MARK: - GreenDot UIView
//
private class GreenDotView: UIView {

    private var borderWidth = CGFloat(1) // Border line width defaults to 1

    /// Designated Initializer
    ///
    init(frame: CGRect, borderWidth: CGFloat) {
        super.init(frame: frame)
        self.borderWidth = borderWidth
        setupSubviews()
    }

    /// Required Initializer
    ///
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }

    private func setupSubviews() {
        backgroundColor = .clear
    }

    override func draw(_ rect: CGRect) {
        let path = UIBezierPath(ovalIn: CGRect(x: rect.origin.x + borderWidth,
                                               y: rect.origin.y + borderWidth,
                                               width: rect.size.width - borderWidth*2,
                                               height: rect.size.height - borderWidth*2))
        StyleManager.wooAccent.setFill()
        path.fill()

        path.lineWidth = borderWidth
        StyleManager.wooWhite.setStroke()
        path.stroke()
    }
}
