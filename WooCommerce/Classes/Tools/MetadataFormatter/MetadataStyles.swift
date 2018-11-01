import Foundation
import UIKit


// TODO:
// - Rename
// - Nukes Color Dependencies
// - Unit Tests

let subjectTextColor = UIColor.black
let subjectNoticonColor = UIColor.black
let subjectBlockquotedColor = UIColor.black
let snippetColor = UIColor.black

let headerItalicsColor = UIColor.gray

let bodyNoticonFont = UIFont.body
let bodyTextColor = UIColor.black
let bodyBlockquotedColor = UIColor.black
let bodyLinkColor = UIColor.black
let bodyNoticonColor = UIColor.black

let footerTextColor = UIColor.black


/// MetadataStyles: Defines a collection of Text Attributes
///
struct MetadataStyles {

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
extension MetadataStyles {

    /// Styles: Notifications List / Subject Block
    ///
    static let subject: MetadataStyles = {
        let regular: Style      = [.paragraphStyle: NSParagraphStyle.subheadline, .font: UIFont.subheadline, .foregroundColor: subjectTextColor]
        let bold: Style         = [.paragraphStyle: NSParagraphStyle.subheadline, .font: UIFont.subheadline.bold]
        let blockquote: Style   = [.paragraphStyle: NSParagraphStyle.subheadline, .font: UIFont.subheadline.italics, .foregroundColor: subjectBlockquotedColor]
        let italics: Style      = [.paragraphStyle: NSParagraphStyle.subheadline, .font: UIFont.subheadline.italics]
        let noticon: Style      = [.paragraphStyle: NSParagraphStyle.subheadline, .font: bodyNoticonFont, .foregroundColor: subjectNoticonColor]

        return MetadataStyles(regular: regular, bold: bold, blockquote: blockquote, italics: italics, match: nil, noticon: noticon)
    }()


    /// Styles: Notifications List / Snippet Block
    ///
    static let snippet: MetadataStyles = {
        let regular: Style      = [.paragraphStyle: NSParagraphStyle.subheadline, .font: UIFont.subheadline, .foregroundColor: snippetColor]

        return MetadataStyles(regular: regular)
    }()


    /// Styles: Notification Defailts / Header Block
    ///
    static let header: MetadataStyles = {
        let regular: Style      = [.font: UIFont.body, .foregroundColor: bodyTextColor]
        let bold: Style         = [.font: UIFont.body.bold, .foregroundColor: bodyTextColor]
        let italics: Style      = [.font: UIFont.body.italics, .foregroundColor: headerItalicsColor]

        return MetadataStyles(regular: regular, bold: bold, italics: italics)
    }()


    /// Styles: Notification Defailts / Footer Block
    ///
    static let footer: MetadataStyles = {
        let regular: Style      = [.paragraphStyle: NSParagraphStyle.body, .font: UIFont.body, .foregroundColor: footerTextColor]

        return MetadataStyles(regular: regular, noticon: body.noticon)
    }()


    /// Styles: Notification Defailts / Body Blocks
    ///
    static let body: MetadataStyles = {
        let regular: Style      = [.paragraphStyle: NSParagraphStyle.body, .font: UIFont.body, .foregroundColor: bodyTextColor]
        let bold: Style         = [.paragraphStyle: NSParagraphStyle.body, .font: UIFont.body.bold, .foregroundColor: bodyTextColor]
        let blockquote: Style   = [.paragraphStyle: NSParagraphStyle.body, .font: UIFont.body.italics, .foregroundColor: bodyBlockquotedColor]
        let match: Style        = [.paragraphStyle: NSParagraphStyle.body, .font: UIFont.body.bold, .foregroundColor: bodyLinkColor]
        let noticon: Style      = [.paragraphStyle: NSParagraphStyle.body, .font: bodyNoticonFont, .foregroundColor: bodyNoticonColor]
        let italic: Style       = [.paragraphStyle: NSParagraphStyle.body, .font: UIFont.body.italics, .foregroundColor: bodyTextColor]
        let link: Style         = [.foregroundColor: bodyLinkColor]

        return MetadataStyles(regular: regular, bold: bold, blockquote: blockquote, match: match, noticon: noticon, link: link)
    }()


    /// Styles: Notification Defailts / Badge Blocks
    ///
    static let badge: MetadataStyles = {
        let regular: Style      = [.font: UIFont.body, .foregroundColor: bodyTextColor, .paragraphStyle: NSParagraphStyle.badge]

        return MetadataStyles(regular: regular, bold: body.bold, blockquote: body.blockquote, italics: body.italics, link: body.link)
    }()
}
