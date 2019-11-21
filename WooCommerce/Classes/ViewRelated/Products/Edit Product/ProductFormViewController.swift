import UIKit
import Yosemite

/// The entry UI for adding/editing a Product.
final class ProductFormViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private var product: Product {
        didSet {
            viewModel = DefaultProductFormTableViewModel(product: product)
            tableViewDataSource = ProductFormTableViewDataSource(viewModel: viewModel)
            tableView.dataSource = tableViewDataSource
            tableView.reloadData()
        }
    }

    private var viewModel: ProductFormTableViewModel
    private var tableViewDataSource: ProductFormTableViewDataSource

    init(product: Product) {
        self.product = product
        self.viewModel = DefaultProductFormTableViewModel(product: product)
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
            case .description:
                editProductDescription()
            default:
                fatalError()
            }
        case .details:
            fatalError()
        }
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
        guard newDescription != product.fullDescription else {
            return
        }
        defer {
            navigationController?.popViewController(animated: true)
        }
        self.product = product.descriptionUpdated(description: newDescription)
    }
}
