import UIKit
import WordPressUI
import Yosemite

import class AutomatticTracks.CrashLogging

final class GroupedProductListSelectorDataSource: PaginatedListSelectorDataSource {
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

    typealias StorageModel = StorageProduct

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
        // no-op
    }

    func isSelected(model: Product) -> Bool {
        return model == selected
    }

    func configureCell(cell: ProductsTabProductTableViewCell, model: Product) {
        cell.selectionStyle = .default

        let viewModel = ProductsTabProductViewModel(product: model)
        cell.update(viewModel: viewModel, imageService: imageService)

        let deleteButton = UIButton(type: .detailDisclosure)
        deleteButton.setImage(.deleteCellImage, for: .normal)
        deleteButton.tintColor = .systemColor(.tertiaryLabel)
        deleteButton.on(.touchUpInside) { [weak self] _ in
            self?.deleteProduct(model)
        }
        cell.accessoryView = deleteButton
    }

    func sync(pageNumber: Int, pageSize: Int, onCompletion: ((Result<Bool, Error>) -> Void)?) {
        let action = ProductAction.retrieveProducts(siteID: siteID,
                                                    productIDs: groupedProductIDs,
                                                    pageNumber: pageNumber,
                                                    pageSize: pageSize) { result in
                                                        switch result {
                                                        case .success:
                                                            onCompletion?(.success(true))
                                                        case .failure(let error):
                                                            DDLogError("⛔️ Error synchronizing products: \(error)")
                                                            onCompletion?(.failure(error))
                                                        }
        }
        ServiceLocator.stores.dispatch(action)
    }
}

private extension GroupedProductListSelectorDataSource {
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

/// Displays a list of grouped products given a product's grouped product IDs, with a CTA to add more products.
final class GroupedProductsViewController: UIViewController {
    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private weak var addButtonBottomBorderView: UIView!
    @IBOutlet private weak var topContainerView: UIView!
    @IBOutlet private weak var productsContainerView: UIView!

    private let imageService: ImageService
    private let productID: Int64
    private let siteID: Int64

    private let dataSource: GroupedProductListSelectorDataSource

    private lazy var paginatedListSelector: PaginatedListSelectorViewController
        <GroupedProductListSelectorDataSource, Product, StorageProduct, ProductsTabProductTableViewCell> = {
            let noResultsPlaceholderText = NSLocalizedString("No products yet", comment: "Placeholder for editing linked products for a grouped product")
            let viewProperties = PaginatedListSelectorViewProperties(navigationBarTitle: nil,
                                                                     noResultsPlaceholderText: noResultsPlaceholderText,
                                                                     noResultsPlaceholderImage: .emptyProductsImage,
                                                                     noResultsPlaceholderImageTintColor: .primary)
            return PaginatedListSelectorViewController(viewProperties: viewProperties, dataSource: dataSource, onDismiss: { _ in })
    }()

    private var cancellable: ObservationToken?

    // Completion callback
    //
    typealias Completion = (_ groupedProductIDs: [Int64]) -> Void
    private let onCompletion: Completion

    init(product: Product, imageService: ImageService = ServiceLocator.imageService, completion: @escaping Completion) {
        self.productID = product.productID
        self.siteID = product.siteID
        self.dataSource = GroupedProductListSelectorDataSource(product: product)
        self.imageService = imageService
        self.onCompletion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureMainView()
        configureNavigation()
        configureAddButton()
        configureAddButtonBottomBorderView()
        configurePaginatedProductList()

        observeGroupedProductIDs()
    }
}

// MARK: - Actions
//
private extension GroupedProductsViewController {
    @objc func addTapped() {
        // TODO-2199: add products action
        let excludedProductIDs = dataSource.groupedProductIDs + [productID]
        let listSelector = ProductListSelectorViewController(excludedProductIDs: excludedProductIDs,
                                                             siteID: siteID) { [weak self] selectedProductIDs in
                                                                self?.dataSource.addProducts(selectedProductIDs)
                                                                self?.navigationController?.popViewController(animated: true)
        }
        show(listSelector, sender: self)
    }

    @objc func doneButtonTapped() {
        completeUpdating()
    }
}

// MARK: - Navigation actions handling
//
extension GroupedProductsViewController {
    override func shouldPopOnBackButton() -> Bool {
        if dataSource.hasUnsavedChanges() {
            presentBackNavigationActionSheet()
            return false
        }
        return true
    }

    override func shouldPopOnSwipeBack() -> Bool {
        return shouldPopOnBackButton()
    }

    private func completeUpdating() {
        onCompletion(dataSource.groupedProductIDs)
    }

    private func presentBackNavigationActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
    }
}

// MARK: - UI updates
//
private extension GroupedProductsViewController {
    func updateNavigationRightBarButtonItem() {
        if dataSource.hasUnsavedChanges() {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
}

// MARK: - UI configurations
//
private extension GroupedProductsViewController {
    func configureMainView() {
        view.backgroundColor = .basicBackground
    }

    func configureNavigation() {
        title = NSLocalizedString("Grouped Products", comment: "Navigation bar title for editing linked products for a grouped product")
        updateNavigationRightBarButtonItem()
        removeNavigationBackBarButtonText()
    }

    func configureAddButton() {
        addButton.setTitle(NSLocalizedString("Add Products", comment: "Action to add products to a grouped product on the Grouped Products screen"),
                           for: .normal)
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        addButton.applySecondaryButtonStyle()
    }

    func configureAddButtonBottomBorderView() {
        addButtonBottomBorderView.backgroundColor = .systemColor(.separator)
    }

    func configurePaginatedProductList() {
        addChild(paginatedListSelector)

        paginatedListSelector.view.translatesAutoresizingMaskIntoConstraints = false
        productsContainerView.addSubview(paginatedListSelector.view)
        paginatedListSelector.didMove(toParent: self)
        productsContainerView.pinSubviewToAllEdges(paginatedListSelector.view)
    }

    func observeGroupedProductIDs() {
        cancellable = dataSource.productIDs.subscribe { [weak self] productIDs in
            self?.paginatedListSelector.updateResultsController()
            self?.updateNavigationRightBarButtonItem()
        }
    }
}
