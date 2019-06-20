import UIKit


// MARK: - PaddedLabel: UILabel subclass that allows for Text Insets.
//
class PaddedLabel: UILabel {

    /// Insets to be applied over the Label's Text.
    ///
    var textInsets = Constants.defaultInsets


    // MARK: - Overridden Methods

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insetRect = bounds.inset(by: textInsets)
        let textRect = super.textRect(forBounds: insetRect, limitedToNumberOfLines: numberOfLines)
        let invertedInsets = UIEdgeInsets(top: -textInsets.top,
                                          left: -textInsets.left,
                                          bottom: -textInsets.bottom,
                                          right: -textInsets.right)
        return textRect.inset(by: invertedInsets)
    }
}


// MARK: - Constants!
//
private extension PaddedLabel {

    enum Constants {
        static let defaultInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
    }
}
