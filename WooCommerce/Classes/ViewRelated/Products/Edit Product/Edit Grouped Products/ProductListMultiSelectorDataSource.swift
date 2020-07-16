import Yosemite

/// Enables the user to select multiple products from a paginated list.
final class ProductListMultiSelectorDataSource: PaginatedListSelectorDataSource {
    typealias StorageModel = StorageProduct

    // Observable list of the latest product IDs
    var productIDs: Observable<[Int64]> {
        productIDsSubject
    }
    private let productIDsSubject: PublishSubject<[Int64]> = PublishSubject<[Int64]>()

    // Not used: since multiple products can be selected in this use case, the single selected product is not used.
    var selected: Product?

    private let siteID: Int64
    private let excludedProductIDs: [Int64]
    private var selectedProductIDs: [Int64] = [] {
        didSet {
            if selectedProductIDs != oldValue {
                productIDsSubject.send(selectedProductIDs)
            }
        }
    }
    private let imageService: ImageService

    init(siteID: Int64, excludedProductIDs: [Int64], imageService: ImageService = ServiceLocator.imageService) {
        self.siteID = siteID
        self.excludedProductIDs = excludedProductIDs
        self.imageService = imageService
    }

    func createResultsController() -> ResultsController<StorageProduct> {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "siteID == %lld AND NOT(productID IN %@)", siteID, excludedProductIDs)
        return ResultsController<StorageProduct>(storageManager: storageManager,
                                                 matching: predicate,
                                                 sortOrder: .nameAscending)
    }

    func handleSelectedChange(selected: Product) {
        if isProductSelected(selected) {
            selectedProductIDs.removeAll { $0 == selected.productID }
        } else {
            selectedProductIDs.append(selected.productID)
        }
    }

    func isSelected(model: Product) -> Bool {
        return model == selected
    }

    func configureCell(cell: ProductsTabProductTableViewCell, model: Product) {
        cell.selectionStyle = .default

        let viewModel = ProductsTabProductViewModel(product: model, isSelected: isProductSelected(model))
        cell.update(viewModel: viewModel, imageService: imageService)
    }

    func sync(pageNumber: Int, pageSize: Int, onCompletion: ((Bool) -> Void)?) {
        let action = ProductAction
            .synchronizeProducts(siteID: siteID,
                                 pageNumber: pageNumber,
                                 pageSize: pageSize,
                                 stockStatus: nil,
                                 productStatus: nil,
                                 productType: nil,
                                 sortOrder: .nameAscending,
                                 excludedProductIDs: excludedProductIDs,
                                 shouldDeleteStoredProductsOnFirstPage: false) { error in
                                    if let error = error {
                                        DDLogError("⛔️ Error synchronizing products on product list selector: \(error)")
                                        onCompletion?(false)
                                        return
                                    }
                                    onCompletion?(true)
        }
        ServiceLocator.stores.dispatch(action)
    }
}

private extension ProductListMultiSelectorDataSource {
    func isProductSelected(_ product: Product) -> Bool {
        return selectedProductIDs.contains(product.productID)
    }
}
