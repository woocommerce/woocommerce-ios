import SwiftUI

/// Hosting controller for `FilterHistoryView`
final class FilterHistoryViewHostingController: UIHostingController<FilterHistoryView> {
    init(viewModel: any FilterListViewModel) {
        super.init(rootView: FilterHistoryView(viewModel: viewModel))
        rootView.onDismiss = { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// View to list all saved filter history
struct FilterHistoryView: View {

    /// to be set externally on the hosting controller
    var onDismiss: () -> Void = {}

    private let viewModel: any FilterListViewModel

    init(viewModel: any FilterListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            Text("Hello, World!")
                .navigationTitle(Localization.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(Localization.cancel) {
                            onDismiss()
                        }
                    }
                }
        }
    }
}

private extension FilterHistoryView {
    enum Localization {
        static let title = NSLocalizedString(
            "filterHistoryView.title",
            value: "Filter History",
            comment: "Title of the Filter History view"
        )
        static let cancel = NSLocalizedString(
            "filterHistoryView.cancel",
            value: "Cancel",
            comment: "Cancel button on the Filter History view"
        )
    }
}

#Preview {
    FilterHistoryView(viewModel: FilterOrderListViewModel(filters: FilterOrderListViewModel.Filters(),
                                                          allowedStatuses: [],
                                                          siteID: 123))
}
