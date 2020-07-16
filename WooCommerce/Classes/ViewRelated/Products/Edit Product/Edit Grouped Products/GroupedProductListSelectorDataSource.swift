import UIKit
import Yosemite

/// Configures the results and cells for a paginated list of linked products of a grouped product, syncs each page of products,
/// and handles actions that could alter the linked products.
final class GroupedProductListSelectorDataSource: PaginatedListSelectorDataSource {
    typealias StorageModel = StorageProduct

    lazy var customResultsSortOrder: ((Product, Product) -> Bool)? = { [weak self] (lhs, rhs) in
        guard let self = self else {
            return true
        }
        let lhsProductID = lhs.productID
        let rhsProductID = rhs.productID
        let productIDs = self.groupedProductIDs
        guard let lhsProductIDIndex = productIDs.firstIndex(of: lhsProductID), let rhsProductIDIndex = productIDs.firstIndex(of: rhsProductID) else {
            return true
        }
        return lhsProductIDIndex < rhsProductIDIndex
    }

    // Observable list of the latest grouped product IDs
    var productIDs: Observable<[Int64]> {
        productIDsSubject
    }
    private let productIDsSubject: PublishSubject<[Int64]> = PublishSubject<[Int64]>()

    private(set) var groupedProductIDs: [Int64] = [] {
        didSet {
            if groupedProductIDs != oldValue {
                productIDsSubject.send(groupedProductIDs)
            }
        }
    }

    // Not used: a grouped product's linked product list is not selectable in this use case.
    var selected: Product?

    private let siteID: Int64
    private let product: Product
    private let imageService: ImageService

    init(product: Product, imageService: ImageService = ServiceLocator.imageService) {
        self.siteID = product.siteID
        self.product = product
        self.groupedProductIDs = product.groupedProducts
        self.imageService = imageService
    }

    func createResultsController() -> ResultsController<StorageProduct> {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "siteID == %lld AND productID IN %@", siteID, groupedProductIDs)
        return ResultsController<StorageProduct>(storageManager: storageManager,
                                                 matching: predicate,
                                                 sortOrder: .nameAscending)
    }

    func handleSelectedChange(selected: Product) {
        // no-op: a grouped product's linked product list is not selectable in this use case.
    }

    func isSelected(model: Product) -> Bool {
        return model == selected
    }

    func configureCell(cell: ProductsTabProductTableViewCell, model: Product) {
        cell.selectionStyle = .none

        let viewModel = ProductsTabProductViewModel(product: model)
        cell.update(viewModel: viewModel, imageService: imageService)

        cell.configureAccessoryDeleteButton { [weak self] in
            self?.deleteProduct(model)
        }

        cell.accessoryType = isSelected(model: model) ? .checkmark: .none
    }

    func sync(pageNumber: Int, pageSize: Int, onCompletion: ((Bool) -> Void)?) {
        let action = ProductAction.retrieveProducts(siteID: siteID,
                                                    productIDs: groupedProductIDs,
                                                    pageNumber: pageNumber,
                                                    pageSize: pageSize) { result in
                                                        switch result {
                                                        case .success:
                                                            onCompletion?(true)
                                                        case .failure(let error):
                                                            DDLogError("⛔️ Error synchronizing grouped product's linked products: \(error)")
                                                            onCompletion?(false)
                                                        }
        }
        ServiceLocator.stores.dispatch(action)
    }
}

// MARK: Public actions
//
extension GroupedProductListSelectorDataSource {
    /// Called when the user deletes a product from the product list.
    func deleteProduct(_ product: Product) {
        guard let index = groupedProductIDs.firstIndex(where: { $0 == product.productID }) else {
            return
        }
        groupedProductIDs.remove(at: index)
    }

    /// Called when the user adds products to a grouped product.
    /// - Parameter products: a list of products to add to a grouped product.
    func addProducts(_ productIDs: [Int64]) {
        groupedProductIDs = (groupedProductIDs + productIDs).removingDuplicates()
    }

    /// Returns whether there are unsaved changes on the grouped products.
    func hasUnsavedChanges() -> Bool {
        return groupedProductIDs != product.groupedProducts
    }
}
