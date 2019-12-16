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
    private var shippingClassSlug: String?

    /// Table Sections to be rendered
    ///
    private let sections: [Section] = [
        Section(rows: [.weight, .length, .width, .height]),
        Section(rows: [.shippingClass])
    ]

    private let product: Product
    private let shippingSettingsService: ShippingSettingsService

    init(product: Product,
         shippingSettingsService: ShippingSettingsService = ServiceLocator.shippingSettingsService) {
        self.product = product
        self.shippingSettingsService = shippingSettingsService

        self.weight = product.weight
        self.length = product.dimensions.length
        self.width = product.dimensions.width
        self.height = product.dimensions.height
        self.shippingClassSlug = product.shippingClass

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
    }
}

// MARK: - View Configuration
//
private extension ProductShippingSettingsViewController {

    func configureNavigationBar() {
        title = NSLocalizedString("Shipping", comment: "Product Shipping Settings navigation title")
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
}

// MARK: - Input changes handling
//
private extension ProductShippingSettingsViewController {
    func handleWeightChange(weight: String?) {
        self.weight = weight
    }

    func handleLengthChange(weight: String?) {
        self.length = weight
    }

    func handleWidthChange(weight: String?) {
        self.width = weight
    }

    func handleHeightChange(weight: String?) {
        self.height = weight
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
        // TODO-1422: navigate to shipping class selector.
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
        let viewModel = product.createShippingWeightCellViewModel(shippingSettingsService: shippingSettingsService) { [weak self] value in
            self?.handleWeightChange(weight: value)
        }
        cell.configure(viewModel: viewModel)
    }

    func configureLength(cell: UnitInputTableViewCell) {
        let viewModel = product.createShippingLengthCellViewModel(shippingSettingsService: shippingSettingsService) { [weak self] value in
            self?.handleLengthChange(weight: value)
        }
        cell.configure(viewModel: viewModel)
    }

    func configureWidth(cell: UnitInputTableViewCell) {
        let viewModel = product.createShippingWidthCellViewModel(shippingSettingsService: shippingSettingsService) { [weak self] value in
            self?.handleWidthChange(weight: value)
        }
        cell.configure(viewModel: viewModel)
    }

    func configureHeight(cell: UnitInputTableViewCell) {
        let viewModel = product.createShippingHeightCellViewModel(shippingSettingsService: shippingSettingsService) { [weak self] value in
            self?.handleHeightChange(weight: value)
        }
        cell.configure(viewModel: viewModel)
    }

    func configureShippingClass(cell: SettingTitleAndValueTableViewCell) {
        let title = NSLocalizedString("Shipping class", comment: "Title of the cell in Product Shipping Settings > Shipping class")
        // TODO-1422: update slug to name once the model is fetched
        cell.updateUI(title: title, value: product.shippingClass)
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
