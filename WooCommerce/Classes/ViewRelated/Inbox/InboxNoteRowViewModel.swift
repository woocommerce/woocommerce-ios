import SwiftUI
import Yosemite
import protocol Storage.StorageManagerType

/// View model for `InboxNoteRow`.
struct InboxNoteRowViewModel: Identifiable, Equatable {
    let id: Int64

    /// Relative date when the note was created.
    let date: String

    /// Icon for the note type (e.g. marketing, info).
    let typeIcon: Image

    /// Title of the note.
    let title: String

    /// HTML note content.
    let attributedContent: NSAttributedString

    /// Actions for the note.
    let actions: [InboxNoteRowActionViewModel]

    /// SiteID related to the Inbox note.
    private let siteID: Int64

    /// Stores to handle note actions.
    private let stores: StoresManager

    init(note: InboxNote,
         today: Date = .init(),
         locale: Locale = .current,
         calendar: Calendar = .current,
         stores: StoresManager = ServiceLocator.stores) {
        let attributedContent = note.content.htmlToAttributedString
            .addingAttributes([
                .font: UIFont.body,
                .foregroundColor: UIColor.secondaryLabel
            ])
        let date: String = {
            let formatter = RelativeDateTimeFormatter()
            formatter.locale = locale
            formatter.calendar = calendar
            formatter.dateTimeStyle = .named
            return formatter.localizedString(for: note.dateCreated, relativeTo: today)
        }()
        let actions = note.actions.map { InboxNoteRowActionViewModel(action: $0) }

        self.init(id: note.id,
                  date: date,
                  typeIcon: (NoteType(rawValue: note.type) ?? .info).image,
                  title: note.title,
                  attributedContent: attributedContent,
                  actions: actions,
                  siteID: note.siteID,
                  stores: stores)
    }

    init(id: Int64,
         date: String,
         typeIcon: Image,
         title: String,
         attributedContent: NSAttributedString, actions: [InboxNoteRowActionViewModel],
         siteID: Int64,
         stores: StoresManager = ServiceLocator.stores) {
        self.id = id
        self.date = date
        self.typeIcon = typeIcon
        self.title = title
        self.attributedContent = attributedContent
        self.actions = actions
        self.siteID = siteID
        self.stores = stores
    }

    static func == (lhs: InboxNoteRowViewModel, rhs: InboxNoteRowViewModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.siteID == rhs.siteID
    }
}

extension InboxNoteRowViewModel {
    func markInboxNoteAsActioned(actionID: Int64) {
        let action = InboxNotesAction.markInboxNoteAsActioned(siteID: siteID,
                                                              noteID: actionID,
                                                              actionID: actionID) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                DDLogError("⛔️ Error on mark inbox note as actioned: \(error)")
            }
        }
        stores.dispatch(action)
    }

    func dismissInboxNote(onCompletion: @escaping (Result<Void, Error>) -> Void) {
        let action = InboxNotesAction.dismissInboxNote(siteID: siteID, noteID: id) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                DDLogError("⛔️ Error on dismissing an inbox note: \(error)")
            }
            onCompletion(result)
        }
        stores.dispatch(action)
    }
}

private extension InboxNoteRowViewModel {
    enum NoteType: String {
        case error
        case warning
        case update
        case info
        case marketing
        case survey

        var image: Image {
            switch self {
            case .error:
                return Image(systemName: "exclamationmark.octagon.fill")
            case .warning:
                return Image(systemName: "exclamationmark.bubble.fill")
            case .update:
                return Image(systemName: "gearshape.fill")
            case .info:
                return Image(uiImage: .infoImage)
            case .marketing:
                return Image(systemName: "lightbulb.fill")
            case .survey:
                return Image(systemName: "doc.plaintext")
            }
        }
    }
}

/// View model for an action in `InboxNoteRow`.
struct InboxNoteRowActionViewModel: Identifiable, Equatable {
    let id: Int64
    let title: String
    let url: URL?

    init(action: InboxAction) {
        let url = URL(string: action.url)
        self.init(id: action.id, title: action.label, url: url)
    }

    init(id: Int64, title: String, url: URL?) {
        self.id = id
        self.title = title
        self.url = url
    }
}
