import SwiftUI

struct SyncableListSelectorView<Syncable: ListSyncable>: View {
    @ObservedObject private var viewModel: SyncableListSelectorViewModel<Syncable>
    @State private var selectedItems: [Syncable.ModelType]

    private let syncable: Syncable
    private let initialSelection: (Syncable.ModelType) -> Bool
    private let onSelection: ([Syncable.ModelType]) -> Void

    private let viewPadding: CGFloat = 16

    init(viewModel: SyncableListSelectorViewModel<Syncable>,
         syncable: Syncable,
         initialSelection: @escaping (Syncable.ModelType) -> Bool,
         onSelection: @escaping ([Syncable.ModelType]) -> Void) {
        self.viewModel = viewModel
        self.syncable = syncable
        self.initialSelection = initialSelection
        self.onSelection = onSelection
        self._selectedItems = State(initialValue: [])
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
                isSelected: selectedItems.isEmpty,
                onSelection: {
                    selectedItems.removeAll()
                    onSelection(selectedItems)
                }
            )

            ForEach(items, id: \.self) { item in
                optionRow(text: syncable.displayName(for: item),
                          isSelected: isItemSelected(item),
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

    func isItemSelected(_ item: Syncable.ModelType) -> Bool {
        if selectedItems.isEmpty {
            return initialSelection(item)
        }
        return selectedItems.contains(item)
    }

    func toggleSelection(for item: Syncable.ModelType) {
        if let index = selectedItems.firstIndex(of: item) {
            selectedItems.remove(at: index)
        } else {
            selectedItems.append(item)
        }
        onSelection(selectedItems)
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
            Text(syncable.emptyStateMessage)
                .secondaryBodyStyle()
            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, viewPadding)
        .background(Color(.systemBackground))
    }
}
