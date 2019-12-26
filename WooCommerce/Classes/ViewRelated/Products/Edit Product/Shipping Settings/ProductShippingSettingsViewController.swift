import UIKit
import Yosemite

// MARK: - ProductShippingSettingsViewController
//
final class ProductShippingSettingsViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    // Editable data
    //
    private var weight: String?
    private var length: String?
    private var width: String?
    private var height: String?
    private var shippingClassSlug: String? {
        return shippingClass?.slug
    }

    // Internal data for rendering UI
    //
    private var shippingClass: ProductShippingClass?

    /// Table Sections to be rendered
    ///
    private let sections: [Section] = [
        Section(rows: [.weight, .length, .width, .height]),
        Section(rows: [.shippingClass])
    ]

    typealias Completion = (_ weight: String?, _ dimensions: ProductDimensions, _ shippingClass: ProductShippingClass?) -> Void
    private let onCompletion: Completion

    private let product: Product
    private let shippingSettingsService: ShippingSettingsService

    init(product: Product,
         shippingSettingsService: ShippingSettingsService = ServiceLocator.shippingSettingsService,
         completion: @escaping Completion) {
        self.product = product
        self.shippingSettingsService = shippingSettingsService
        self.onCompletion = completion

        self.weight = product.weight
        self.length = product.dimensions.length
        self.width = product.dimensions.width
        self.height = product.dimensions.height

        self.shippingClass = product.productShippingClass

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
            tableView.register(row.type.loadNib(), forCellReuseIdentifier: row.reuseIdentifier)
        }
    }

    func retrieveProductShippingClass() {
        guard let shippingClass = shippingClass else {
            return
        }

        let action = ProductShippingClassAction
            .retrieveProductShippingClass(siteID: Int64(product.siteID),
                                          remoteID: shippingClass.shippingClassID) { [weak self] (shippingClass, error) in
            self?.shippingClass = shippingClass
            self?.tableView.reloadData()
        }
        ServiceLocator.stores.dispatch(action)
    }
}

// MARK: - Navigation actions handling
//
private extension ProductShippingSettingsViewController {
    @objc func completeUpdating() {
        let dimensions = ProductDimensions(length: length ?? "",
                                           width: width ?? "",
                                           height: height ?? "")
        onCompletion(weight, dimensions, shippingClass)
    }
}

// MARK: - Input changes handling
//
private extension ProductShippingSettingsViewController {
    func handleWeightChange(_ weight: String?) {
        self.weight = weight
    }

    func handleLengthChange(_ length: String?) {
        self.length = length
    }

    func handleWidthChange(_ width: String?) {
        self.width = width
    }

    func handleHeightChange(_ height: String?) {
        self.height = height
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension ProductShippingSettingsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
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
            let dataSource = PaginatedProductShippingClassListSelectorDataSource(product: product, selected: shippingClass)
            let navigationBarTitle = NSLocalizedString("Shipping classes", comment: "Navigation bar title of the Product shipping class selector screen")
            let noResultsPlaceholderText = NSLocalizedString("No shipping classes yet",
            comment: "The text on the placeholder overlay when there are no shipping classes on the Shipping Class list picker")
            let noResultsPlaceholderImage = UIImage.shippingClassListSelectorEmptyImage
            let viewProperties = PaginatedListSelectorViewProperties(navigationBarTitle: navigationBarTitle,
                                                                     noResultsPlaceholderText: noResultsPlaceholderText,
                                                                     noResultsPlaceholderImage: noResultsPlaceholderImage)
            let selectorViewController =
                PaginatedListSelectorViewController(viewProperties: viewProperties,
                                                    dataSource: dataSource) { [weak self] selected in
                                                        guard let self = self else {
                                                            return
                                                        }
                                                        self.shippingClass = selected
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
        case let cell as SettingTitleAndValueTableViewCell where row == .shippingClass:
            configureShippingClass(cell: cell)
        default:
            fatalError()
        }
    }

    func configureWeight(cell: UnitInputTableViewCell) {
        let viewModel = Product.createShippingWeightViewModel(weight: weight,
                                                              using: shippingSettingsService) { [weak self] value in
                                                                self?.handleWeightChange(value)
        }
        cell.configure(viewModel: viewModel)
    }

    func configureLength(cell: UnitInputTableViewCell) {
        let viewModel = Product.createShippingLengthViewModel(length: length ?? "",
                                                              using: shippingSettingsService) { [weak self] value in
                                                                self?.handleLengthChange(value)
        }
        cell.configure(viewModel: viewModel)
    }

    func configureWidth(cell: UnitInputTableViewCell) {
        let viewModel = Product.createShippingWidthViewModel(width: width ?? "",
                                                             using: shippingSettingsService) { [weak self] value in
                                                                self?.handleWidthChange(value)
        }
        cell.configure(viewModel: viewModel)
    }

    func configureHeight(cell: UnitInputTableViewCell) {
        let viewModel = Product.createShippingHeightViewModel(height: height ?? "",
                                                              using: shippingSettingsService) { [weak self] value in
                                                                self?.handleHeightChange(value)
        }
        cell.configure(viewModel: viewModel)
    }

    func configureShippingClass(cell: SettingTitleAndValueTableViewCell) {
        let title = NSLocalizedString("Shipping class", comment: "Title of the cell in Product Shipping Settings > Shipping class")
        cell.updateUI(title: title, value: shippingClass?.name)
        cell.accessoryType = .disclosureIndicator
    }
}

// MARK: - Convenience Methods
//
private extension ProductShippingSettingsViewController {

    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }
}

private extension ProductShippingSettingsViewController {

    struct Section {
        let rows: [Row]
    }

    enum Row: CaseIterable {
        case weight
        case length
        case width
        case height
        case shippingClass

        var type: UITableViewCell.Type {
            switch self {
            case .weight, .length, .width, .height:
                return UnitInputTableViewCell.self
            case .shippingClass:
                return SettingTitleAndValueTableViewCell.self
            }
        }

        var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}
