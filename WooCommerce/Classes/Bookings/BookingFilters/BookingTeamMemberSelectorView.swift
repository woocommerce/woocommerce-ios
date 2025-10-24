import SwiftUI
import Yosemite

struct BookingTeamMemberSelectorView: View {
    @ObservedObject private var viewModel: BookingTeamMemberSelectorViewModel
    @State var selectedMember: BookingResource?

    private let onSelection: (BookingResource?) -> Void

    init(viewModel: BookingTeamMemberSelectorViewModel,
         selectedMember: BookingResource?,
         onSelection: @escaping (BookingResource?) -> Void) {
        self.viewModel = viewModel
        self.selectedMember = selectedMember
        self.onSelection = onSelection
    }

    var body: some View {
        VStack {
            switch viewModel.syncState {
            case .empty:
                emptyStateView
            case .syncingFirstPage:
                loadingView
            case .results:
                resourceList(with: viewModel.resources,
                             onNextPage: { viewModel.onLoadNextPageAction() })
            }
        }
        .task {
            viewModel.loadResources()
        }
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedMember) { _, newValue in
            onSelection(newValue)
        }
    }
}

private extension BookingTeamMemberSelectorView {
    var loadingView: some View {
        VStack {
            Spacer()
            ProgressView().progressViewStyle(.circular)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }

    func resourceList(with members: [BookingResource],
                      onNextPage: @escaping () -> Void) -> some View {
        List {
            optionRow(text: Localization.any,
                      isSelected: selectedMember == nil,
                      onSelection: {  selectedMember = nil })

            ForEach(members, id: \.resourceID) { member in
                optionRow(text: member.name,
                          isSelected: member == selectedMember,
                          onSelection: { selectedMember = member})
            }

            InfiniteScrollIndicator(showContent: viewModel.shouldShowBottomActivityIndicator)
                .padding(.top, Layout.viewPadding)
                .onAppear {
                    onNextPage()
                }
        }
        .listStyle(.plain)
        .background(Color(.listBackground))
    }

    func optionRow(text: String, isSelected: Bool, onSelection: @escaping () -> Void) -> some View {
        HStack {
            Text(text)
            Spacer()
            Image(systemName: "checkmark")
                .font(.body.weight(.medium))
                .foregroundStyle(Color.accentColor)
                .renderedIf(isSelected)
        }
        .tappable {
            onSelection()
        }
        .listRowBackground(Color(.listForeground(modal: false)))
    }

    var emptyStateView: some View {
        VStack {
            Spacer()
            Text(Localization.noMembersFound)
                .secondaryBodyStyle()
            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, Layout.viewPadding)
        .background(Color(.systemBackground))
    }
}

private extension BookingTeamMemberSelectorView {
    enum Layout {
        static let viewPadding: CGFloat = 16
    }

    enum Localization {
        static let title = NSLocalizedString(
            "bookingTeamMemberSelectorView.title",
            value: "Team member",
            comment: "Title of the booking team member selector view"
        )
        static let any = NSLocalizedString(
            "bookingTeamMemberSelectorView.any",
            value: "Any",
            comment: "Option to select no filter on the booking team member selector view"
        )
        static let noMembersFound = NSLocalizedString(
            "bookingTeamMemberSelectorView.noMembersFound",
            value: "No team members found",
            comment: "Text on the empty view of the booking team member selector view"
        )
    }
}

// MARK: - Hosting Controller
final class BookingTeamMemberSelectorHostingController: UIHostingController<BookingTeamMemberSelectorView> {
    init(viewModel: BookingTeamMemberSelectorViewModel,
         selectedMember: BookingResource?,
         onSelection: @escaping (BookingResource?) -> Void) {
        super.init(rootView: BookingTeamMemberSelectorView(
            viewModel: viewModel,
            selectedMember: selectedMember,
            onSelection: onSelection
        ))
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
