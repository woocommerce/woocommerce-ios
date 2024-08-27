import SwiftUI
import Experiments
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

    /// SiteID related to the Inbox note.
    private let siteID: Int64

    /// Stores to handle note actions.
    private let stores: StoresManager

    /// Feature Flag Service.
    private let featureFlagService: FeatureFlagService

    /// Whether the row is shown in placeholder state.
    let isPlaceholder: Bool

    /// Indicate if the note was actioned or not (the user did an action, so the note will be considered as read).
    let isRead: Bool

    /// Indicate if the note is a survey or not.
    let isSurvey: Bool

    /// Indicate if the note is actioned or not.
    let isActioned: Bool

    /// Indicate if the call to actions of the Inbox Note Row should be hidden
    var showInboxCTA: Bool {
        featureFlagService.isFeatureFlagEnabled(.showInboxCTA)
    }

    var shouldAuthenticateAdminPage: Bool {
        guard let site = stores.sessionManager.defaultSite else {
            return false
        }
        return stores.shouldAuthenticateAdminPage(for: site)
    }

    init(note: InboxNote,
         today: Date = .init(),
         locale: Locale = .current,
         calendar: Calendar = .current,
         stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        let attributedContent = note.content.htmlToAttributedString
            .addingAttributes([
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
                  actions: actions,
                  siteID: note.siteID,
                  stores: stores,
                  featureFlagService: featureFlagService,
                  isPlaceholder: false,
                  isRead: note.isRead,
                  isSurvey: note.type == "survey",
                  isActioned: note.status == "actioned"
        )
    }

    init(id: Int64,
         date: String,
         title: String,
         attributedContent: NSAttributedString,
         actions: [InboxNoteRowActionViewModel],
         siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         isPlaceholder: Bool,
         isRead: Bool,
         isSurvey: Bool,
         isActioned: Bool) {
        self.id = id
        self.date = date
        self.title = title
        self.attributedContent = attributedContent
        self.actions = actions
        self.siteID = siteID
        self.stores = stores
        self.featureFlagService = featureFlagService
        self.isPlaceholder = isPlaceholder
        self.isRead = isRead
        self.isSurvey = isSurvey
        self.isActioned = isActioned
    }

    static func == (lhs: InboxNoteRowViewModel, rhs: InboxNoteRowViewModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.siteID == rhs.siteID &&
        lhs.isRead == rhs.isRead
    }
}

extension InboxNoteRowViewModel {
    func markInboxNoteAsActioned(actionID: Int64) {
        ServiceLocator.analytics.track(.inboxNoteAction,
                                       withProperties: ["action": "open"])
        let action = InboxNotesAction.markInboxNoteAsActioned(siteID: siteID,
                                                              noteID: id,
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
        ServiceLocator.analytics.track(.inboxNoteAction,
                                       withProperties: ["action": "dismiss"])
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
