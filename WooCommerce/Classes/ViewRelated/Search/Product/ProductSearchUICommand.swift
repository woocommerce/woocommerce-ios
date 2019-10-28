import Yosemite

// TODO: remove after testing
import Networking

/// Implementation of `SearchUICommand` for Product search.
final class ProductSearchUICommand: SearchUICommand {
    typealias Model = Product
    typealias CellViewModel = ProductsTabProductViewModel
    typealias ResultsControllerModel = StorageProduct

    let searchBarPlaceholder = NSLocalizedString("Search all products", comment: "Products Search Placeholder")

    let emptyStateText = NSLocalizedString("No products yet", comment: "Search Products (Empty State)")

    private let siteID: Int

    init(siteID: Int) {
        self.siteID = siteID
    }

    func createResultsController() -> ResultsController<ResultsControllerModel> {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(key: "dateModified", ascending: true)

        return ResultsController<StorageProduct>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }

    func createCellViewModel(model: Product) -> ProductsTabProductViewModel {
        return ProductsTabProductViewModel(product: model)
    }

    /// Synchronizes the Products matching a given Keyword
    ///
    func synchronizeModels(siteID: Int, keyword: String, pageNumber: Int, pageSize: Int, onCompletion: ((Bool) -> Void)?) {
        let action = ProductAction.searchProducts(siteID: siteID,
                                                  keyword: keyword,
                                                  pageNumber: pageNumber,
                                                  pageSize: pageSize) { error in
                                                    if let error = error {
                                                        DDLogError("☠️ Product Search Failure! \(error)")
                                                    }

                                                    onCompletion?(error == nil)
        }

        ServiceLocator.stores.dispatch(action)

        ServiceLocator.analytics.track(.productListSearched)
    }

    func didSelectSearchResult(model: Product, from viewController: UIViewController) {
        // TODO: Remove after testing previewing a product

        guard let credentials = ServiceLocator.stores.sessionManager.defaultCredentials,
            let site = ServiceLocator.stores.sessionManager.defaultSite else {
            fatalError()
        }

        let previewGenerator = ProductPreviewGenerator(product: model, frameNonce: site.frameNonce, credentials: credentials)
        previewGenerator.generate { (request, errorMessage) in
            guard let request = request else {
                DDLogError("⛔️ Unable to preview product (\(model.name)): \(errorMessage ?? "Unknown")")
                return
            }
            WebviewHelper.launch(request.url?.absoluteString, with: viewController)
        }
        return

        let currencyCode = CurrencySettings.shared.currencyCode
        let currency = CurrencySettings.shared.symbol(from: currencyCode)
        let viewModel = ProductDetailsViewModel(product: model, currency: currency)
        let productViewController = ProductDetailsViewController(viewModel: viewModel)
        viewController.navigationController?.pushViewController(productViewController, animated: true)
    }
}
