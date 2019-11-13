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

    /// Returns the icon tint color to be used for this note
    ///
    var noticonTintColor: UIColor {
        guard kind == .storeOrder else {
            return .listIcon
        }
        return .accent
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

    /// Returns the Associated Product (Name + URL), if any.
    ///
    var product: (name: String, url: URL)? {
        guard subkind == .storeReview, let block = body.first(ofKind: .text), let text = block.text else {
            return nil
        }

        let ranges: [(name: String, url: URL)] = block.ranges.compactMap { range in
            guard let swiftRange = Range(range.range, in: text), let url = range.url else {
                return nil
            }

            let name = String(text[swiftRange])
            return (name, url)
        }

        return ranges.first {
            return $0.name.contains(Constants.filledInStar) == false && $0.name.contains(Constants.emptyStar) == false
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
