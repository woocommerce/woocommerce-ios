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
        let updateTitle = NSLocalizedString("Update", comment: "Action for updating a Product remotely")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: updateTitle, style: .done, target: self, action: #selector(updateProduct))
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
        let title = NSLocalizedString("Publishing your product...", comment: "Title of the in-progress UI while updating the Product remotely")
        let message = NSLocalizedString("Please wait while we publish this product to your store",
                                        comment: "Message of the in-progress UI while updating the Product remotely")
        let viewProperties = InProgressViewProperties(title: title, message: message)
        let inProgressViewController = InProgressViewController(viewProperties: viewProperties)
        navigationController?.present(inProgressViewController, animated: true, completion: nil)

        let action = ProductAction.updateProduct(product: product) { [weak self] (product, error) in
            guard let product = product, error == nil else {
                let errorDescription = error?.localizedDescription ?? "No error specified"
                DDLogError("⛔️ Error updating Product: \(errorDescription)")
                self?.displayError(error: error)
                return
            }
            self?.product = product

            // Dismisses the in-progress UI.
            self?.navigationController?.dismiss(animated: true, completion: nil)
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

    func editPriceSettings() {
        let priceSettingsViewController = ProductPriceSettingsViewController(product: product)
        navigationController?.pushViewController(priceSettingsViewController, animated: true)
    }

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
        let inventorySettingsViewController = ProductInventorySettingsViewController(product: product)
        navigationController?.pushViewController(inventorySettingsViewController, animated: true)
    }
}

// MARK: Action - Edit Product Description
//
private extension ProductFormViewController {
    enum Constants {
        static let settingsHeaderHeight = CGFloat(16)
    }
}
