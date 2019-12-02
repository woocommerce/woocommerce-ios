import Foundation
import UIKit


/// StringStyles: Defines a collection of Text Attributes
///
struct StringStyles {

    /// Attributed String's Style (convenience) Alias.
    ///
    typealias Style = [NSAttributedString.Key: Any]

    /// Style to be applied over the entire text.
    ///
    let regular: Style

    /// Bold: Ranges = [.user]
    ///
    let bold: Style?

    /// Italics: Ranges = [.comment, .post]
    ///
    let italics: Style?

    /// Blockquote: Ranges = [.blockquote]
    ///
    let blockquote: Style?

    /// Match: Ranges = [.match]
    ///
    let match: Style?

    /// Noticon: Ranges [.noticon]
    ///
    let noticon: Style?

    /// Links
    ///
    let link: Style?


    /// Designated Initializer.
    ///
    init(regular: Style, bold: Style? = nil, blockquote: Style? = nil, italics: Style? = nil, match: Style? = nil, noticon: Style? = nil, link: Style? = nil) {
        self.regular = regular
        self.bold = bold
        self.blockquote = blockquote
        self.italics = italics
        self.match = match
        self.noticon = noticon
        self.link = link
    }
}


// MARK: - Default Styles
//
extension StringStyles {

    /// Styles: Notifications List / Subject Block
    ///
    static var subject: StringStyles {
        let regular: Style      = [.paragraphStyle: NSParagraphStyle.body, .font: UIFont.body, .foregroundColor: UIColor.text]
        let bold: Style         = [.paragraphStyle: NSParagraphStyle.body, .font: UIFont.body.bold]
        let blockquote: Style   = [.paragraphStyle: NSParagraphStyle.body, .font: UIFont.body.italics]
        let italics: Style      = [.paragraphStyle: NSParagraphStyle.body, .font: UIFont.body.italics]
        let noticon: Style      = [.paragraphStyle: NSParagraphStyle.body, .font: UIFont.noticon(forStyle: .body), .foregroundColor: UIColor.listIcon]

        return StringStyles(regular: regular, bold: bold, blockquote: blockquote, italics: italics, match: nil, noticon: noticon)
    }


    /// Styles: Notifications List / Snippet Block
    ///
    static var snippet: StringStyles {
        let regular: Style = [.paragraphStyle: NSParagraphStyle.truncatingTailFootnote, .font: UIFont.footnote, .foregroundColor: UIColor.text]
        return StringStyles(regular: regular)
    }


    /// Styles: Notification Defailts / Header Block
    ///
    static let header: StringStyles = {
        let regular: Style      = [.font: UIFont.body, .foregroundColor: UIColor.text]
        let bold: Style         = [.font: UIFont.body.bold, .foregroundColor: UIColor.text]
        let italics: Style      = [.font: UIFont.body.italics, .foregroundColor: UIColor.text]

        return StringStyles(regular: regular, bold: bold, italics: italics)
    }()


    /// Styles: Notification Defailts / Footer Block
    ///
    static let footer: StringStyles = {
        let regular: Style      = [.paragraphStyle: NSParagraphStyle.body, .font: UIFont.body, .foregroundColor: UIColor.text]

        return StringStyles(regular: regular, noticon: body.noticon)
    }()


    /// Styles: Notification Defailts / Body Blocks
    ///
    static let body: StringStyles = {
        let regular: Style = [.paragraphStyle: NSParagraphStyle.body,
                              .font: UIFont.body,
                              .foregroundColor: UIColor.text]

        let bold: Style = [.paragraphStyle: NSParagraphStyle.body,
                           .font: UIFont.body.bold,
                           .foregroundColor: UIColor.text]

        let blockquote: Style = [.paragraphStyle: NSParagraphStyle.body,
                                 .font: UIFont.body.italics,
                                 .foregroundColor: UIColor.text]

        let match: Style = [.paragraphStyle: NSParagraphStyle.body,
                            .font: UIFont.body.bold,
                            .foregroundColor: UIColor.text]

        let noticon: Style = [.paragraphStyle: NSParagraphStyle.body,
                              .font: UIFont.noticon(forStyle: .body),
                              .foregroundColor: UIColor.text]

        let italic: Style = [.paragraphStyle: NSParagraphStyle.body,
                             .font: UIFont.body.italics,
                             .foregroundColor: UIColor.text]

        let link: Style = [.foregroundColor: UIColor.primary]

        return StringStyles(regular: regular, bold: bold, blockquote: blockquote, match: match, noticon: noticon, link: link)
    }()
}
