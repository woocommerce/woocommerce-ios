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

/// Search Header View
///
private struct SearchHeader: View {

    // Tracks the scale of the view due to accessibility changes
    @ScaledMetric private var scale: CGFloat = 1

    /// Filter search term
    ///
    @Binding var filterText: String

    /// Placeholder for the filter text field
    ///
    let filterPlaceholder: String

    var body: some View {
        HStack(spacing: 0) {
            // Search Icon
            Image(uiImage: .searchBarButtonItemImage)
                .renderingMode(.template)
                .resizable()
                .frame(width: Layout.iconSize.width * scale, height: Layout.iconSize.height * scale)
                .foregroundColor(Color(.listSmallIcon))
                .padding([.leading, .trailing], Layout.internalPadding)
                .accessibilityHidden(true)

            // TextField
            TextField(filterPlaceholder, text: $filterText)
                .padding([.bottom, .top], Layout.internalPadding)
                .accessibility(addTraits: .isSearchField)
        }
        .background(Color(.searchBarBackground))
        .cornerRadius(Layout.cornerRadius)
        .padding(Layout.externalPadding)
    }
}

// MARK: Constants

private extension SearchHeader {
    enum Layout {
        static let iconSize = CGSize(width: 16, height: 16)
        static let internalPadding: CGFloat = 8
        static let cornerRadius: CGFloat = 10
        static let externalPadding = EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
    }
}
