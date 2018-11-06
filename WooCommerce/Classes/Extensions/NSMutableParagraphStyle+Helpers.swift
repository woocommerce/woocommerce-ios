import Foundation
import UIKit


/// NSMutableParagraphStyle: Helper Methods
///
extension NSMutableParagraphStyle {

    /// No Maximum Line Height constant
    ///
    static let NoMaximum = CGFloat(0)

    /// Convenience Initializer
    ///
    convenience init(minLineHeight: CGFloat,
                     maxLineHeight: CGFloat = NoMaximum,
                     lineBreakMode: NSLineBreakMode = .byWordWrapping,
                     alignment: NSTextAlignment = .natural) {

        self.init()
        self.minimumLineHeight = minLineHeight
        self.maximumLineHeight = maxLineHeight
        self.lineBreakMode = lineBreakMode
        self.alignment = alignment
    }

    /// Convenience Initializer: Returns a Paragraph Style with a standard "minimum line height" set to accommodate a
    /// given UIFont instance.
    ///
    convenience init(standardLineHeightUsingFont font: UIFont, alignment: NSTextAlignment = .natural) {
        self.init(minLineHeight: font.lineHeight.rounded(.up), alignment: alignment)
    }
}
