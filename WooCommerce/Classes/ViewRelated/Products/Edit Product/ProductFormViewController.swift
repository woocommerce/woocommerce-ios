import UIKit
import Yosemite

/// The entry UI for adding/editing a Product.
final class ProductFormViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private var product: Product {
        didSet {
            viewModel = DefaultProductFormTableViewModel(product: product, currency: currency)
            tableViewDataSource = ProductFormTableViewDataSource(viewModel: viewModel)
            tableView.dataSource = tableViewDataSource
            tableView.reloadData()
        }
    }

    private var productUpdater: ProductUpdater {
        return product
    }

    private var viewModel: ProductFormTableViewModel
    private var tableViewDataSource: ProductFormTableViewDataSource

    private let currency: String

    init(product: Product, currency: String) {
        self.currency = currency
        self.product = product
        self.viewModel = DefaultProductFormTableViewModel(product: product, currency: currency)
        self.tableViewDataSource = ProductFormTableViewDataSource(viewModel: viewModel)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        configureTableView()
    }
}

private extension ProductFormViewController {
    func configureNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(updateProduct))
        removeNavigationBackBarButtonText()
    }

    func configureTableView() {
        registerTableViewCells()

        tableView.dataSource = tableViewDataSource
        tableView.delegate = self

        tableView.backgroundColor = .listBackground
        tableView.removeLastCellSeparator()

        tableView.reloadData()
    }

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        viewModel.sections.forEach { section in
            switch section {
            case .primaryFields(let rows):
                rows.forEach { row in
                    row.cellTypes.forEach { cellType in
                        tableView.register(cellType.loadNib(), forCellReuseIdentifier: cellType.reuseIdentifier)
                    }
                }
            default:
                return
            }
        }
    }
}

// MARK: Navigation actions
//
private extension ProductFormViewController {
    @objc func updateProduct() {
        let action = ProductAction.updateProduct(product: product) { [weak self] (product, error) in
            guard let product = product, error == nil else {
                let errorDescription = error?.localizedDescription ?? "No error specified"
                DDLogError("⛔️ Error updating Product: \(errorDescription)")
                self?.displayError(error: error)
                return
            }
            self?.product = product

            // TODO-1671: temporarily dismisses the Product form before the navigation is implemented.
            self?.dismiss(animated: true)
        }
        ServiceLocator.stores.dispatch(action)
    }

    func displayError(error: ProductUpdateError?) {
        let title = NSLocalizedString("Cannot update Product", comment: "The title of the alert when there is an error updating the product")

        let message: String?
        switch error {
        case .invalidSKU:
            message = NSLocalizedString("The SKU is used for another product or is invalid. Please check the inventory settings.",
                                        comment: "The message of the alert when there is an error updating the product SKU")
        default:
            message = nil
        }

        displayErrorAlert(title: title, message: message)
    }

    func displayErrorAlert(title: String?, message: String?) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        let cancel = UIAlertAction(title: NSLocalizedString(
            "OK",
            comment: "Dismiss button on the alert when there is an error updating the product"
        ), style: .cancel, handler: nil)
        alert.addAction(cancel)

        present(alert, animated: true, completion: nil)
    }
}

