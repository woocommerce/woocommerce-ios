import SwiftUI

/// SwiftUI wrapper of `FilterListViewController`.
///
struct FilterListView<ViewModel: FilterListViewModel>: UIViewControllerRepresentable {
    private let viewModel: ViewModel
    private let onFilterAction: (ViewModel.Criteria) -> Void
    private let onClearAction: () -> Void
    private let onDismissAction: () -> Void

    init(viewModel: ViewModel,
         onFilterAction: @escaping (ViewModel.Criteria) -> Void,
         onClearAction: @escaping () -> Void,
         onDismissAction: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onFilterAction = onFilterAction
        self.onClearAction = onClearAction
        self.onDismissAction = onDismissAction
    }

    func makeUIViewController(context: Context) -> FilterListViewController<ViewModel> {
        return FilterListViewController(viewModel: viewModel,
                                        onFilterAction: onFilterAction,
                                        onClearAction: onClearAction,
                                        onDismissAction: onDismissAction)
    }

    func updateUIViewController(_ uiViewController: FilterListViewController<ViewModel>, context: Context) {
        // no=op
    }
}
