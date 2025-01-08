import SwiftUI

/// Hosting controller for `FilterHistoryView`
final class FilterHistoryViewHostingController<ViewModel: FilterListViewModel>: UIHostingController<FilterHistoryView<ViewModel>> {
    init(viewModel: ViewModel, onSelection: @escaping (ViewModel.Criteria) -> Void) {
        super.init(rootView: FilterHistoryView(viewModel: viewModel, onSelection: onSelection))
        rootView.onDismiss = { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// View to list all saved filter history
struct FilterHistoryView<ViewModel: FilterListViewModel>: View {

    /// to be set externally on the hosting controller
    var onDismiss: () -> Void = {}

    private let viewModel: ViewModel
    private let onSelection: (ViewModel.Criteria) -> Void

    @State private var selectedFilter: ViewModel.Criteria?
    @State private var savedFilters: [ViewModel.Criteria] = []
    @State private var error: Error?

    private let title = NSLocalizedString(
        "filterHistoryView.title",
        value: "Filter History",
        comment: "Title of the Filter History view"
    )

    private let cancel = NSLocalizedString(
        "filterHistoryView.cancel",
        value: "Cancel",
        comment: "Cancel button on the Filter History view"
    )

    private let apply = NSLocalizedString(
        "filterHistoryView.apply",
        value: "Apply",
        comment: "Apply button on the Filter History view"
    )

    private let emptyState = NSLocalizedString(
        "filterHistoryView.emptyState",
        value: "No past filters found",
        comment: "Label on the empty state of the Filter History view"
    )

    init(viewModel: ViewModel, onSelection: @escaping (ViewModel.Criteria) -> Void) {
        self.viewModel = viewModel
        self.onSelection = onSelection
    }

    var body: some View {
        NavigationStack {
            VStack {
                if error != nil {
                    emptyStateView
                } else {
                    filterListView
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(cancel) {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(apply) {
                        guard let selectedFilter else { return }
                        onSelection(selectedFilter)
                        onDismiss()
                    }
                    .disabled(selectedFilter == nil)
                }
            }
        }
        .task {
            do {
                savedFilters = try await viewModel.retrieveFilterHistory()
            } catch {
                self.error = error
            }
        }
    }
}

private extension FilterHistoryView {
    var filterListView: some View {
        List {
            ForEach(savedFilters, id: \.readableString) { filter in
                SelectableItemRow(title: filter.readableString,
                                  selected: selectedFilter == filter,
                                  displayMode: .compact)
                    .onTapGesture {
                        selectedFilter = filter
                    }
            }
        }
        .listStyle(.grouped)
    }

    @ViewBuilder
    var emptyStateView: some View {
        Image(systemName: "clock")
            .foregroundColor(.secondary)
            .font(.largeTitle)
            .padding(.bottom)
        Text(emptyState)
            .secondaryBodyStyle()
    }
}
