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
        // Anchor the action sheet at the top to be able to show the popover on iPad in the most appropriate position
        Divider()
            .actionSheet(isPresented: $showingActionSheet) {
                ActionSheet(
                    title: Text(Localization.title),
                    buttons: [
                        .default(Text(Localization.dismissAllNotes), action: {
                            showingDismissAlert = true
                        }),
                        .cancel()
                    ]
                )
            }
            .alert(isPresented: $showingDismissAlert) {
                return Alert(title: Text(Localization.dismissAllNotesAlertTitle),
                             message: Text(Localization.dismissAllNotesAlertMessage),
                             primaryButton: .default(Text(Localization.dismissAllNotes), action: viewModel.dismissAllInboxNotes),
                             secondaryButton: .cancel())
            }

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
                        ForEach(viewModel.placeholderRowViewModels) { rowViewModel in
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
        .ignoresSafeArea()
        .background(Constants.listBackground.ignoresSafeArea())
        .navigationTitle(Localization.title)
        .onAppear {
            viewModel.onLoadTrigger.send()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingActionSheet = true
                }, label: {
                    Image(uiImage: .moreImage)
                        .renderingMode(.template)
                })
                    .renderedIf(viewModel.syncState == .results)
            }
        }
    }
}

private extension Inbox {

    enum Constants {
        static let listForeground: Color = Color(.listForeground)
        static let listBackground: Color = Color(.listBackground)
    }

    enum Localization {
        static let title = NSLocalizedString("Inbox", comment: "Title for the screen that shows inbox notes.")
        static let emptyStateTitle = NSLocalizedString("Congrats, you’ve read everything!",
                                                         comment: "Title displayed if there are no inbox notes in the inbox screen.")
        static let emptyStateMessage = NSLocalizedString("Come back soon for more tips and insights on growing your store",
                                                         comment: "Message displayed if there are no inbox notes to display in the inbox screen.")
        static let dismissAllNotes = NSLocalizedString("Dismiss All",
                                                              comment: "Dismiss All button in Inbox Notes for dismissing all the notes.")
        static let dismissAllNotesAlertTitle = NSLocalizedString("Dismiss all messages",
                                                         comment: "Title of the alert for dismissing all the inbox notes.")
        static let dismissAllNotesAlertMessage = NSLocalizedString("Are you sure? Inbox messages will be dismissed forever.",
                                                           comment: "Message displayed in the alert for dismissing all the inbox notes.")
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
