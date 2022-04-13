import Combine
import UIKit
import Yosemite

/// Displays a paginated list of products where the user can select.
final class ProductListSelectorViewController: UIViewController {
    /// Whether the view is for selecting or excluding products
    private let isExclusion: Bool

    private let excludedProductIDs: [Int64]
    private var productIDs: [Int64] = [] {
        didSet {
            if productIDs != oldValue {
                updateDoneButton(productIDs: productIDs)
            }
        }
    }

    private let siteID: Int64
    private var selectedProductIDsSubscription: AnyCancellable?
    private var filters: FilterProductListViewModel.Filters = FilterProductListViewModel.Filters()

    private lazy var dataSource = ProductListMultiSelectorDataSource(siteID: siteID, excludedProductIDs: excludedProductIDs)

    private lazy var paginatedListSelector: PaginatedListSelectorViewController
        <ProductListMultiSelectorDataSource, Product, StorageProduct, ProductListSelectorTableViewCell> = {
            let viewProperties = PaginatedListSelectorViewProperties(navigationBarTitle: nil,
                                                                     noResultsPlaceholderText: Localization.noResultsPlaceholder,
                                                                     noResultsPlaceholderImage: .emptyProductsImage,
                                                                     noResultsPlaceholderImageTintColor: .primary,
                                                                     tableViewStyle: .plain,
                                                                     separatorStyle: .none)
            return PaginatedListSelectorViewController(viewProperties: viewProperties, dataSource: dataSource, onDismiss: { _ in })
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var doneButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        button.applyPrimaryButtonStyle()
        return button
    }()

    private lazy var doneButtonContainer: UIView = {
        let buttonContainer = UIView(frame: .zero)
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addSubview(doneButton)
        buttonContainer.pinSubviewToSafeArea(doneButton, insets: Constants.doneButtonInsets)
        return buttonContainer
    }()

    private lazy var topBarContainer: UIView = {
        let container = UIView(frame: .zero)
        container.translatesAutoresizingMaskIntoConstraints = false

        let selectAllButton = UIButton()
        selectAllButton.setTitle(Localization.selectAll, for: .normal)
        selectAllButton.translatesAutoresizingMaskIntoConstraints = false
        selectAllButton.addTarget(self, action: #selector(selectAllProducts), for: .touchUpInside)
        selectAllButton.applyLinkButtonStyle()
        selectAllButton.contentEdgeInsets = .zero
        container.addSubview(selectAllButton)

        let filterButton = UIButton()
        filterButton.setTitle(Localization.filter, for: .normal)
        filterButton.translatesAutoresizingMaskIntoConstraints = false
        filterButton.addTarget(self, action: #selector(showFilter), for: .touchUpInside)
        filterButton.applyLinkButtonStyle()
        filterButton.contentEdgeInsets = .zero
        container.addSubview(filterButton)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: Constants.topBarHeight),
            selectAllButton.leadingAnchor.constraint(equalTo: container.safeLeadingAnchor, constant: Constants.topBarMargin),
            selectAllButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            container.safeTrailingAnchor.constraint(equalTo: filterButton.trailingAnchor, constant: Constants.topBarMargin),
            filterButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        return container
    }()

    // Completion callback
    //
    typealias Completion = (_ selectedProductIDs: [Int64]) -> Void
    private let onCompletion: Completion

    init(excludedProductIDs: [Int64], siteID: Int64, isExclusion: Bool = false, onCompletion: @escaping Completion) {
        self.excludedProductIDs = excludedProductIDs
        self.siteID = siteID
        self.isExclusion = isExclusion
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
        configureContentStackView()
    }
}

// MARK: - Actions
private extension ProductListSelectorViewController {
    @objc func selectAllProducts() {
        // TODO
    }

    @objc func showFilter() {
        let viewModel = FilterProductListViewModel(filters: filters, siteID: siteID)
        let filterProductListViewController = FilterListViewController(viewModel: viewModel, onFilterAction: { [weak self] filters in
            ServiceLocator.analytics.track(.productFilterListShowProductsButtonTapped, withProperties: ["filters": filters.analyticsDescription])
            self?.filters = filters
        }, onClearAction: {
            ServiceLocator.analytics.track(.productFilterListClearMenuButtonTapped)
        }, onDismissAction: {
            ServiceLocator.analytics.track(.productFilterListDismissButtonTapped)
        })
        present(filterProductListViewController, animated: true, completion: nil)
    }

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

    func updateDoneButton(productIDs: [Int64]) {
        let itemCount = String.pluralize(productIDs.count, singular: Localization.singleProduct, plural: Localization.multipleProducts)
        let format = isExclusion ? Localization.exclusionActionTitle : Localization.selectionActionTitle
        let title = String.localizedStringWithFormat(format, itemCount)
        doneButton.setTitle(title, for: .normal)
        doneButtonContainer.isHidden = productIDs.isEmpty
    }
}

// MARK: - UI configurations
//
private extension ProductListSelectorViewController {
    func configureMainView() {
        view.backgroundColor = .basicBackground
    }

    func configureNavigation() {
        navigationItem.title = isExclusion ? Localization.exclusionTitle : Localization.selectionTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(searchButtonTapped))
    }

    func configureContentStackView() {
        contentStackView.addArrangedSubview(topBarContainer)

        observeSelectedProductIDs(observableProductIDs: dataSource.productIDs)
        addChild(paginatedListSelector)
        paginatedListSelector.view.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(paginatedListSelector.view)
        paginatedListSelector.didMove(toParent: self)

        contentStackView.addArrangedSubview(doneButtonContainer)
        doneButtonContainer.isHidden = true // Hide the button initially since no product is selected yet.

        view.addSubview(contentStackView)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor),
            view.safeTopAnchor.constraint(equalTo: contentStackView.safeTopAnchor),
            view.safeBottomAnchor.constraint(equalTo: contentStackView.safeBottomAnchor)
        ])
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
    enum Constants {
        static let doneButtonInsets = UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 16)
        static let topBarMargin: CGFloat = 16
        static let topBarHeight: CGFloat = 46
    }

    enum Localization {
        static let noResultsPlaceholder = NSLocalizedString("No products yet",
                                                                comment: "Placeholder text when there are no products on the product list selector")
        static let selectionTitle = NSLocalizedString("Select products", comment: "Title for the Select Products screen")
        static let exclusionTitle = NSLocalizedString("Exclude products", comment: "Title of the Exclude Products screen")
        static let selectionActionTitle = NSLocalizedString(
            "Select %1$@",
            comment: "Title of the action button on the Select Products screen" +
            "Reads like: Select 1 Product"
        )
        static let exclusionActionTitle = NSLocalizedString(
            "Exclude %1$@",
            comment: "Title of the action button on the Exclude Products screen" +
            "Reads like: Exclude 1 Product"
        )
        static let singleProduct = NSLocalizedString("%1$d Product", comment: "Count of one product")
        static let multipleProducts = NSLocalizedString("%1$d Products", comment: "Count of several products, reads like: 2 Products")
        static let selectAll = NSLocalizedString("Select All", comment: "Button to select all products on the product list selector")
        static let filter = NSLocalizedString("Filter", comment: "Button to filter products on the product list selector")
    }
}
