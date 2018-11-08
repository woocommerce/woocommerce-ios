import Foundation
import UIKit
import Yosemite


// MARK: - NotificationDetailsViewController
//
class NotificationDetailsViewController: UIViewController {

    /// Main TableView
    ///
    @IBOutlet private var tableView: UITableView!

    /// Note to be displayed!
    ///
    private var note: Note!

    /// Designated Initializer
    ///
    init(note: Note) {
        self.note = note
        super.init(nibName: nil, bundle: nil)
    }

    /// Required!
    ///
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        assert(note != nil, "Please use the designated initializer!")
    }


    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationItem()
        configureMainView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
}


// MARK: - User Interface Initialization
//
private extension NotificationDetailsViewController {

    /// Setup: Navigation
    ///
    func configureNavigationItem() {
        title = note.title

        // Don't show the Notifications title in the next-view's back button
        let backButton = UIBarButtonItem(title: String(), style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backButton
    }

    /// Setup: Main View
    ///
    func configureMainView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }
}


// TODO: Footer

//
//
enum NoteDetailsRow {
    case header(gravatar: NoteBlock, snippet: NoteBlock?)

    case user(user: NoteBlock)

    case comment(comment: NoteBlock, user: NoteBlock)
    case actions(comment: NoteBlock)

    case text(text: NoteBlock)
    case image(text: NoteBlock)
    case footer(text: NoteBlock)
}

//
//
extension NoteDetailsRow {

    ///
    ///
    func details(from note: Note) -> [NoteDetailsRow] {
        return [
            headerDetailRows(from: note),
            commentDetailRows(from: note) ?? regularDetailRows(from: note)
        ].flatMap { $0 }
    }


    /// Header: .image + Optional(.text)
    ///
    private func headerDetailRows(from note: Note) -> [NoteDetailsRow] {
        guard let gravatar = note.header.first(ofKind: .image) else {
            return []
        }

        let snippet = note.header.first(ofKind: .text)
        return [
            .header(gravatar: gravatar, snippet: snippet)
        ]
    }

    /// Comment: .comment + .user + .actions
    ///
    private func commentDetailRows(from note: Note) -> [NoteDetailsRow]? {
        guard let comment = note.body.first(ofKind: .comment), let user = note.body.first(ofKind: .user) else {
            return nil
        }

        return [
            .comment(comment: comment, user: user),
            .actions(comment: comment)
        ]
    }

    ///
    ///
    private func regularDetailRows(from note: Note) -> [NoteDetailsRow] {
        return note.body.compactMap { block -> NoteDetailsRow? in
            switch block.kind {
            case .comment:
                return nil
            case .image:
                return .image(text: block)
            case .text:
                return .text(text: block)
            case .user:
                return .user(user: block)
            }
        }
    }
}



//  KIND
//    case comment:         [Header, Comment, Footer, Actions]
//
//    case commentLike      [Header, Users...]
//    case like             [Header, Users...]
//    case follow           [Header, Users...]
//    case storeOrder       [Image, Text, Text, Text, Text]
//
//  READER
//    case automattcher     [Header, Post??]
//    case newPost          [Header, Post??]
//    case post             ??
//    case user             ??



//  CELLS
//      NoteBlockHeaderTableViewCell
//      NoteBlockTextTableViewCell where .kind == .footer
//      NoteBlockUserTableViewCell
//      NoteBlockCommentTableViewCell
//      NoteBlockActionsTableViewCell
//      NoteBlockImageTableViewCell
//      NoteBlockTextTableViewCell



//  COMMENT
//    guard let comment = blockOfKind(.comment, from: blocks), let user = blockOfKind(.user, from: blocks) else {
//        return []
//    }
//
//    let commentGroupBlocks  = [comment, user]
//    let middleGroupBlocks   = blocks.filter { return commentGroupBlocks.contains($0) == false }
//    let actionGroupBlocks   = [comment]
