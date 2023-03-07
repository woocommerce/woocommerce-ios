import SwiftUI

/// SwiftUI wrapper of `ProductCategoryListViewController`.
///
struct ProductCategoryList: UIViewControllerRepresentable {
    private let viewModel: ProductCategoryListViewModel
    private let config: ProductCategoryListViewController.Configuration

    init(viewModel: ProductCategoryListViewModel, config: ProductCategoryListViewController.Configuration) {
        self.viewModel = viewModel
        self.config = config
    }

    func makeUIViewController(context: Context) -> ProductCategoryListViewController {
        return ProductCategoryListViewController(viewModel: viewModel, configuration: config)
    }

    func updateUIViewController(_ uiViewController: ProductCategoryListViewController, context: Context) {
        // no=op
    }
}
