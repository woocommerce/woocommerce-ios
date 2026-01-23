import Combine
import UIKit
import Yosemite

/// Displays a paginated list of products where the user can select.
final class ProductListSelectorViewController: UIViewController {
    private let excludedProductIDs: [Int64]
    private var productIDs: [Int64] = [] {
        didSet {
            if productIDs != oldValue {
                updateNavigationTitle(productIDs: productIDs)
                updateNavigationRightBarButtonItem(productIDs: productIDs)
            }
        }
    }

    private let siteID: Int64
    private var selectedProductIDsSubscription: AnyCancellable?

    private lazy var dataSource = ProductListMultiSelectorDataSource(siteID: siteID, excludedProductIDs: excludedProductIDs)

    private lazy var paginatedListSelector: PaginatedListSelectorViewController
        <ProductListMultiSelectorDataSource, Product, StorageProduct, ProductsTabProductTableViewCell> = {
            let viewProperties = PaginatedListSelectorViewProperties(navigationBarTitle: nil,
                                                                     noResultsPlaceholderText: Localization.noResultsPlaceholder,
                                                                     noResultsPlaceholderImage: .emptyProductsImage,
                                                                     noResultsPlaceholderImageTintColor: .primary,
                                                                     tableViewStyle: .plain,
                                                                     separatorStyle: .none)
            return PaginatedListSelectorViewController(viewProperties: viewProperties, dataSource: dataSource, onDismiss: { _ in })
    }()

    // Completion callback
    //
    typealias Completion = (_ selectedProductIDs: [Int64]) -> Void
    private let onCompletion: Completion

    init(excludedProductIDs: [Int64], siteID: Int64, onCompletion: @escaping Completion) {
        self.excludedProductIDs = excludedProductIDs
        self.siteID = siteID
        self.onCompletion = onCompletion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureMainView()
        configureNavigation()
        configurePaginatedProductListSelectorChildViewController()
    }
}

// MARK: - Actions
private extension ProductListSelectorViewController {
    @objc func doneButtonTapped() {
        completeUpdating()
    }

    @objc func searchButtonTapped() {
        let productIDsToExclude = (excludedProductIDs + productIDs).removingDuplicates()
        let searchProductsCommand = ProductListMultiSelectorSearchUICommand(siteID: siteID,
                                                                            excludedProductIDs: productIDsToExclude) { [weak self] productIDs in
                                                                                self?.didSelectProductsFromSearch(ids: productIDs)
        }
        let searchViewController = SearchViewController(storeID: siteID,
                                                        command: searchProductsCommand,
                                                        cellType: ProductsTabProductTableViewCell.self,
                                                        cellSeparator: .none)
        let navigationController = WooNavigationController(rootViewController: searchViewController)
        searchProductsCommand.configurePresentingViewControllerForDiscardChangesAlert(presentingViewController: navigationController)
        present(navigationController, animated: true, completion: nil)
    }

    func didSelectProductsFromSearch(ids: [Int64]) {
        dataSource.addProducts(ids)
        paginatedListSelector.reloadData()
    }
}

// MARK: - Navigation actions handling
//
extension ProductListSelectorViewController {
    override func shouldPopOnBackButton() -> Bool {
        if hasUnsavedChanges() {
            presentBackNavigationActionSheet()
            return false
        }
        return true
    }

    override func shouldPopOnSwipeBack() -> Bool {
        return shouldPopOnBackButton()
    }

    private func completeUpdating() {
        onCompletion(productIDs)
    }

    private func hasUnsavedChanges() -> Bool {
        return productIDs.isNotEmpty
    }

    private func presentBackNavigationActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
    }
}

// MARK: - UI updates
private extension ProductListSelectorViewController {
    func updateNavigationRightBarButtonItem(productIDs: [Int64]) {
        if productIDs.isEmpty {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(searchButtonTapped))
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
        }
    }

    func updateNavigationTitle(productIDs: [Int64]) {
        let title: String
        switch productIDs.count {
        case 0:
            title = Localization.titleWithoutSelectedProducts
        case 1:
            title = Localization.titleWithOneSelectedProduct
        default:
            title = String.localizedStringWithFormat(Localization.titleWithMultipleSelectedProductsFormat, productIDs.count)
        }
        navigationItem.title = title
    }
}

// MARK: - UI configurations
//
private extension ProductListSelectorViewController {
    func configureMainView() {
        view.backgroundColor = .basicBackground
    }

    func configureNavigation() {
        updateNavigationTitle(productIDs: productIDs)
        updateNavigationRightBarButtonItem(productIDs: productIDs)
    }

    func configurePaginatedProductListSelectorChildViewController() {
        observeSelectedProductIDs(observableProductIDs: dataSource.productIDs)

        addChild(paginatedListSelector)
        paginatedListSelector.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(paginatedListSelector.view)
        paginatedListSelector.didMove(toParent: self)

        view.pinSubviewToAllEdges(paginatedListSelector.view)
    }

    func observeSelectedProductIDs(observableProductIDs: AnyPublisher<[Int64], Never>) {
        selectedProductIDsSubscription = observableProductIDs.sink { [weak self] selectedProductIDs in
            self?.productIDs = selectedProductIDs
        }
    }
}

// MARK: - Constants
//
private extension ProductListSelectorViewController {
    enum Localization {
        static let noResultsPlaceholder = NSLocalizedString("No products yet",
                                                                comment: "Placeholder text when there are no products on the product list selector")
        static let titleWithoutSelectedProducts = NSLocalizedString("Add Products", comment: "Button text that appears in multiple screens to add products - in the order creation/editing form to add products to an order, and in the linked products settings to add upsell/cross-sell products to a product listing.")
        static let titleWithOneSelectedProduct =
            NSLocalizedString("1 Product Selected",
                              comment: "Text displayed on an action button and navigation bar title when exactly one product has been selected in product selection screens, specifically when adding products to orders or selecting products for linked product lists.")
        static let titleWithMultipleSelectedProductsFormat =
            NSLocalizedString("%ld Products Selected",
                              comment: "This text appears as the navigation bar title in the product selection screen when multiple products (2 or more) have been selected. The %ld placeholder will be replaced with the actual number of selected products.")
    }
}
