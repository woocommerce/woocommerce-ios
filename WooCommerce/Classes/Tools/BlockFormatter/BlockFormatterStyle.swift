import Foundation
import UIKit
import Networking

// TODO:
// - Nuke Networking Dependency (BlockFormatterStyles / BlockFormatter)
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


/// BlockFormatterStyles: Defines a collection of Styles to be applied over a Block.
///
struct BlockFormatterStyles {

    /// Attributed String's Style (convenience) Alias.
    ///
    typealias Style = [NSAttributedString.Key: Any]

    /// Style to be applied over the entire text.
    ///
    let regular: Style

    /// Bold: Ranges = [user]
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

    /// Link Color!
    ///
    let linkColor: UIColor?


    /// Designated Initializer.
    ///
    init(regular: Style, bold: Style? = nil, blockquote: Style? = nil, italics: Style? = nil, match: Style? = nil, noticon: Style? = nil, linkColor: UIColor? = nil) {
        self.regular = regular
        self.bold = bold
        self.blockquote = blockquote
        self.italics = italics
        self.match = match
        self.noticon = noticon
        self.linkColor = linkColor
    }

    /// Returns the target Style for a given NoteRange.Kind
    ///
    func attributes(for kind: NoteRange.Kind) -> Style? {
        switch kind {
        case .blockquote:   return blockquote
        case .comment:      return italics
        case .match:        return match
        case .noticon:      return noticon
        case .post:         return italics
        case .user:         return bold
        default:            return nil
        }
    }
}


// MARK: - Default Styles
//
extension BlockFormatterStyles {

    /// Subject: Notifications List / Subject Block
    ///
    static let subject: BlockFormatterStyles = {
        let regular: Style      = [.paragraphStyle: NSParagraphStyle.subheadline, .font: UIFont.subheadline, .foregroundColor: subjectTextColor]
        let bold: Style         = [.paragraphStyle: NSParagraphStyle.subheadline, .font: UIFont.subheadline.bold]
        let blockquote: Style   = [.paragraphStyle: NSParagraphStyle.subheadline, .font: UIFont.subheadline.italics, .foregroundColor: subjectBlockquotedColor]
        let italics: Style      = [.paragraphStyle: NSParagraphStyle.subheadline, .font: UIFont.subheadline.italics]
        let noticon: Style      = [.paragraphStyle: NSParagraphStyle.subheadline, .font: bodyNoticonFont, .foregroundColor: subjectNoticonColor]

        return BlockFormatterStyles(regular: regular, bold: bold, blockquote: blockquote, italics: italics, match: nil, noticon: noticon)
    }()


    /// Subject: Notifications List / Snippet Block
    ///
    static let snippet: BlockFormatterStyles = {
        let regular: Style      = [.paragraphStyle: NSParagraphStyle.subheadline, .font: UIFont.subheadline, .foregroundColor: snippetColor]

        return BlockFormatterStyles(regular: regular)
    }()


    /// Subject: Notification Defailts / Header Block
    ///
    static let header: BlockFormatterStyles = {
        let regular: Style      = [.font: UIFont.body, .foregroundColor: bodyTextColor]
        let bold: Style         = [.font: UIFont.body.bold, .foregroundColor: bodyTextColor]
        let italics: Style      = [.font: UIFont.body.italics, .foregroundColor: headerItalicsColor]

        return BlockFormatterStyles(regular: regular, bold: bold, italics: italics)
    }()


    /// Subject: Notification Defailts / Footer Block
    ///
    static let footer: BlockFormatterStyles = {
        let regular: Style      = [.paragraphStyle: NSParagraphStyle.body, .font: UIFont.body, .foregroundColor: footerTextColor]

        return BlockFormatterStyles(regular: regular, noticon: body.noticon)
    }()


    /// Subject: Notification Defailts / Body Blocks
    ///
    static let body: BlockFormatterStyles = {
        let regular: Style      = [.paragraphStyle: NSParagraphStyle.body, .font: UIFont.body, .foregroundColor: bodyTextColor]
        let bold: Style         = [.paragraphStyle: NSParagraphStyle.body, .font: UIFont.body.bold, .foregroundColor: bodyTextColor]
        let blockquote: Style   = [.paragraphStyle: NSParagraphStyle.body, .font: UIFont.body.italics, .foregroundColor: bodyBlockquotedColor]
        let match: Style        = [.paragraphStyle: NSParagraphStyle.body, .font: UIFont.body.bold, .foregroundColor: bodyLinkColor]
        let noticon: Style      = [.paragraphStyle: NSParagraphStyle.body, .font: bodyNoticonFont, .foregroundColor: bodyNoticonColor]
        let italic: Style       = [.paragraphStyle: NSParagraphStyle.body, .font: UIFont.body.italics, .foregroundColor: bodyTextColor]

        return BlockFormatterStyles(regular: regular, bold: bold, blockquote: blockquote, match: match, noticon: noticon, linkColor: bodyLinkColor)
    }()


    /// Subject: Notification Defailts / Badge Blocks
    ///
    static let badge: BlockFormatterStyles = {
        let regular: Style      = [.font: UIFont.body, .foregroundColor: bodyTextColor, .paragraphStyle: NSParagraphStyle.badge]

        return BlockFormatterStyles(regular: regular, bold: body.bold, blockquote: body.blockquote, italics: body.italics, linkColor: body.linkColor)
    }()
}
