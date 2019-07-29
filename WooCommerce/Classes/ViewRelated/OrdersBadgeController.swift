import Foundation
import UIKit

final class OrdersBadgeController {
    /// Displays or Hides the Dot, depending on the new Badge Value
    ///
    func badgeCountWasUpdated(newValue: Int, in tabBar: UITabBar) {
        guard newValue > 0 else {
            hideBadgeOn(.orders, in: tabBar)
            return
        }

        showBadgeOn(.orders, in: tabBar)
    }

    /// Shows the dot in the specified WooTab
    ///
    func showBadgeOn(_ tab: WooTab, in tabBar: UITabBar) {
        hideBadgeOn(tab, in: tabBar)
//        let dot = BadgeView(frame: CGRect(x: DotConstants.xOffset,
//                                          y: DotConstants.yOffset,
//                                          width: DotConstants.diameter,
//                                          height: DotConstants.diameter), borderWidth: DotConstants.borderWidth)
        let dot = BadgeLabel(frame: CGRect(x: DotConstants.xOffset, y: DotConstants.yOffset, width: 23, height: 17))
        dot.tag = dotTag(for: tab)
        dot.font = StyleManager.badgeFont
        dot.backgroundColor = StyleManager.wooCommerceBrandColor
        dot.borderColor = StyleManager.wooWhite
        dot.borderWidth = 1
        dot.textColor = StyleManager.wooWhite
        dot.horizontalPadding = 2
        dot.cornerRadius = 8
        dot.textAlignment = .center
        dot.text = "9+"
        dot.isHidden = true
        tabBar.subviews[tab.rawValue].subviews.first?.insertSubview(dot, at: 1)
        dot.fadeIn()
    }

    /// Hides the Dot in the specified WooTab
    ///
    func hideBadgeOn(_ tab: WooTab, in tabBar: UITabBar) {
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
private extension OrdersBadgeController {

    enum DotConstants {
        static let diameter    = CGFloat(10)
        static let borderWidth = CGFloat(1)
        static let xOffset     = CGFloat(14)
        static let yOffset     = CGFloat(1)
        static let tagOffset   = 999
    }
}



// MARK: - Badge UIView
//
private class BadgeView: UIView {

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


class BadgeLabel: UILabel {
    @IBInspectable var horizontalPadding: CGFloat = 0 {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    // MARK: Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    fileprivate func setupView() {
        textAlignment = .center
        layer.masksToBounds = true

        cornerRadius = 2.0
    }

    // MARK: Padding

    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets.init(top: 0, left: horizontalPadding, bottom: 0, right: horizontalPadding)
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        var paddedSize = super.intrinsicContentSize
        paddedSize.width += 2 * horizontalPadding
        return paddedSize
    }

    // MARK: Computed Properties

    @IBInspectable var borderColor: UIColor {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue.cgColor
        }
    }

    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }

    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }
}
