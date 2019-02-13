import Foundation
import UIKit


/// NSParagraphStyle: Helper Methods
///
extension NSParagraphStyle {

    /// Returns a ParagraphStyle with it's minimum Line Height set to accomodate `UIFont.subheadline`
    ///
    static var subheadline: NSParagraphStyle {
        return NSMutableParagraphStyle(standardLineHeightUsingFont: UIFont.subheadline)
    }

    /// Returns a ParagraphStyle with it's minimum Line Height set to accomodate `UIFont.body`
    ///
    static var body: NSParagraphStyle {
        return NSMutableParagraphStyle(standardLineHeightUsingFont: UIFont.body)
    }

    /// Returns a ParagraphStyle with it's minimum Line Height set to accomodate `UIFont.footnote`
    ///
    static var footnote: NSParagraphStyle {
        return NSMutableParagraphStyle(standardLineHeightUsingFont: UIFont.footnote)
    }

    /// Returns a ParagraphStyle with it's minimum Line Height set to accomodate `UIFont.footnote` and a `lineBreakMode` set to `.byTruncatingTail`
    ///
    static var truncatingTailFootnote: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.setParagraphStyle(footnote)
        style.lineBreakMode = .byTruncatingTail

        return style
    }

    /// Returns a ParagraphStyle with it's minimum Line Height set to accomodate `UIFont.body` / Centered
    ///
    static var badge: NSParagraphStyle {
        return NSMutableParagraphStyle(standardLineHeightUsingFont: UIFont.body, alignment: .center)
    }
}
