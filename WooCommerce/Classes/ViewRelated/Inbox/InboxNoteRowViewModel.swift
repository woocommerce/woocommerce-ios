import Yosemite

/// View model for `InboxNoteRow`.
struct InboxNoteRowViewModel: Identifiable, Equatable {
    let id: Int64
    let title: String

    /// HTML note content.
    let attributedContent: NSAttributedString

    let actions: [InboxNoteRowActionViewModel]

    init(note: InboxNote) {
        let attributedContent = note.content.htmlToAttributedString
            .addingAttributes([
                .font: UIFont.body,
                .foregroundColor: UIColor.secondaryLabel
            ])
        let actions = note.actions.map { InboxNoteRowActionViewModel(action: $0) }
        self.init(id: note.id,
                  title: note.title,
                  attributedContent: attributedContent,
                  actions: actions)
    }

    init(id: Int64, title: String, attributedContent: NSAttributedString, actions: [InboxNoteRowActionViewModel]) {
        self.id = id
        self.title = title
        self.attributedContent = attributedContent
        self.actions = actions
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
