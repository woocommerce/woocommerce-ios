import Foundation
import Yosemite

// MARK: - NoteDetailsRow: Map to different UITableView Cells.
//
enum NoteDetailsRow {
    case header(gravatar: NoteBlock, snippet: NoteBlock?)
    case headerPlain(title: String, url: URL)
    case comment(comment: NoteBlock, user: NoteBlock, footer: NoteBlock?)

    // Note: As of Mark 1, we only support Comment Rows. Uncomment when the time comes!
    //
    //    case image(image: NoteBlock)
    //    case text(text: NoteBlock)
    //    case user(user: NoteBlock)
}


// MARK: - Helpers
//
extension NoteDetailsRow {

    /// Returns the UITableView reuseIdentifier.
    ///
    var reuseIdentifier: String {
        switch self {
        case .header:
            return NoteDetailsHeaderTableViewCell.reuseIdentifier
        case .headerPlain:
            return NoteDetailsHeaderPlainTableViewCell.reuseIdentifier
        case .comment:
            return NoteDetailsCommentTableViewCell.reuseIdentifier
        }
    }
}


// MARK: - Builders
//
extension NoteDetailsRow {

    /// Returns a collection of NoteDetailsRow(s) that represent a given Notification's Header + Body.
    /// Each one of the returned DetailsRow is meant to be mapped to a single UI component.
    ///
    static func details(from note: Note) -> [NoteDetailsRow] {
        return [
            headerDetailRows(from: note.header),
            headerDetailRowsForStoreReview(for: note),
            commentDetailRows(from: note.body) ?? regularDetailRows(from: note.body),
        ].flatMap { $0 }
    }


    /// Returns an array containing a single NoteDetailsRow, representing a given collection of Header Blocks.
    ///
    private static func headerDetailRows(from blocks: [NoteBlock]) -> [NoteDetailsRow] {
        guard let gravatar = blocks.first(ofKind: .image) else {
            return []
        }

        // Note: Snippet Block is actually optional!
        return [
            .header(gravatar: gravatar, snippet: blocks.first(ofKind: .text)),
        ]
    }

    /// Returns an array containing a Header Plain row, whenever:
    ///
    /// A. We're dealing with a Store Review Notification
    /// B. There are no actual Header Blocks
    ///
    /// This is meant to be a temporary workaround, client side. Please remove whenever a proper Header is added, backend side.
    ///
    private static func headerDetailRowsForStoreReview(for note: Note) -> [NoteDetailsRow] {
        guard note.subkind == .storeReview, note.header.isEmpty, let product = note.product else {
            return []
        }

        return [
            .headerPlain(title: product.name, url: product.url),
        ]
    }

    /// Returns an array containing a single NoteDetailsRow of the `.comment` type, whenever the specified collection of
    /// Body Blocks contain the "Comment Payload".
    ///
    /// A proper Comment Notification is expected to contain the following body blocks: [.comment, .user, Optional(.text)]
    /// Whenever such criteria isn't met, this method returns nil.
    ///
    private static func commentDetailRows(from blocks: [NoteBlock]) -> [NoteDetailsRow]? {
        guard let comment = blocks.first(ofKind: .comment), let user = blocks.first(ofKind: .user) else {
            return nil
        }

        // Note: Footer Block is actually optional!
        return [
            .comment(comment: comment, user: user, footer: blocks.first(ofKind: .text)),
        ]
    }


    /// Returns a collection of NoteDetailsRow(s) that represent a given collection of Body Blocks.
    /// Supported Block Types:  [.image | .text | .user]
    ///
    /// Note: You must first call `commentDetailRows`. If such method returns *nil*, then the Body Blocks are assumed *not*
    /// to represent a Comment (in such case: those blocks are expected to be "regular blocks").
    ///
    private static func regularDetailRows(from blocks: [NoteBlock]) -> [NoteDetailsRow] {
        return []

        // Note: As of Mark 1, we only support Comment Rows. Uncomment when the time comes!
        //
        //        return blocks.compactMap { block -> NoteDetailsRow? in
        //            switch block.kind {
        //            case .image:
        //                return .image(image: block)
        //            case .text:
        //                return .text(text: block)
        //            case .user:
        //                return .user(user: block)
        //            default:
        //                return nil
        //            }
        //        }
    }
}
