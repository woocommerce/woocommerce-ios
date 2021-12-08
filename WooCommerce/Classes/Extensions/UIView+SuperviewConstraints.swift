import UIKit

extension UIView {
    @discardableResult
    public func constrainToSuperview(attribute: NSLayoutConstraint.Attribute,
                                     relatedBy relation: UIKit.NSLayoutConstraint.Relation = .equal,
                                     constant: CoreGraphics.CGFloat = 0) -> UIKit.NSLayoutConstraint {
        NSLayoutConstraint(item: self,
                           attribute: attribute,
                           relatedBy: relation,
                           toItem: superview,
                           attribute: attribute,
                           multiplier: 0,
                           constant: constant)
    }
}
