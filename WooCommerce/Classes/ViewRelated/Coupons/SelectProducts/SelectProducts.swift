import SwiftUI

/// View to select products
///
struct SelectProducts: View {
    @State private var query: String = ""
    @ObservedObject private var viewModel: SelectProductsViewModel

    init(viewModel: SelectProductsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SearchHeader(filterText: $query, filterPlaceholder: Localization.searchBarPlaceholder)
            HStack {
                Button(Localization.selectAll) {
                    // TODO: select all item
                }
                .buttonStyle(LinkButtonStyle())
                .fixedSize()
                Spacer()
                Button(Localization.filter) {
                    // TODO: show filter view
                }
                .buttonStyle(LinkButtonStyle())
                .fixedSize()
            }
            Spacer()
            Button(viewModel.actionTitle) {
                // TODO: handle completion
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding()
            .renderedIf(viewModel.selectedItemCount > 0)
        }
        navigationTitle(viewModel.navigationTitle)
    }
}

private extension SelectProducts {
    enum Constants {
        static let horizontalSpacing: CGFloat = 16
    }

    enum Localization {
        static let searchBarPlaceholder = NSLocalizedString("Search Products", comment: "Placeholder for the search bar in the Select Products screen")
        static let selectAll = NSLocalizedString("Select All", comment: "Action button on the Select Products screen to select all products in the list")
        static let filter = NSLocalizedString("Filter", comment: "Action button on the Select Products screen to filter items in the product list.")
    }
}

struct SelectProducts_Previews: PreviewProvider {
    static var previews: some View {
        SelectProducts(viewModel: .init())
    }
}
