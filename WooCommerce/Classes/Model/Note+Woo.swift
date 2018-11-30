import Foundation
import Yosemite


// MARK: - Note Helper Methods
//
extension Note {

    /// Returns the Subject Block
    ///
    var blockForSubject: NoteBlock? {
        return subject.first
    }

    /// Returns the Snippet Block
    ///
    var blockForSnippet: NoteBlock? {
        guard let snippet = subject.last, subject.count > 1 else {
            return nil
        }

        return snippet
    }

    /// Returns the number of stars for a review (or nil if the Note is not a review)
    ///
    var starRating: Int? {
        guard subkind == .storeReview else {
            return nil
        }
        guard let block = body.first(ofKind: .text) else {
            return nil
        }

        return block.text?.filter({ "\u{2605}".contains($0) }).count
    }
}
