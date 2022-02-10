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

    var body: some View {
        VStack(spacing: 0) {
            SearchHeader(filterText: $viewModel.searchTerm, filterPlaceholder: viewModel.filterPlaceholder)
                .background(Color(.listForeground))

            ListSelector(command: viewModel.command, tableStyle: .plain)
        }
        .navigationTitle(viewModel.navigationTitle)
    }
}
