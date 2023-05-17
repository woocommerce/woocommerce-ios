import Yosemite

/// Implementation of `SearchUICommand` for Product search.
final class ProductSearchUICommand: SearchUICommand {
    typealias Model = Product
    typealias CellViewModel = ProductsTabProductViewModel
    typealias ResultsControllerModel = StorageProduct

    let searchBarPlaceholder = NSLocalizedString("Search products", comment: "Products Search Placeholder")

    let searchBarAccessibilityIdentifier = "product-search-screen-search-field"

    let cancelButtonAccessibilityIdentifier = "product-search-screen-cancel-button"

    var resynchronizeModels: (() -> Void) = {}

    private var lastSearchQueryByFilter: [ProductSearchFilter: String] = [:]
    private var filter: ProductSearchFilter = .all

    private let siteID: Int64
    private let stores: StoresManager
    private let analytics: Analytics
    private let isSearchProductsBySKUEnabled: Bool

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         isSearchProductsBySKUEnabled: Bool = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.searchProductsBySKU)) {
        self.siteID = siteID
        self.stores = stores
        self.analytics = analytics
        self.isSearchProductsBySKUEnabled = isSearchProductsBySKUEnabled
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

    func createHeaderView() -> UIView? {
        guard isSearchProductsBySKUEnabled else {
            return nil
        }
        let segmentedControl: UISegmentedControl = {
            let segmentedControl = UISegmentedControl()

            let filters: [ProductSearchFilter] = [.all, .sku]
            for (index, filter) in filters.enumerated() {
                segmentedControl.insertSegment(withTitle: filter.title, at: index, animated: false)
                if filter == self.filter {
                    segmentedControl.selectedSegmentIndex = index
                }
            }
            segmentedControl.on(.valueChanged) { [weak self] sender in
                let index = sender.selectedSegmentIndex
                guard let filter = filters[safe: index] else {
                    return
                }
                self?.showResults(filter: filter)
            }
            return segmentedControl
        }()

        let containerView = UIView(frame: .zero)
        containerView.addSubview(segmentedControl)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        containerView.pinSubviewToAllEdges(segmentedControl, insets: .init(top: 8, left: 16, bottom: 16, right: 16))
        return containerView
    }

    func configureEmptyStateViewControllerBeforeDisplay(viewController: EmptyStateViewController,
                                                        searchKeyword: String) {
        let boldSearchKeyword = NSAttributedString(string: searchKeyword,
                                                   attributes: [.font: EmptyStateViewController.Config.messageFont.bold])

        let format = NSLocalizedString("We're sorry, we couldn't find results for “%@”",
                                       comment: "Message for empty Products search results. The %@ is a placeholder for the text entered by the user.")
        let message = NSMutableAttributedString(string: format)
        message.replaceFirstOccurrence(of: "%@", with: boldSearchKeyword)

        viewController.configure(.simple(message: message, image: .emptySearchResultsImage))
    }

    func createCellViewModel(model: Product) -> ProductsTabProductViewModel {
        ProductsTabProductViewModel(product: model, isSKUShown: true)
    }

    /// Synchronizes the Products matching a given Keyword
    ///
    func synchronizeModels(siteID: Int64, keyword: String, pageNumber: Int, pageSize: Int, onCompletion: ((Bool) -> Void)?) {
        if isSearchProductsBySKUEnabled {
            // Returns early if the search query is the same for the given filter and for the first page to avoid duplicate API requests when
            // switching filter tabs.
            if let lastFilterSearchQuery = lastSearchQueryByFilter[filter],
               lastFilterSearchQuery == keyword,
               pageNumber == SyncingCoordinator.Defaults.pageFirstIndex {
                onCompletion?(true)
                return
            }
            // Skips the product search API request if the keyword is empty.
            guard keyword.isNotEmpty else {
                onCompletion?(true)
                return
            }
            lastSearchQueryByFilter[filter] = keyword
        }

        let action = ProductAction.searchProducts(siteID: siteID,
                                                  keyword: keyword,
                                                  filter: filter,
                                                  pageNumber: pageNumber,
                                                  pageSize: pageSize) { result in
            if case let .failure(error) = result {
                DDLogError("☠️ Product Search Failure! \(error)")
            }

            onCompletion?(result.isSuccess)
        }

        stores.dispatch(action)

        analytics.track(.productListSearched, withProperties: isSearchProductsBySKUEnabled ? ["filter": filter.analyticsValue]: nil)
    }

    func didSelectSearchResult(model: Product, from viewController: UIViewController, reloadData: () -> Void, updateActionButton: () -> Void) {
        ProductDetailsFactory.productDetails(product: model, presentationStyle: .navigationStack, forceReadOnly: false) { [weak viewController] vc in
            viewController?.navigationController?.pushViewController(vc, animated: true)
        }
    }

    func searchResultsPredicate(keyword: String) -> NSPredicate? {
        guard isSearchProductsBySKUEnabled else {
            return NSPredicate(format: "ANY searchResults.keyword = %@", keyword)
        }
        guard keyword.isNotEmpty else {
            return nil
        }
        return NSPredicate(format: "SUBQUERY(searchResults, $result, $result.keyword = %@ AND $result.filterKey = %@).@count > 0",
                           keyword, filter.rawValue)
    }
}

private extension ProductSearchUICommand {
    func showResults(filter: ProductSearchFilter) {
        guard filter != self.filter else {
            return
        }
        self.filter = filter
        resynchronizeModels()
    }
}

extension ProductSearchFilter {
    var title: String {
        switch self {
        case .all:
            return NSLocalizedString("All Products", comment: "Title of the product search filter to search for all products.")
        case .sku:
            return NSLocalizedString("SKU", comment: "Title of the product search filter to search for products that match the SKU.")
        }
    }

    /// The value that is set in the analytics event property.
    var analyticsValue: String {
        switch self {
        case .all:
            return "all"
        case .sku:
            return "sku"
        }
    }
}
