import UIKit

@IBDesignable class PaddedLabel: UILabel {
    @IBInspectable var textInsets = Constants.defaultInsets


    override func drawText(in rect: CGRect) {
        super.drawText(in: UIEdgeInsetsInsetRect(rect, textInsets))
    }

    override var intrinsicContentSize: CGSize {
        var intrinsicSuperViewContentSize = super.intrinsicContentSize
        intrinsicSuperViewContentSize.height += textInsets.top + textInsets.bottom
        intrinsicSuperViewContentSize.width += textInsets.left + textInsets.right
        return intrinsicSuperViewContentSize
    }
}


// MARK: - Constants!
//
private extension PaddedLabel {

    enum Constants {
        static let defaultInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
    }
}
