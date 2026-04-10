import SwiftUI

struct SyncableListSelectorView<Syncable: ListSyncable>: View {
    @ObservedObject private var viewModel: SyncableListSelectorViewModel<Syncable>
    @State private var selectedItems: [Syncable.ListFilterType]
    @State private var notice: Notice?

    @ScaledMetric private var scale: CGFloat = 1.0

    private let syncable: Syncable
    private let onSelection: ([Syncable.ListFilterType]) -> Void

    private let viewPadding: CGFloat = 16
    private let emptyStateImageWidth: CGFloat = 67

    init(viewModel: SyncableListSelectorViewModel<Syncable>,
         syncable: Syncable,
         initialSelections: [Syncable.ListFilterType],
         onSelection: @escaping ([Syncable.ListFilterType]) -> Void) {
        self.viewModel = viewModel
        self.syncable = syncable
        self.selectedItems = initialSelections
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
                itemList(with: viewModel.items,
                         onNextPage: { viewModel.onLoadNextPageAction() })
            }
        }
        .task {
            viewModel.loadResources()
        }
        .navigationTitle(syncable.title)
        .navigationBarTitleDisplayMode(.inline)
        .notice($notice)
        .if(syncable.searchConfiguration != nil) { view in
            view.searchable(text: $viewModel.searchQuery,
                            placement: .navigationBarDrawer(displayMode: .always),
                            prompt: syncable.searchConfiguration!.searchPrompt)
        }
    }
}

private extension SyncableListSelectorView {
    var loadingView: some View {
        VStack {
            Spacer()
            ProgressView().progressViewStyle(.circular)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }

    func itemList(with items: [Syncable.ModelType],
                  onNextPage: @escaping () -> Void) -> some View {
        List {
            optionRow(
                text: NSLocalizedString(
                    "listSelectorView.any",
                    value: "Any",
                    comment: "Option to select no filter on a list selector view"
                ),
                description: nil,
                isSelected: selectedItems.isEmpty,
                onSelection: {
                    selectedItems.removeAll()
                    onSelection([])
                }
            )
            .renderedIf(viewModel.searchQuery.isEmpty)
            .listRowSeparator(.hidden, edges: .top)

            ForEach(Array(items.enumerated()), id: \.element) { (index, item) in
                optionRow(text: syncable.displayName(for: item),
                          description: syncable.description(for: item),
                          isSelected: selectedItems.contains(where: { $0 == syncable.filterItem(for: item) }),
                          onSelection: { toggleSelectionIfPossible(for: item) })
                .if(index == 0 && viewModel.searchQuery.isNotEmpty) {
                    $0.listRowSeparator(.hidden, edges: .top)
                }
            }

            InfiniteScrollIndicator(showContent: viewModel.shouldShowBottomActivityIndicator)
                .padding(.top, viewPadding)
                .onAppear {
                    onNextPage()
                }
        }
        .listStyle(.plain)
        .background(Color(.listBackground))
    }

    func toggleSelectionIfPossible(for item: Syncable.ModelType) {
        guard syncable.selectionEnabled(for: item) else {
            if let message = syncable.selectionDisabledMessage {
                notice = Notice(message: message, feedbackType: .error)
            }
            return
        }
        let filterItem = syncable.filterItem(for: item)
        if let index = selectedItems.firstIndex(of: filterItem) {
            selectedItems.remove(at: index)
        } else {
            selectedItems.append(filterItem)
        }
        onSelection(selectedItems)
    }

    func optionRow(text: String, description: String?, isSelected: Bool, onSelection: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading) {
                if text.isEmpty, let placeholder = syncable.emptyItemTitlePlaceholder {
                    Text(placeholder)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.secondary)
                } else {
                    Text(text)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.primary)
                }

                if let description {
                    Text(description)
                        .footnoteStyle()
                }
            }
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
            Image(.magnifyingGlassNotFound)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: emptyStateImageWidth * scale)
                .padding(.bottom, viewPadding)
                .renderedIf(viewModel.searchQuery.isNotEmpty)

            if let configuration = syncable.searchConfiguration,
                viewModel.searchQuery.isNotEmpty {
                Text(configuration.emptySearchTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary)
                Text(configuration.emptySearchDescription)
                    .font(.title3)
                    .foregroundStyle(Color.secondary)
            } else {
                Text(syncable.emptyStateMessage)
                    .secondaryBodyStyle()
            }
            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, viewPadding)
        .background(Color(.systemBackground))
    }
}
