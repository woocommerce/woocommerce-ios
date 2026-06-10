import UIKit

extension UIView {
    static func makePinnedHeaderBackgroundView(color: UIColor) -> UIView {
        let backgroundView = UIView()
        backgroundView.backgroundColor = color
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
