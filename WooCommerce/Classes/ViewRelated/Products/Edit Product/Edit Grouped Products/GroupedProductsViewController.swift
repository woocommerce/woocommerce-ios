import UIKit
import WordPressUI
import Yosemite

import class AutomatticTracks.CrashLogging

/// Displays a list of grouped products given a product's grouped product IDs, with a CTA to add more products.
final class GroupedProductsViewController: UIViewController {
    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private weak var addButtonBottomBorderView: UIView!
    @IBOutlet private weak var topContainerView: UIView!
    @IBOutlet private weak var tableView: UITableView!

    private let imageService: ImageService
    private let viewModel: GroupedProductsViewModel
    private let productID: Int64
    private let siteID: Int64

    /// ResultsController: Surrounds us. Binds the galaxy together. And also, keeps the UITableView <> (Stored) Products in sync.
    ///
    private lazy var resultsController: ResultsController<StorageProduct> = {
        let resultsController = createResultsController()
        configureResultsController(resultsController) { [weak self] in
            self?.tableView.reloadData()
        }
        return resultsController
    }()

    private var groupedProducts: [Product] {
        resultsController.fetchedObjects.sorted { (lhs, rhs) -> Bool in
            let lhsProductID = lhs.productID
            let rhsProductID = rhs.productID
            let productIDs = viewModel.groupedProductIDs
            guard let lhsProductIDIndex = productIDs.firstIndex(of: lhsProductID), let rhsProductIDIndex = productIDs.firstIndex(of: rhsProductID) else {
                    return true
            }
            return lhsProductIDIndex < rhsProductIDIndex
        }
    }

    private var cancellable: ObservationToken?

    /// UI Active State
    ///
    private var state: State = .loading {
        didSet {
            didLeave(state: oldValue)
            didEnter(state: state)
        }
    }

    // Completion callback
    //
    typealias Completion = (_ groupedProductIDs: [Int64]) -> Void
    private let onCompletion: Completion

    init(product: Product, imageService: ImageService = ServiceLocator.imageService, completion: @escaping Completion) {
        self.viewModel = GroupedProductsViewModel(product: product)
        self.productID = product.productID
        self.siteID = product.siteID
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
        configureTableView()

        observeGroupedProductsResult()

        loadGroupedProducts(from: viewModel.groupedProductIDs)
    }
}

// MARK: - Actions
//
private extension GroupedProductsViewController {
    @objc func addTapped() {
        // TODO-2199: add products action
        let excludedProductIDs = viewModel.groupedProductIDs + [productID]
        let listSelector = ProductListSelectorViewController(excludedProductIDs: viewModel.groupedProductIDs,
                                                             siteID: siteID) { [weak self] selectedProductIDs in
                                                                self?.viewModel.addProducts(selectedProductIDs)
                                                                self?.navigationController?.popViewController(animated: true)
        }
        show(listSelector, sender: self)
    }

    @objc func doneButtonTapped() {
        completeUpdating()
    }

    func deleteTapped(product: Product) {
        viewModel.deleteProduct(product)
    }
}

// MARK: - Navigation actions handling
//
extension GroupedProductsViewController {
    override func shouldPopOnBackButton() -> Bool {
        if viewModel.hasUnsavedChanges() {
            presentBackNavigationActionSheet()
            return false
        }
        return true
    }

    override func shouldPopOnSwipeBack() -> Bool {
        return shouldPopOnBackButton()
    }

