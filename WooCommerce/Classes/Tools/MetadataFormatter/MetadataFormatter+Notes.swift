import Foundation
import Networking


/// MetadataFormatter: Notifications Convenience Methods
///
extension MetadataFormatter {

    /// Returns an AttributedString representation of a given NoteBlock, with the specified Styles applied to it.
    ///
    func format(block: NoteBlock, with styles: MetadataStyles) -> NSAttributedString {
        guard let text = block.text else {
            return NSAttributedString()
        }

        return format(text: text, with: styles, using: block.ranges as [MetadataDescriptor])
    }
}


/// NoteRange: MetadataDescriptor Conformance
///
extension NoteRange: MetadataDescriptor {

    /// Returns the TextStyles that should be applied over the receiver instance.
    ///
    func attributes(from styles: MetadataStyles) -> [NSAttributedString.Key: Any]? {
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
