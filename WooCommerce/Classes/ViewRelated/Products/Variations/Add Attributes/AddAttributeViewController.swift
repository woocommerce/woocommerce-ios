import UIKit
import Yosemite
import WordPressUI

final class AddAttributeViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    private let ghostTableView = UITableView()

    private let product: Product
    private let viewModel: AddAttributeViewModel

    /// Init
    ///
    init(product: Product) {
        self.product = product
        viewModel = AddAttributeViewModel(product: product)
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
        configureGhostTableView()
        registerTableViewCells()
        configureViewModel()
    }

}

// MARK: - View Configuration
//
private extension AddAttributeViewController {

    func configureNavigationBar() {
        title = Localization.titleView

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Localization.nextNavBarButton,
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(completeUpdating))
    }

    func configureMainView() {
        view.backgroundColor = .listForeground
    }

    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listForeground
        tableView.separatorStyle = .none

        registerTableViewCells()

        tableView.dataSource = self
        tableView.delegate = self
    }

    func configureGhostTableView() {
        view.addSubview(ghostTableView)
        ghostTableView.isHidden = true
        ghostTableView.translatesAutoresizingMaskIntoConstraints = false
        ghostTableView.pinSubviewToAllEdges(view)
        ghostTableView.backgroundColor = .listBackground
        ghostTableView.removeLastCellSeparator()
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }
        ghostTableView.registerNib(for: BasicTableViewCell.self)
    }

    func configureViewModel() {
        viewModel.performFetch()
        viewModel.observeProductAttributesListStateChanges { [weak self] syncState in
            switch syncState {
            case .initialized:
                break
            case .syncing:
                self?.displayGhostTableView()
            case .failed:
                self?.removeGhostTableView()
                self?.displaySyncingErrorNotice()
            case .synced:
                self?.removeGhostTableView()
            }
        }
    }
}

// MARK: - Placeholders & Errors
//
private extension AddAttributeViewController {

    /// Renders ghost placeholder product attributes.
    ///
    func displayGhostTableView() {
        let placeholderProductAttributesPerSection = [3]
        let options = GhostOptions(displaysSectionHeader: false,
                                   reuseIdentifier: BasicTableViewCell.reuseIdentifier,
                                   rowsPerSection: placeholderProductAttributesPerSection)
        ghostTableView.displayGhostContent(options: options,
                                           style: .wooDefaultGhostStyle)
        ghostTableView.isHidden = false
    }

    /// Removes ghost  placeholder product attributes.
    ///
    func removeGhostTableView() {
        tableView.reloadData()
        ghostTableView.removeGhostContent()
        ghostTableView.isHidden = true
    }

    /// Displays the Sync Error Notice.
    ///
    func displaySyncingErrorNotice() {
        let notice = Notice(title: Localization.syncErrorMessage, feedbackType: .error, actionTitle: Localization.retryAction) { [weak self] in
            self?.viewModel.performFetch()
        }

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension AddAttributeViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = viewModel.sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension AddAttributeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Cell configuration
//
private extension AddAttributeViewController {
    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as TextFieldTableViewCell where row == .attributeTextField:
            configureTextField(cell: cell)
        case let cell as BasicTableViewCell where row == .existingAttribute:
            configureAttribute(cell: cell, attribute: viewModel.fetchedAttributes[safe: indexPath.row])
        default:
            fatalError()
            break
        }
    }

    func configureTextField(cell: TextFieldTableViewCell) {

    }

    func configureAttribute(cell: BasicTableViewCell, attribute: ProductAttribute?) {
        cell.textLabel?.text = attribute?.name
    }
}


// MARK: - Navigation actions handling
//
extension AddAttributeViewController {

    @objc private func completeUpdating() {
        // TODO: to be implemented
    }
}

extension AddAttributeViewController {

    struct Section: Equatable {
        let header: String?
        let footer: String?
        let rows: [Row]
    }

    enum Row: CaseIterable {
        case attributeTextField
        case existingAttribute

        fileprivate var type: UITableViewCell.Type {
            switch self {
            case .attributeTextField:
                return TextFieldTableViewCell.self
            case .existingAttribute:
                return BasicTableViewCell.self
            }
        }

        fileprivate var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}

private extension AddAttributeViewController {
    enum Localization {
        static let titleView = NSLocalizedString("Add attribute", comment: "Add Product Attribute screen navigation title")
        static let nextNavBarButton = NSLocalizedString("Next", comment: "Next nav bar button title in Add Product Attribute screen")
        static let syncErrorMessage = NSLocalizedString("Unable to load product attributes", comment: "Load Product Attributes Action Failed")
        static let retryAction = NSLocalizedString("Retry", comment: "Retry Action")
    }
}
