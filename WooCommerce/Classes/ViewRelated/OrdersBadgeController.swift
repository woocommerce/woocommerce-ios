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
