import SwiftUI

struct SyncableListSelectorView<Syncable: ListSyncable>: View {
    @ObservedObject private var viewModel: SyncableListSelectorViewModel<Syncable>
    @State private var selectedItems: [Syncable.ListFilterType]

    private let syncable: Syncable
    private let onSelection: ([Syncable.ListFilterType]) -> Void

    private let viewPadding: CGFloat = 16

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

            ForEach(items, id: \.self) { item in
                optionRow(text: syncable.displayName(for: item),
                          description: syncable.description(for: item),
                          isSelected: selectedItems.contains(where: { $0 == syncable.filterItem(for: item) }),
                          onSelection: { toggleSelection(for: item) })
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

    func toggleSelection(for item: Syncable.ModelType) {
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
            Text(syncable.emptyStateMessage)
                .secondaryBodyStyle()
            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, viewPadding)
        .background(Color(.systemBackground))
    }
}
