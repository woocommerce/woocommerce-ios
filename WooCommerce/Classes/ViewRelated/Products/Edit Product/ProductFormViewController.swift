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
                return
            }
            self?.product = product

            // Temporarily dismisses the Product form before the navigation is implemented.
            self?.dismiss(animated: true)
        }
        ServiceLocator.stores.dispatch(action)
    }
}

extension ProductFormViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let section = viewModel.sections[indexPath.section]
        switch section {
        case .images:
            fatalError()
        case .primaryFields(let rows):
            let row = rows[indexPath.row]
            switch row {
            case .name:
                editProductName()
            case .description:
                editProductDescription()
            }
        case .settings:
            // TODO-1422: Shipping Settings
            // TODO-1423: Price Settings
            // TODO-1424: Inventory Settings
            return
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

// MARK: Action - Edit Product Description
//
private extension ProductFormViewController {
    enum Constants {
        static let settingsHeaderHeight = CGFloat(16)
    }
}
