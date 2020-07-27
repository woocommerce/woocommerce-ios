import Yosemite

/// Implementation of `SearchUICommand` for selecting linked products to a grouped product from search UI.
final class ProductListMultiSelectorSearchUICommand: SearchUICommand {
    typealias Model = Product
    typealias CellViewModel = ProductsTabProductViewModel
    typealias ResultsControllerModel = StorageProduct

    let searchBarPlaceholder = NSLocalizedString("Search all products", comment: "Products Search Placeholder")

    let searchBarAccessibilityIdentifier = "product-search-screen-search-field"

    let cancelButtonAccessibilityIdentifier = "product-search-screen-cancel-button"

    private let siteID: Int64

    private let excludedProductIDs: [Int64]
    private var selectedProductIDs: [Int64] = []

    typealias Completion = (_ selectedProductIDs: [Int64]) -> Void
    private let onCompletion: Completion

    init(siteID: Int64, excludedProductIDs: [Int64], onCompletion: @escaping Completion) {
        self.siteID = siteID
        self.excludedProductIDs = excludedProductIDs
        self.onCompletion = onCompletion
    }

    func createResultsController() -> ResultsController<ResultsControllerModel> {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "siteID == %lld AND NOT(productID in %@)", siteID, excludedProductIDs)
        return ResultsController<StorageProduct>(storageManager: storageManager, matching: predicate, sortOrder: .nameAscending)
    }

    func createStarterViewController() -> UIViewController? {
        nil
    }

    func configureEmptyStateViewControllerBeforeDisplay(viewController: EmptyStateViewController,
                                                        searchKeyword: String) {
        let boldSearchKeyword = NSAttributedString(string: searchKeyword,
                                                   attributes: [.font: EmptyStateViewController.Config.messageFont.bold])

        let message = NSMutableAttributedString(string: Strings.emptySearchResultsFormat)
        message.replaceFirstOccurrence(of: "%@", with: boldSearchKeyword)

        viewController.configure(.simple(message: message, image: .emptySearchResultsImage))
    }

    func configureActionButton(_ button: UIButton, onDismiss: @escaping () -> Void) {
        let hasUnsavedChanges = selectedProductIDs.isNotEmpty
        let title = hasUnsavedChanges ? Strings.done: Strings.cancel

        // The button title has to be updated without animation so that the title is not truncated when its width changes.
        UIView.performWithoutAnimation {
            button.setTitle(title, for: .normal)
            button.layoutIfNeeded()
        }
        button.on(.touchUpInside) { [weak self] _ in
            if hasUnsavedChanges {
                self?.completeSelectingProducts()
            }
            onDismiss()
        }
    }

    func createCellViewModel(model: Product) -> ProductsTabProductViewModel {
        return ProductsTabProductViewModel(product: model, isSelected: isProductSelected(model))
    }

    /// Synchronizes the Products matching a given Keyword
    ///
    func synchronizeModels(siteID: Int64, keyword: String, pageNumber: Int, pageSize: Int, onCompletion: ((Bool) -> Void)?) {
        let action = ProductAction.searchProducts(siteID: siteID,
                                                  keyword: keyword,
                                                  pageNumber: pageNumber,
                                                  pageSize: pageSize,
                                                  excludedProductIDs: excludedProductIDs) { error in
                                                    if let error = error {
                                                        DDLogError("☠️ Product Search Failure! \(error)")
                                                    }

                                                    onCompletion?(error == nil)
        }
        ServiceLocator.stores.dispatch(action)
    }

    func didSelectSearchResult(model: Product, from viewController: UIViewController, reloadData: () -> Void, updateActionButton: () -> Void) {
        onProductSelected(model)
        reloadData()
        updateActionButton()
    }
}

private extension ProductListMultiSelectorSearchUICommand {
    @objc func completeSelectingProducts() {
        onCompletion(selectedProductIDs)
    }
}

private extension ProductListMultiSelectorSearchUICommand {
    func isProductSelected(_ product: Product) -> Bool {
        return selectedProductIDs.contains(product.productID)
    }

    func onProductSelected(_ product: Product) {
        if isProductSelected(product) {
            // Unselects the product if it is currently selected.
            selectedProductIDs.removeAll { $0 == product.productID }
        } else {
            selectedProductIDs.append(product.productID)
        }
    }
}

private extension ProductListMultiSelectorSearchUICommand {
    enum Strings {
        static let cancel = NSLocalizedString("Cancel", comment: "Action title to cancel selecting products to add to a grouped product from search results")
        static let done = NSLocalizedString("Done", comment: "Action title to select products to add to a grouped product from search results")
        static let emptySearchResultsFormat =
            NSLocalizedString("We're sorry, we couldn't find results for “%@”",
                              comment: "Message for empty Products search results. The %@ is a placeholder for the text entered by the user.")
    }
}
