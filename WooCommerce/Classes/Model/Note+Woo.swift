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

        return block.text?.filter({ Constants.filledInStar.contains($0) }).count
    }

    /// Returns the Product Name String
    ///
    var product: String? {
        guard subkind == .storeReview, let block = body.first(ofKind: .text), let text = block.text else {
            return nil
        }

        let substrings = block.ranges.compactMap { range -> String? in
            guard let swiftRange = Range(range.range, in: text) else {
                return nil
            }

            return String(text[swiftRange])
        }

        return substrings.first {
            $0.contains(Constants.filledInStar) == false && $0.contains(Constants.filledInStar) == false
        }
    }
}


// MARK: - Constants!
//
private extension Note {
    enum Constants {
        static let filledInStar = "\u{2605}"  // Unicode Black Star ★
        static let emptyStar    = "\u{2606}"  // Unicode White Star ☆
    }
}
