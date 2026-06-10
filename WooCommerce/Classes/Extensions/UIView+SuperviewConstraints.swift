import UIKit

extension UIView {
    static func makeLiquidGlassHeaderBackgroundView() -> UIView {
        let backgroundView: UIView
        if #available(iOS 26.0, *) {
            let effect = UIGlassEffect(style: .regular)
            backgroundView = UIVisualEffectView(effect: effect)
        } else {
            let view = UIView()
            view.backgroundColor = .listForeground(modal: false)
            backgroundView = view
        }

        backgroundView.isUserInteractionEnabled = false
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        return backgroundView
    }

    @discardableResult
    public func constrainToSuperview(attribute: NSLayoutConstraint.Attribute,
                                     relatedBy relation: UIKit.NSLayoutConstraint.Relation = .equal,
                                     constant: CoreGraphics.CGFloat = 0) -> UIKit.NSLayoutConstraint {
        NSLayoutConstraint(item: self,
                           attribute: attribute,
                           relatedBy: relation,
                           toItem: superview,
                           attribute: attribute,
                           multiplier: 1,
                           constant: constant)
    }
}
