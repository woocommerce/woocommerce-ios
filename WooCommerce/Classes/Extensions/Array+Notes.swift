import Foundation
import Networking


/// Extension: [Array of NoteBlock Elements]
///
extension Array where Element == Networking.NoteBlock {

    /// Returns the first NoteBlock of the given kind.
    ///
    func first(ofKind kind: NoteBlock.Kind) -> NoteBlock? {
        return first { $0.kind == kind }
    }
}