    private func completeUpdating() {
        onCompletion(viewModel.groupedProductIDs)
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
        if viewModel.hasUnsavedChanges() {
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

    func configureTableView() {
        tableView.dataSource = self

        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.rowHeight = UITableView.automaticDimension

        tableView.register(ProductsTabProductTableViewCell.self, forCellReuseIdentifier: ProductsTabProductTableViewCell.reuseIdentifier)

        // Removes extra header spacing in ghost content view.
        tableView.estimatedSectionHeaderHeight = 0
        tableView.sectionHeaderHeight = 0

        tableView.backgroundColor = .basicBackground
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
    }

    func observeGroupedProductsResult() {
        cancellable = viewModel.productIDs.subscribe { [weak self] result in
            switch result {
            case .failure(let error):
                self?.displayLoadingErrorNotice(error: error)
            case .success:
                self?.updateResultsController()
                self?.transitionToResultsUpdatedState()
                self?.updateNavigationRightBarButtonItem()
            }
        }
    }
}

// MARK: - ResultsController
//
private extension GroupedProductsViewController {
    func createResultsController() -> ResultsController<StorageProduct> {
        let storageManager = ServiceLocator.storageManager
        let productIDs = viewModel.groupedProductIDs
        let predicate = NSPredicate(format: "siteID == %lld AND productID IN %@", siteID, productIDs)
        let descriptor = NSSortDescriptor(keyPath: \StorageProduct.productID, ascending: true)

        return ResultsController<StorageProduct>(storageManager: storageManager,
                                                 matching: predicate,
                                                 sortedBy: [descriptor])
    }

    func configureResultsController(_ resultsController: ResultsController<StorageProduct>, onReload: @escaping () -> Void) {
        resultsController.onDidChangeContent = {
            onReload()
        }
        resultsController.onDidResetContent = {
            onReload()
        }
        do {
            try resultsController.performFetch()
        } catch {
            CrashLogging.logError(error)
        }
        tableView.reloadData()
    }

    func updateResultsController() {
        resultsController = createResultsController()
        configureResultsController(resultsController) { [weak self] in
            self?.tableView.reloadData()
        }
    }
}

// MARK: Networking
//
private extension GroupedProductsViewController {
    func loadGroupedProducts(from ids: [Int64]) {
        transitionToLoadingState()
        let action = ProductAction.retrieveProducts(siteID: siteID, productIDs: viewModel.groupedProductIDs) { [weak self] result in
            switch result {
            case .success:
                self?.transitionToResultsUpdatedState()
            case .failure(let error):
                self?.displayLoadingErrorNotice(error: error)
            }
        }
        ServiceLocator.stores.dispatch(action)
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension GroupedProductsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsController.fetchedObjects.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProductsTabProductTableViewCell.reuseIdentifier,
                                                       for: indexPath) as? ProductsTabProductTableViewCell else {
            fatalError()
        }

        let product = groupedProducts[indexPath.row]
        let viewModel = ProductsTabProductViewModel(product: product)
        cell.update(viewModel: viewModel, imageService: imageService)

        let deleteButton = UIButton(type: .detailDisclosure)
        deleteButton.setImage(.deleteCellImage, for: .normal)
        deleteButton.tintColor = .systemColor(.tertiaryLabel)
        deleteButton.on(.touchUpInside) { [weak self] _ in
            self?.deleteTapped(product: product)
        }
        cell.accessoryView = deleteButton

        return cell
    }
}

// MARK: - Finite State Machine Management
//
private extension GroupedProductsViewController {
    func didEnter(state: State) {
        switch state {
        case .noResultsPlaceholder:
            displayNoResultsOverlay()
        case .loading:
            displayPlaceholderProducts()
        default:
            break
        }
    }

    func didLeave(state: State) {
        switch state {
        case .noResultsPlaceholder:
            removeAllOverlays()
        case .loading:
            removePlaceholderProducts()
        default:
            break
        }
    }

    func transitionToLoadingState() {
        state = .loading
    }

    func transitionToResultsUpdatedState() {
        state = resultsController.numberOfObjects == 0 ? .noResultsPlaceholder: .success
    }
}

// MARK: - Placeholders
//
private extension GroupedProductsViewController {
    func displayPlaceholderProducts() {
        let options = GhostOptions(reuseIdentifier: ProductsTabProductTableViewCell.reuseIdentifier, rowsPerSection: Settings.placeholderRowsPerSection)
        tableView.displayGhostContent(options: options, style: .wooDefaultGhostStyle)
        topContainerView.isHidden = true
        resultsController.stopForwardingEvents()
    }

    func removePlaceholderProducts() {
        resultsController.startForwardingEvents(to: tableView)
        topContainerView.isHidden = false
        tableView.removeGhostContent()
        tableView.reloadData()
    }

    /// Displays the Error Notice.
    ///
    func displayLoadingErrorNotice(error: Error) {
        DDLogError("⛔️ Error loading grouped products for IDs (\(viewModel.groupedProductIDs)): \(error.localizedDescription)")

        let message = NSLocalizedString("Unable to load products",
                                        comment: "Error notice message when the app cannot load the linked products for a grouped product")
        let actionTitle = NSLocalizedString("Retry", comment: "Retry action for loading the linked products for a grouped product")
        let notice = Notice(title: message, feedbackType: .error, actionTitle: actionTitle) { [weak self] in
            guard let self = self else {
                return
            }
            self.loadGroupedProducts(from: self.viewModel.groupedProductIDs)
        }

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }

    /// Displays the overlay when there are no results.
    ///
    func displayNoResultsOverlay() {
        let overlayView: OverlayMessageView = OverlayMessageView.instantiateFromNib()
        overlayView.messageImage = nil
        overlayView.messageText = NSLocalizedString("No products yet",
                                                    comment: "The text on the placeholder overlay when there are no linked products for a grouped product")
        overlayView.actionVisible = false

        // Pins the overlay view to the bottom of the Add CTA.
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        NSLayoutConstraint.activate([
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.topAnchor.constraint(equalTo: addButtonBottomBorderView.bottomAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    /// Removes all of the the OverlayMessageView instances in the view hierarchy.
    ///
    func removeAllOverlays() {
        for subview in view.subviews where subview is OverlayMessageView {
            subview.removeFromSuperview()
        }
    }
}

// MARK: - Nested Types
//
private extension GroupedProductsViewController {
    enum Settings {
        static let placeholderRowsPerSection = [3]
    }

    enum State {
        case loading
        case noResultsPlaceholder
        case success
        case failure
    }
}
