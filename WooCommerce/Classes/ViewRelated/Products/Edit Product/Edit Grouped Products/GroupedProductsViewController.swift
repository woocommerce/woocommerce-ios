import UIKit
import WordPressUI
import Yosemite

/// Displays a list of grouped products given a product's grouped product IDs, with a CTA to add more products.
final class GroupedProductsViewController: UIViewController {
    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private weak var addButtonBottomBorderView: UIView!
    @IBOutlet private weak var tableView: UITableView!

    private let imageService: ImageService

    private let product: Product
    private var groupedProducts: [Product] = []
    private var groupedProductIDs: [Int64]

    /// UI Active State
    ///
    private var state: State = .loading {
        didSet {
            didLeave(state: oldValue)
            didEnter(state: state)
        }
    }

    init(product: Product, imageService: ImageService = ServiceLocator.imageService) {
        self.product = product
        self.groupedProductIDs = product.groupedProducts
        self.imageService = imageService
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

        loadGroupedProducts(from: groupedProductIDs)
    }
}

// MARK: - Actions
//
private extension GroupedProductsViewController {
    @objc func addTapped() {
        // TODO-JC
    }

    @objc func doneButtonTapped() {
        // TODO-JC
    }

    func deleteTapped(product: Product) {
        // TODO-JC
        groupedProducts.removeAll(where: { $0.productID == product.productID })
        tableView.reloadData()
    }
}

// MARK: - UI configurations
//
private extension GroupedProductsViewController {
    func configureMainView() {
        view.backgroundColor = .basicBackground
    }

    func configureNavigation() {
        title = NSLocalizedString("Grouped Products", comment: "The navigation bar title for editing linked products for a grouped product")

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))

        removeNavigationBackBarButtonText()
    }

    func configureAddButton() {
        addButton.setTitle(NSLocalizedString("Add Product", comment: "Action to add products to a grouped product on the Grouped Products screen"), for: .normal)
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
}

// MARK: Networking
//
private extension GroupedProductsViewController {
    func loadGroupedProducts(from ids: [Int64]) {
        transitionToLoadingState()
        let action = ProductAction.retrieveProducts(siteID: product.siteID, productIDs: ids) { [weak self] result in
            switch result {
            case .success(let products):
                self?.groupedProducts = products
                self?.tableView.reloadData()
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
        return groupedProducts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProductsTabProductTableViewCell.reuseIdentifier,
                                                       for: indexPath) as? ProductsTabProductTableViewCell else {
            fatalError()
        }

        let productID = groupedProductIDs[indexPath.row]
        guard let product = groupedProducts.first(where: { $0.productID == productID }) else {
            fatalError("Expected product of ID \(productID) from: \(groupedProducts)")
        }
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
        case .failure:
            break
        case .success:
            break
        }
    }

    func didLeave(state: State) {
        switch state {
        case .noResultsPlaceholder:
            removeAllOverlays()
        case .loading:
            removePlaceholderProducts()
        case .failure:
            break
        case .success:
            break
        }
    }

    func transitionToLoadingState() {
        state = .loading
    }

    func transitionToResultsUpdatedState() {
        state = groupedProducts.isEmpty ? .noResultsPlaceholder: .success
    }
}

// MARK: - Placeholders
//
private extension GroupedProductsViewController {
    /// Renders the Placeholder Orders: For safety reasons, we'll also halt ResultsController <> UITableView glue.
    ///
    func displayPlaceholderProducts() {
        let options = GhostOptions(reuseIdentifier: ProductsTabProductTableViewCell.reuseIdentifier, rowsPerSection: Settings.placeholderRowsPerSection)
        tableView.displayGhostContent(options: options, style: .wooDefaultGhostStyle)
    }

    /// Removes the Placeholder Products (and restores the ResultsController <> UITableView link).
    ///
    func removePlaceholderProducts() {
        tableView.removeGhostContent()
        tableView.reloadData()
    }

    /// Displays the Error Notice.
    ///
    func displayLoadingErrorNotice(error: Error) {
        DDLogError("⛔️ Error loading grouped products for IDs (\(groupedProductIDs)): \(error.localizedDescription)")

        let message = NSLocalizedString("Unable to load products",
                                        comment: "Error notice message when the app cannot load the linked products for a grouped product")
        let actionTitle = NSLocalizedString("Retry", comment: "Retry action for loading the linked products for a grouped product")
        let notice = Notice(title: message, feedbackType: .error, actionTitle: actionTitle) { [weak self] in
            guard let self = self else {
                return
            }
            self.loadGroupedProducts(from: self.groupedProductIDs)
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
