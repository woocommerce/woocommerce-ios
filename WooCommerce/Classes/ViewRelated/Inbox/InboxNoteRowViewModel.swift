import Yosemite

/// View model for `InboxNoteRow`.
struct InboxNoteRowViewModel: Identifiable {
    let id: Int64
    let title: String

    let actions: [InboxNoteRowActionViewModel]

    init(note: InboxNote) {
        let actions = note.actions.map { InboxNoteRowActionViewModel(action: $0) }
        self.init(id: note.id,
                  title: note.title,
                  actions: actions)
    }

    init(id: Int64, title: String, actions: [InboxNoteRowActionViewModel]) {
        self.id = id
        self.title = title
        self.actions = actions
    }
}

/// View model for an action in `InboxNoteRow`.
struct InboxNoteRowActionViewModel: Identifiable {
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
