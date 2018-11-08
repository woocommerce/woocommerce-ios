import Foundation
import Yosemite


// MARK: - NoteDetailsRow
//
enum NoteDetailsRow {
    case header(gravatar: NoteBlock, snippet: NoteBlock?)
    case comment(comment: NoteBlock, user: NoteBlock, footer: NoteBlock?)
    case image(image: NoteBlock)
    case text(text: NoteBlock)
    case user(user: NoteBlock)
}


// MARK: - Helpers
//
extension NoteDetailsRow {

    /// Returns a collection of NoteDetailsRow(s) that represent a given Notification's Header + Body.
    /// Each one of the returned DetailsRow is meant to be mapped to a single UI component.
    ///
    func details(from note: Note) -> [NoteDetailsRow] {
        return [
            headerDetailRows(from: note.header),
            commentDetailRows(from: note.body) ?? regularDetailRows(from: note.body)
        ].flatMap { $0 }
    }


    /// Returns an array containing a single NoteDetailsRow, representing a given collection of Header Blocks.
    ///
    private func headerDetailRows(from blocks: [NoteBlock]) -> [NoteDetailsRow] {
        guard let gravatar = blocks.first(ofKind: .image) else {
            return []
        }

        // Note: Snippet is actually optional!
        return [
            .header(gravatar: gravatar, snippet: blocks.first(ofKind: .text))
        ]
    }


    /// Returns an array containing a single NoteDetailsRow of the `.comment` type, whenever the specified collection of
    /// Body Blocks contain the "Comment Payload".
    ///
    /// A proper Comment Notification is expected to contain the following body blocks: [.comment, .user, Optional(.text)]
    /// Whenever such criteria isn't met, this method returns nil.
    ///
    private func commentDetailRows(from blocks: [NoteBlock]) -> [NoteDetailsRow]? {
        guard let comment = blocks.first(ofKind: .comment), let user = blocks.first(ofKind: .user) else {
            return nil
        }

        // Note: Footer is actually optional!
        return [
            .comment(comment: comment, user: user, footer: blocks.first(ofKind: .text))
        ]
    }


    /// Returns a collection of NoteDetailsRow(s) that represent a given collection of Body Blocks.
    /// Supported Block Types:  [.image | .text | .user]
    ///
    /// Note: You must first call `commentDetailRows`. If such method returns *nil*, then the Body Blocks are assumed *not*
    /// to represent a Comment (in such case: those blocks are expected to be "regular blocks").
    ///
    private func regularDetailRows(from blocks: [NoteBlock]) -> [NoteDetailsRow] {
        return blocks.compactMap { block -> NoteDetailsRow? in
            switch block.kind {
            case .image:    return .image(image: block)
            case .text:     return .text(text: block)
            case .user:     return .user(user: block)
            case .comment:  return nil
            }
        }
    }
}
