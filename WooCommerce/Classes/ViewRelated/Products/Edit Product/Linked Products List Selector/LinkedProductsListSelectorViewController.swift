import UIKit
import WordPressUI
import Yosemite
import Observables

/// Displays a paginated list of products given product IDs, with a CTA to add more products.
final class LinkedProductsListSelectorViewController: UIViewController {

    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private weak var addButtonBottomBorderView: UIView!
    @IBOutlet private weak var topContainerView: UIView!
    @IBOutlet private weak var productsContainerView: UIView!

    private let imageService: ImageService
    private let productID: Int64
    private let siteID: Int64
    private let viewConfiguration: LinkedProductsListSelectorViewController.ViewConfiguration

    private let dataSource: LinkedProductListSelectorDataSource

    private lazy var paginatedListSelector: PaginatedListSelectorViewController
        <LinkedProductListSelectorDataSource, Product, StorageProduct, ProductsTabProductTableViewCell> = {
            let viewProperties = PaginatedListSelectorViewProperties(navigationBarTitle: nil,
                                                                     noResultsPlaceholderText: Localization.noResultsPlaceholder,
                                                                     noResultsPlaceholderImage: .emptyProductsImage,
                                                                     noResultsPlaceholderImageTintColor: .primary,
                                                                     tableViewStyle: .plain,
                                                                     separatorStyle: .none)
            return PaginatedListSelectorViewController(viewProperties: viewProperties, dataSource: dataSource, onDismiss: { _ in })
    }()

    private var cancellable: ObservationToken?

    // Completion callback
    //
    typealias Completion = (_ linkedProductIDs: [Int64]) -> Void
    private let onCompletion: Completion

    init(product: Product,
         linkedProductIDs: [Int64],
         imageService: ImageService = ServiceLocator.imageService,
         viewConfiguration: ViewConfiguration,
         completion: @escaping Completion) {
        self.productID = product.productID
        self.siteID = product.siteID
        self.dataSource = LinkedProductListSelectorDataSource(product: product,
                                                              linkedProductIDs: linkedProductIDs,
                                                              trackingContext: viewConfiguration.trackingContext)
        self.imageService = imageService
        self.viewConfiguration = viewConfiguration
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

        observeLinkedProductIDs()
    }
}

// MARK: - Actions
//
private extension LinkedProductsListSelectorViewController {
    @objc func addTapped() {
        ServiceLocator.analytics.track(.connectedProductsList, withProperties: ["action": "add_tapped", "context": viewConfiguration.trackingContext])

        let excludedProductIDs = dataSource.linkedProductIDs + [productID]
        let listSelector = ProductListSelectorViewController(excludedProductIDs: excludedProductIDs,
                                                             siteID: siteID) { [weak self] selectedProductIDs in
                                                                if selectedProductIDs.isNotEmpty,
                                                                   let context = self?.viewConfiguration.trackingContext {
                                                                    ServiceLocator.analytics.track(.connectedProductsList,
                                                                                                   withProperties: ["action": "added", "context": context])
                                                                }
                                                                self?.dataSource.addProducts(selectedProductIDs)
                                                                self?.navigationController?.popViewController(animated: true)
        }
        show(listSelector, sender: self)
    }

    @objc func doneButtonTapped() {
        if dataSource.hasUnsavedChanges() {
            ServiceLocator.analytics.track(.connectedProductsList, withProperties: ["action": "done_tapped", "context": viewConfiguration.trackingContext])
        }

        completeUpdating()
    }
}

// MARK: - Navigation actions handling
//
extension LinkedProductsListSelectorViewController {
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
        onCompletion(dataSource.linkedProductIDs)
    }

    private func presentBackNavigationActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
    }
}

// MARK: - UI updates
//
private extension LinkedProductsListSelectorViewController {
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
private extension LinkedProductsListSelectorViewController {
    func configureMainView() {
        view.backgroundColor = .basicBackground
    }

    func configureNavigation() {
        title = viewConfiguration.title
        updateNavigationRightBarButtonItem()
    }

    func configureAddButton() {
        addButton.setTitle(Localization.addButton, for: .normal)
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

    func observeLinkedProductIDs() {
        cancellable = dataSource.productIDs.subscribe { [weak self] productIDs in
            self?.paginatedListSelector.updateResultsController()
            self?.updateNavigationRightBarButtonItem()
        }
    }
}

extension LinkedProductsListSelectorViewController {
    struct ViewConfiguration {
        let title: String
        let trackingContext: String

        init(title: String,
             trackingContext: String) {
            self.title = title
            self.trackingContext = trackingContext
        }
    }
}

private extension LinkedProductsListSelectorViewController {
    enum Localization {
        static let noResultsPlaceholder = NSLocalizedString("No products yet", comment: "Placeholder for the linked products list selector screen")
        static let addButton = NSLocalizedString("Add Products",
                                                 comment: "Action to add linked products to a product in the Linked Products List Selector screen")
    }
}
