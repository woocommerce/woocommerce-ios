import SwiftUI

/// View showing a list of product categories to select from.
///
struct ProductCategorySelector: View {
    @ObservedObject private var viewModel: ProductCategorySelectorViewModel

    init(viewModel: ProductCategorySelectorViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ProductCategoryList(viewModel: viewModel.listViewModel)
                Button("Done") {
                    // TODO
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        // TODO
                    }
                }
            }
            .navigationTitle("Select Products")
            .navigationBarTitleDisplayMode(.large)
            .navigationViewStyle(.stack)
            .wooNavigationBarStyle()
        }
    }
}

struct ProductCategorySelector_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ProductCategorySelectorViewModel(siteID: 123) { _ in }
        ProductCategorySelector(viewModel: viewModel)
    }
}