extension ProductFormViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let section = viewModel.sections[indexPath.section]
        switch section {
        case .primaryFields(let rows):
            let row = rows[indexPath.row]
            switch row {
            case .images:
                break
            case .name:
                editProductName()
            case .description:
                editProductDescription()
            }
        case .settings(let rows):
            let row = rows[indexPath.row]
            switch row {
            case .price:
                editPriceSettings()
            case .shipping:
                editShippingSettings()
            case .inventory:
                editInventorySettings()
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let section = viewModel.sections[section]
        switch section {
        case .settings:
            return Constants.settingsHeaderHeight
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = viewModel.sections[section]
        switch section {
        case .settings:
            let clearView = UIView(frame: .zero)
            clearView.backgroundColor = .clear
            return clearView
        default:
            return nil
        }
    }
}

// MARK: Action - Edit Product Name
//
private extension ProductFormViewController {
    func editProductName() {
        let placeholder = NSLocalizedString("Enter a title...", comment: "The text placeholder for the Text Editor screen")
        let navigationTitle = NSLocalizedString("Title", comment: "The navigation bar title of the Text editor screen.")
        let textViewController = TextViewViewController(text: product.name,
                                                        placeholder: placeholder,
                                                        navigationTitle: navigationTitle
        ) { [weak self] (newProductName) in
            self?.onEditProductNameCompletion(newName: newProductName ?? "")
        }

        navigationController?.pushViewController(textViewController, animated: true)
    }

    func onEditProductNameCompletion(newName: String) {
        defer {
            navigationController?.popViewController(animated: true)
        }
        guard newName != product.name else {
            return
        }
        self.product = productUpdater.nameUpdated(name: newName)
    }
}

// MARK: Action - Edit Product Description
//
private extension ProductFormViewController {
    func editProductDescription() {
        let editorViewController = EditorFactory().productDescriptionEditor(product: product) { [weak self] content in
            self?.onEditProductDescriptionCompletion(newDescription: content)
        }
        navigationController?.pushViewController(editorViewController, animated: true)
    }

    func onEditProductDescriptionCompletion(newDescription: String) {
        defer {
            navigationController?.popViewController(animated: true)
        }
        guard newDescription != product.fullDescription else {
            return
        }
        self.product = productUpdater.descriptionUpdated(description: newDescription)
    }
}

// MARK: Action - Edit Product Price Settings
//
private extension ProductFormViewController {
    func editPriceSettings() {
        let priceSettingsViewController = ProductPriceSettingsViewController(product: product)
        navigationController?.pushViewController(priceSettingsViewController, animated: true)
    }
}

// MARK: Action - Edit Product Shipping Settings
//
private extension ProductFormViewController {
    func editShippingSettings() {
        let shippingSettingsViewController = ProductShippingSettingsViewController(product: product) { [weak self] (weight, dimensions, shippingClass) in
            self?.onEditShippingSettingsCompletion(weight: weight, dimensions: dimensions, shippingClass: shippingClass)
        }
        navigationController?.pushViewController(shippingSettingsViewController, animated: true)
    }

    func onEditShippingSettingsCompletion(weight: String?, dimensions: ProductDimensions, shippingClass: ProductShippingClass?) {
        defer {
            navigationController?.popViewController(animated: true)
        }
        guard weight != self.product.weight || dimensions != self.product.dimensions || shippingClass != product.productShippingClass else {
            return
        }
        self.product = productUpdater.shippingSettingsUpdated(weight: weight, dimensions: dimensions, shippingClass: shippingClass)
    }
}

// MARK: Action - Edit Product Inventory Settings
//
private extension ProductFormViewController {
    func editInventorySettings() {
        let inventorySettingsViewController = ProductInventorySettingsViewController(product: product) { [weak self] data in
            self?.onEditInventorySettingsCompletion(data: data)
        }
        navigationController?.pushViewController(inventorySettingsViewController, animated: true)
    }

    func onEditInventorySettingsCompletion(data: ProductInventoryEditableData) {
        defer {
            navigationController?.popViewController(animated: true)
        }
        let originalData = ProductInventoryEditableData(product: product)
        guard originalData != data else {
            return
        }
        self.product = productUpdater.inventorySettingsUpdated(sku: data.sku,
                                                               manageStock: data.manageStock,
                                                               soldIndividually: data.soldIndividually,
                                                               stockQuantity: data.stockQuantity,
                                                               backordersSetting: data.backordersSetting,
                                                               stockStatus: data.stockStatus)
    }
}

// MARK: Action - Edit Product Description
//
private extension ProductFormViewController {
    enum Constants {
        static let settingsHeaderHeight = CGFloat(16)
    }
}
