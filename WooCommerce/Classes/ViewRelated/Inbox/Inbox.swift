import Combine
import SwiftUI
import Yosemite

/// Shows a list of inbox notes as shown in WooCommerce Admin in core.
struct Inbox: View {
    /// Environment safe areas
    @Environment(\.safeAreaInsets) var safeAreaInsets: EdgeInsets

    /// View model that drives the view.
    @ObservedObject private(set) var viewModel: InboxViewModel
    @State private var showingActionSheet: Bool = false
    @State private var showingDismissAlert: Bool = false

    init(viewModel: InboxViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                switch viewModel.syncState {
                case .results:
                    RefreshableInfiniteScrollList(isLoading: viewModel.shouldShowBottomActivityIndicator,
                                                  loadAction: viewModel.onLoadNextPageAction,
                                                  refreshAction: { completion in
                        viewModel.onRefreshAction(completion: completion)
                    }) {
                        ForEach(viewModel.noteRowViewModels) { rowViewModel in
                            InboxNoteRow(viewModel: rowViewModel)
                        }
                        .background(Constants.listForeground)
                    }
                    .padding(.horizontal, insets: safeAreaInsets)
                    .background(Constants.listForeground)
                case .empty:
                    EmptyState(title: Localization.emptyStateTitle,
                               description: Localization.emptyStateMessage,
                               image: .emptyInboxNotesImage)
                        .frame(maxHeight: .infinity)
                        .padding(insets: safeAreaInsets)
                case .syncingFirstPage:
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(InboxViewModel.placeholderRowViewModels) { rowViewModel in
                                InboxNoteRow(viewModel: rowViewModel)
                                    .redacted(reason: .placeholder)
                                    .shimmering()
                            }
                        }
                    }
                    .padding(.horizontal, insets: safeAreaInsets)
                    .background(Constants.listForeground)
                }
            }
            .ignoresSafeArea(.container, edges: [.horizontal])
            .background(Constants.listBackground.ignoresSafeArea())
            .navigationTitle(Localization.title)
            .onAppear {
                viewModel.onLoadTrigger.send()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.syncState == .results {
                        Button(action: {
                            showingActionSheet = true
                        }, label: {
                            Image(uiImage: .moreImage)
                                .renderingMode(.template)
                        })
                        .confirmationDialog(Localization.title, isPresented: $showingActionSheet) {
                            Button(Localization.dismissAllNotes) {
                                showingDismissAlert = true
                            }
                        }
                    }
                }
            }
            .alert(Localization.dismissAllNotesAlertTitle, isPresented: $showingDismissAlert, actions: {
                Button(Localization.dismissAllNotes) {
                    showingDismissAlert = false
                    viewModel.dismissAllInboxNotes()
                }

                Button(Localization.cancel) {
                    showingDismissAlert = false
                }
            }, message: {
                Text(Localization.dismissAllNotesAlertMessage)
            })
        }
    }
}

private extension Inbox {

    enum Constants {
        static let listForeground: Color = Color(.listForeground(modal: false))
        static let listBackground: Color = Color(.listBackground)
    }

    enum Localization {
        static let title = NSLocalizedString("Inbox", comment: "Title for the screen that shows inbox notes.")
        static let emptyStateTitle = NSLocalizedString("Congrats, you’ve read everything!",
                                                         comment: "This text appears as an empty state title in the Inbox screen when there are no inbox notes/messages to display, congratulating the user for having read all available content.")
        static let emptyStateMessage = NSLocalizedString("Come back soon for more tips and insights on growing your store.",
                                                         comment: "This message appears in the Inbox screen when there are no inbox notes to display, shown below the empty state title 'Congrats, you've read everything!' to encourage users to return later for new content.")
        static let dismissAllNotes = NSLocalizedString("Dismiss All",
                                                              comment: "Dismiss All button in Inbox Notes for dismissing all the notes.")
        static let dismissAllNotesAlertTitle = NSLocalizedString("Dismiss all messages",
                                                         comment: "Title of the alert for dismissing all the inbox notes.")
        static let dismissAllNotesAlertMessage = NSLocalizedString("Are you sure? Inbox messages will be dismissed forever.",
                                                           comment: "This text appears as the message body in a confirmation alert dialog that shows when the user taps 'Dismiss All' in the Inbox screen, asking them to confirm they want to permanently remove all inbox messages.")
        static let cancel = NSLocalizedString(
            "inbox.alert.cancel",
            value: "Cancel",
            comment: "Button to dismiss the confirmation alert on the Inbox screen."
        )
    }
}

#if DEBUG

/// Allows mocking for previewing `Inbox` view.
private final class PreviewInboxNotesStoresManager: DefaultStoresManager {
    private let inboxNotes: [InboxNote]

    init(inboxNotes: [InboxNote], sessionManager: SessionManager = SessionManager.standard) {
        self.inboxNotes = inboxNotes
        super.init(sessionManager: sessionManager)
    }

    // MARK: - Overridden Methods

    override func dispatch(_ action: Action) {
        if let action = action as? InboxNotesAction {
            onInboxNotesAction(action: action)
        } else {
            super.dispatch(action)
        }
    }

    private func onInboxNotesAction(action: InboxNotesAction) {
        switch action {
        case .loadAllInboxNotes(_, _, _, _, _, _, let completion):
            completion(.success(inboxNotes))
            return
        default:
            return
        }
    }
}

extension InboxNote {
    static func placeholder() -> InboxNote {
        .init(siteID: 255,
              id: 0,
              name: "",
              type: "",
              status: "",
              actions: [.init(id: 0, name: "", label: "Accept Apple Pay", status: "", url: "https://wordpress.com")],
              title: "Boost sales this holiday season with Apple Pay!",
              content: "",
              isRemoved: false,
              isRead: false,
              dateCreated: .init())
    }
}

struct Inbox_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Placeholder state.
            Inbox(viewModel: .init(siteID: 122))
                .preferredColorScheme(.light)
            Inbox(viewModel: .init(siteID: 122))
                .preferredColorScheme(.dark)
            // Empty state.
            Inbox(viewModel: .init(siteID: 322,
                                   stores: PreviewInboxNotesStoresManager(inboxNotes: [])))
                .preferredColorScheme(.light)
            Inbox(viewModel: .init(siteID: 322,
                                   stores: PreviewInboxNotesStoresManager(inboxNotes: [])))
                .preferredColorScheme(.dark)
            // Results state.
            Inbox(viewModel: .init(siteID: 322,
                                   stores: PreviewInboxNotesStoresManager(inboxNotes: [.placeholder(), .placeholder()])))
                .preferredColorScheme(.light)
            Inbox(viewModel: .init(siteID: 322,
                                   stores: PreviewInboxNotesStoresManager(inboxNotes: [.placeholder(), .placeholder()])))
                .preferredColorScheme(.dark)
        }
    }
}

#endif
