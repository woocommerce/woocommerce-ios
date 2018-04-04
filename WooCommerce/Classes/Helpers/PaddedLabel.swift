import UIKit

@IBDesignable class PaddedLabel: UILabel {
    @IBInspectable var insets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

    override func drawText(in rect: CGRect) {
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }

    override var intrinsicContentSize: CGSize {
        var intrinsicSuperViewContentSize = super.intrinsicContentSize
        intrinsicSuperViewContentSize.height += insets.top + insets.bottom
        intrinsicSuperViewContentSize.width += insets.left + insets.right
        return intrinsicSuperViewContentSize
    }
}
