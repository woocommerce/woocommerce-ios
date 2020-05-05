import Yosemite

/// Implementation of `SearchUICommand` for Product search.
final class ProductSearchUICommand: SearchUICommand {
    typealias Model = Product
    typealias CellViewModel = ProductsTabProductViewModel
    typealias ResultsControllerModel = StorageProduct

    let searchBarPlaceholder = NSLocalizedString("Search all products", comment: "Products Search Placeholder")

    let searchBarAccessibilityIdentifier = "product-search-screen-search-field"

    let cancelButtonAccessibilityIdentifier = "product-search-screen-cancel-button"

    private let siteID: Int64

    init(siteID: Int64) {
        self.siteID = siteID
    }

    func createResultsController() -> ResultsController<ResultsControllerModel> {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(key: "name", ascending: true)

        return ResultsController<StorageProduct>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }

    func createStarterViewController() -> UIViewController? {
        nil
    }

    func configureEmptyStateViewControllerBeforeDisplay(viewController: EmptyStateViewController,
                                                        searchKeyword: String) {
        let boldSearchKeyword = NSAttributedString(string: searchKeyword,
                                                   attributes: [.font: EmptyStateViewController.messageFont.bold])

        let format = NSLocalizedString("We're sorry, we couldn't find results for “%@”",
                                       comment: "Message for empty Products search results. The %@ is a placeholder for the text entered by the user.")
        let message = NSMutableAttributedString(string: format)
        message.replaceFirstOccurrence(of: "%@", with: boldSearchKeyword)

        viewController.configure(.simple(message: message, image: .emptySearchResultsImage))
    }

    func createCellViewModel(model: Product) -> ProductsTabProductViewModel {
        return ProductsTabProductViewModel(product: model)
    }

    /// Synchronizes the Products matching a given Keyword
    ///
    func synchronizeModels(siteID: Int64, keyword: String, pageNumber: Int, pageSize: Int, onCompletion: ((Bool) -> Void)?) {
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
        let isEditProductsEnabled = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.editProducts)
        let currencyCode = CurrencySettings.shared.currencyCode
        let currency = CurrencySettings.shared.symbol(from: currencyCode)
        let vc: UIViewController
        if model.productType == .simple && isEditProductsEnabled {
            vc = ProductFormViewController(product: model, currency: currency)
            // Since the edit Product UI could hold local changes, disables the bottom bar (tab bar) to simplify app states.
            vc.hidesBottomBarWhenPushed = true
        } else {
            let viewModel = ProductDetailsViewModel(product: model, currency: currency)
            vc = ProductDetailsViewController(viewModel: viewModel)
        }
        viewController.navigationController?.pushViewController(vc, animated: true)
    }
}
