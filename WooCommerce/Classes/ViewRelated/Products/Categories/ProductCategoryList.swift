import SwiftUI

/// SwiftUI wrapper of `ProductCategoryListViewController`.
///
struct ProductCategoryList: UIViewControllerRepresentable {
    private let viewModel: ProductCategoryListViewModel

    init(viewModel: ProductCategoryListViewModel) {
        self.viewModel = viewModel
    }

    func makeUIViewController(context: Context) -> ProductCategoryListViewController {
        return ProductCategoryListViewController(viewModel: viewModel)
    }

    func updateUIViewController(_ uiViewController: ProductCategoryListViewController, context: Context) {
        // no=op
    }
}
