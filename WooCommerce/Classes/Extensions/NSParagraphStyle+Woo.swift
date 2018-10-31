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

    /// Returns a ParagraphStyle with it's minimum Line Height set to accomodate `UIFont.body` / Centered
    ///
    static var badge: NSParagraphStyle {
        return NSMutableParagraphStyle(standardLineHeightUsingFont: UIFont.body, alignment: .center)
    }
}
