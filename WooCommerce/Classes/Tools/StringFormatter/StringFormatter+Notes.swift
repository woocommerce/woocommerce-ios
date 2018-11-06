import Foundation
import Networking


/// StringFormatter: Notifications Convenience Methods
///
extension StringFormatter {

    /// Returns an AttributedString representation of a given NoteBlock, with the specified Styles applied to it.
    /// For convenience's sake, Newlines [Leading, Trailing] will also be trimmed in this spot.
    ///
    func format(block: NoteBlock, with styles: StringStyles) -> NSAttributedString {
        guard let text = block.text else {
            return NSAttributedString()
        }

        return format(text: text, with: styles, using: block.ranges as [StringDescriptor]).trimNewlines()
    }
}


/// NoteRange: StringDescriptor Conformance
///
extension NoteRange: StringDescriptor {

    /// Returns the TextStyles that should be applied over the receiver instance.
    ///
    func attributes(from styles: StringStyles) -> [NSAttributedString.Key: Any]? {
        switch kind {
        case .blockquote:   return styles.blockquote
        case .comment:      return styles.italics
        case .match:        return styles.match
        case .noticon:      return styles.noticon
        case .post:         return styles.italics
        case .user:         return styles.bold
        default:            return nil
        }
    }
}
