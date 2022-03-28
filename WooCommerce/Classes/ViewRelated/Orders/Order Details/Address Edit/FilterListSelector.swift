import SwiftUI
import Shimmer

protocol FilterListSelectorViewModelable: ObservableObject {

    associatedtype Command: ObservableListSelectorCommand

    /// Binding variable for the filter search term
    ///
    var searchTerm: String { get set }

    /// Command to provide data and cell configuration
    ///
    var command: Command { get }

    /// View title in a navigation context
    ///
    var navigationTitle: String { get }

    /// Placeholder for the filter text field
    ///
    var filterPlaceholder: String { get }
}

/// Filterable List Selector View
///
struct FilterListSelector<ViewModel: FilterListSelectorViewModelable>: View {

    /// View model to drive the view content
    ///
    @StateObject var viewModel: ViewModel

    /// Header search term.
    ///
    /// We don't use `$viewModel.searchTerm` directly because there appears to be a bug where the **search term** assignment
    /// enters into an infinite loop after choosing an autocomplete suggestion. https://github.com/woocommerce/woocommerce-ios/issues/6211
    ///
    /// A **fix**  is to provide this local binding and use the `onChange(of:)` modifier to relay changes to the view model.
    ///
    @State private var searchTerm = ""

    /// Custom init to provide an initial value to the local `searchTerm` from `viewModel.searchTerm`.
    ///
    init(viewModel: ViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.searchTerm = viewModel.searchTerm
    }

    var body: some View {
        VStack(spacing: 0) {
            SearchHeader(filterText: $searchTerm, filterPlaceholder: viewModel.filterPlaceholder)
                .background(Color(.listForeground))
                .onChange(of: searchTerm) { newValue in
                    viewModel.searchTerm = newValue
                }

            ListSelector(command: viewModel.command, tableStyle: .plain)
                .ignoresSafeArea()
        }
        .navigationTitle(viewModel.navigationTitle)
    }
}
