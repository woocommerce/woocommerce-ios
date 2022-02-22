import SwiftUI
import Yosemite

/// View model for `InboxNoteRow`.
struct InboxNoteRowViewModel: Identifiable, Equatable {
    let id: Int64

    /// Relative date when the note was created.
    let date: String

    /// Title of the note.
    let title: String

    /// HTML note content.
    let attributedContent: NSAttributedString

    /// Actions for the note.
    let actions: [InboxNoteRowActionViewModel]

    init(note: InboxNote, today: Date = .init(), locale: Locale = .current, calendar: Calendar = .current) {
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
                  title: note.title,
                  attributedContent: attributedContent,
                  actions: actions)
    }

    init(id: Int64, date: String, title: String, attributedContent: NSAttributedString, actions: [InboxNoteRowActionViewModel]) {
        self.id = id
        self.date = date
        self.title = title
        self.attributedContent = attributedContent
        self.actions = actions
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
