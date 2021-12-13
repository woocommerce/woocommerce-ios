import UIKit
import Yosemite

// MARK: - ProductShippingSettingsViewController
//
final class ProductShippingSettingsViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    /// Tracks whether the original shipping class has been retrieved, if the product has a shipping class.
    /// The shipping class picker action is blocked until the original shipping class has been retrieved.
    private var hasRetrievedShippingClassIfNeeded: Bool = false

    typealias Completion = (_ weight: String?,
        _ dimensions: ProductDimensions,
        _ shippingClassSlug: String?,
        _ shippingClassID: Int64?,
        _ hasUnsavedChanges: Bool) -> Void
    private let onCompletion: Completion

    private let viewModel: ProductShippingSettingsViewModel
    private let shippingSettingsService: ShippingSettingsService

    init(product: ProductFormDataModel,
         shippingSettingsService: ShippingSettingsService = ServiceLocator.shippingSettingsService,
         completion: @escaping Completion) {
        self.viewModel = ProductShippingSettingsViewModel(product: product)
        self.shippingSettingsService = shippingSettingsService
        self.onCompletion = completion

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        configureMainView()
        configureTableView()
        retrieveProductShippingClass()
        handleSwipeBackGesture()
    }
}

// MARK: - View Configuration
//
private extension ProductShippingSettingsViewController {

    func configureNavigationBar() {
        title = NSLocalizedString("Shipping", comment: "Product Shipping Settings navigation title")

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(completeUpdating))
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground

        registerTableViewCells()

        tableView.dataSource = self
        tableView.delegate = self
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }
    }

    func retrieveProductShippingClass() {
        let productHasShippingClass = viewModel.product.shippingClass?.isEmpty == false
        guard productHasShippingClass else {
            hasRetrievedShippingClassIfNeeded = true
            return
        }

        let action = ProductShippingClassAction
            .retrieveProductShippingClass(siteID: viewModel.product.siteID,
                                          remoteID: viewModel.product.shippingClassID) { [weak self] (shippingClass, error) in
                                            guard let shippingClass = shippingClass, error == nil else {
                                                return
                                            }
                                            self?.viewModel.onShippingClassRetrieved(shippingClass: shippingClass)
                                            self?.hasRetrievedShippingClassIfNeeded = true
                                            self?.tableView.reloadData()
        }
        ServiceLocator.stores.dispatch(action)
    }
}

// MARK: - Navigation actions handling
//
extension ProductShippingSettingsViewController {

    override func shouldPopOnBackButton() -> Bool {
        guard viewModel.hasUnsavedChanges() == false else {
            presentBackNavigationActionSheet()
            return false
        }
        return true
    }

    override func shouldPopOnSwipeBack() -> Bool {
        return shouldPopOnBackButton()
    }

    @objc private func completeUpdating() {
        viewModel.completeUpdating(onCompletion: onCompletion)
    }

    private func presentBackNavigationActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension ProductShippingSettingsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension ProductShippingSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let row = rowAtIndexPath(indexPath)
        switch row {
        case .shippingClass:
            guard hasRetrievedShippingClassIfNeeded else {
                return
            }
            let dataSource = PaginatedProductShippingClassListSelectorDataSource(product: viewModel.product, selected: viewModel.shippingClass)
            let navigationBarTitle = NSLocalizedString("Shipping classes", comment: "Navigation bar title of the Product shipping class selector screen")
            let noResultsPlaceholderText = NSLocalizedString("No shipping classes yet",
            comment: "The text on the placeholder overlay when there are no shipping classes on the Shipping Class list picker")
            let noResultsPlaceholderImage = UIImage.shippingClassListSelectorEmptyImage
            let viewProperties = PaginatedListSelectorViewProperties(navigationBarTitle: navigationBarTitle,
                                                                     noResultsPlaceholderText: noResultsPlaceholderText,
                                                                     noResultsPlaceholderImage: noResultsPlaceholderImage,
                                                                     noResultsPlaceholderImageTintColor: .gray(.shade20),
                                                                     tableViewStyle: .grouped)
            let selectorViewController =
                PaginatedListSelectorViewController(viewProperties: viewProperties,
                                                    dataSource: dataSource) { [weak self] selected in
                                                        guard let self = self else {
                                                            return
                                                        }
                                                        self.viewModel.handleShippingClassChange(selected)
                                                        self.tableView.reloadData()
            }
            navigationController?.pushViewController(selectorViewController, animated: true)
        default:
            return
        }
    }
}

// MARK: - Cell configuration
//
private extension ProductShippingSettingsViewController {
    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as UnitInputTableViewCell where row == .weight:
            configureWeight(cell: cell)
        case let cell as UnitInputTableViewCell where row == .length:
            configureLength(cell: cell)
        case let cell as UnitInputTableViewCell where row == .width:
            configureWidth(cell: cell)
        case let cell as UnitInputTableViewCell where row == .height:
            configureHeight(cell: cell)
        case let cell as TitleAndValueTableViewCell where row == .shippingClass:
            configureShippingClass(cell: cell)
        default:
            fatalError()
        }
    }

    func configureWeight(cell: UnitInputTableViewCell) {
        let cellViewModel = Product.createShippingWeightViewModel(weight: viewModel.weight,
                                                                  using: shippingSettingsService) { [weak self] value in
                                                                    self?.viewModel.handleWeightChange(value)
        }
        cell.configure(viewModel: cellViewModel)
    }

    func configureLength(cell: UnitInputTableViewCell) {
        let cellViewModel = Product.createShippingLengthViewModel(length: viewModel.length ?? "",
                                                                  using: shippingSettingsService) { [weak self] value in
                                                                    self?.viewModel.handleLengthChange(value)
        }
        cell.configure(viewModel: cellViewModel)
    }

    func configureWidth(cell: UnitInputTableViewCell) {
        let cellViewModel = Product.createShippingWidthViewModel(width: viewModel.width ?? "",
                                                                 using: shippingSettingsService) { [weak self] value in
                                                                    self?.viewModel.handleWidthChange(value)
        }
        cell.configure(viewModel: cellViewModel)
    }

    func configureHeight(cell: UnitInputTableViewCell) {
        let cellViewModel = Product.createShippingHeightViewModel(height: viewModel.height ?? "",
                                                                  using: shippingSettingsService) { [weak self] value in
                                                                    self?.viewModel.handleHeightChange(value)
        }
        cell.configure(viewModel: cellViewModel)
    }

    func configureShippingClass(cell: TitleAndValueTableViewCell) {
        let title = NSLocalizedString("Shipping class", comment: "Title of the cell in Product Shipping Settings > Shipping class")
        cell.updateUI(title: title, value: viewModel.shippingClass?.name)
        cell.accessoryType = .disclosureIndicator
    }
}

// MARK: - Convenience Methods
//
private extension ProductShippingSettingsViewController {

    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return viewModel.sections[indexPath.section].rows[indexPath.row]
    }
}

extension ProductShippingSettingsViewController {

    struct Section: Equatable {
        let rows: [Row]
    }

    enum Row: CaseIterable {
        case weight
        case length
        case width
        case height
        case shippingClass

        fileprivate var type: UITableViewCell.Type {
            switch self {
            case .weight, .length, .width, .height:
                return UnitInputTableViewCell.self
            case .shippingClass:
                return TitleAndValueTableViewCell.self
            }
        }

        fileprivate var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}
