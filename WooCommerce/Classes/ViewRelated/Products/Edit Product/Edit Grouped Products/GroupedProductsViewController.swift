import UIKit
import WordPressUI
import Yosemite

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
