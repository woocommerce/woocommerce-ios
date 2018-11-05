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
    static let subject: StringStyles = {
        let regular: Style      = [.paragraphStyle: NSParagraphStyle.subheadline, .font: UIFont.subheadline, .foregroundColor: NukeMe.subjectTextColor]
        let bold: Style         = [.paragraphStyle: NSParagraphStyle.subheadline, .font: UIFont.subheadline.bold]
        let blockquote: Style   = [.paragraphStyle: NSParagraphStyle.subheadline, .font: UIFont.subheadline.italics, .foregroundColor: NukeMe.subjectBlockquotedColor]
        let italics: Style      = [.paragraphStyle: NSParagraphStyle.subheadline, .font: UIFont.subheadline.italics]
        let noticon: Style      = [.paragraphStyle: NSParagraphStyle.subheadline, .font: UIFont.noticon(forStyle: .body), .foregroundColor: NukeMe.subjectNoticonColor]

        return StringStyles(regular: regular, bold: bold, blockquote: blockquote, italics: italics, match: nil, noticon: noticon)
    }()


    /// Styles: Notifications List / Snippet Block
    ///
    static let snippet: StringStyles = {
        let regular: Style      = [.paragraphStyle: NSParagraphStyle.subheadline, .font: UIFont.subheadline, .foregroundColor: NukeMe.snippetColor]

        return StringStyles(regular: regular)
    }()


    /// Styles: Notification Defailts / Header Block
    ///
    static let header: StringStyles = {
        let regular: Style      = [.font: UIFont.body, .foregroundColor: NukeMe.bodyTextColor]
        let bold: Style         = [.font: UIFont.body.bold, .foregroundColor: NukeMe.bodyTextColor]
        let italics: Style      = [.font: UIFont.body.italics, .foregroundColor: NukeMe.headerItalicsColor]

        return StringStyles(regular: regular, bold: bold, italics: italics)
    }()


    /// Styles: Notification Defailts / Footer Block
    ///
    static let footer: StringStyles = {
        let regular: Style      = [.paragraphStyle: NSParagraphStyle.body, .font: UIFont.body, .foregroundColor: NukeMe.footerTextColor]

        return StringStyles(regular: regular, noticon: body.noticon)
    }()


    /// Styles: Notification Defailts / Body Blocks
    ///
    static let body: StringStyles = {
        let regular: Style      = [.paragraphStyle: NSParagraphStyle.body, .font: UIFont.body, .foregroundColor: NukeMe.bodyTextColor]
        let bold: Style         = [.paragraphStyle: NSParagraphStyle.body, .font: UIFont.body.bold, .foregroundColor: NukeMe.bodyTextColor]
        let blockquote: Style   = [.paragraphStyle: NSParagraphStyle.body, .font: UIFont.body.italics, .foregroundColor: NukeMe.bodyBlockquotedColor]
        let match: Style        = [.paragraphStyle: NSParagraphStyle.body, .font: UIFont.body.bold, .foregroundColor: NukeMe.bodyLinkColor]
        let noticon: Style      = [.paragraphStyle: NSParagraphStyle.body, .font: UIFont.noticon(forStyle: .body), .foregroundColor: NukeMe.bodyNoticonColor]
        let italic: Style       = [.paragraphStyle: NSParagraphStyle.body, .font: UIFont.body.italics, .foregroundColor: NukeMe.bodyTextColor]
        let link: Style         = [.foregroundColor: NukeMe.bodyLinkColor]

        return StringStyles(regular: regular, bold: bold, blockquote: blockquote, match: match, noticon: noticon, link: link)
    }()
}


// MARK: - TODO: Nuke this. Map the Colors, as required, from the StyleManager
//
private struct NukeMe {
    static let subjectTextColor = UIColor.black
    static let subjectNoticonColor = UIColor.black
    static let subjectBlockquotedColor = UIColor.black
    static let snippetColor = UIColor.black

    static let headerItalicsColor = UIColor.gray

    static let bodyTextColor = UIColor.black
    static let bodyBlockquotedColor = UIColor.black
    static let bodyLinkColor = UIColor.black
    static let bodyNoticonColor = UIColor.black

    static let footerTextColor = UIColor.black
}
