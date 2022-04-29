import SwiftUI

/// View showing a list of product categories to select from.
///
struct ProductCategorySelector: View {
    @ObservedObject private var viewModel: ProductCategorySelectorViewModel

    init(viewModel: ProductCategorySelectorViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text("Hello, World!")
    }
}

struct ProductCategorySelector_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ProductCategorySelectorViewModel(siteID: 123) { _ in }
        ProductCategorySelector(viewModel: viewModel)
    }
}
