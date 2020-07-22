import UIKit
import Yosemite
import WordPressUI

/// ProductTagsViewController: Displays the list of ProductTag associated to the active Site and to the specific product.
///
final class ProductTagsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    private let ghostTableView = UITableView()

    private var product: Product

    private let viewModel: ProductTagsViewModel

    // Completion callback
    //
    typealias Completion = (_ tags: [ProductTag]) -> Void
    private let onCompletion: Completion

    init(product: Product, completion: @escaping Completion) {
        self.product = product
        self.viewModel = ProductTagsViewModel(product: product)
        onCompletion = completion
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationBar()
        configureTableView()
        configureViewModel()
    }

}

// MARK: - View Configuration
//
private extension ProductTagsViewController {

    func configureNavigationBar() {
        title = NSLocalizedString("Tags", comment: "Product Tags navigation title")

        removeNavigationBackBarButtonText()
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        registerTableViewCells()
        tableView.dataSource = self
        tableView.delegate = self

        tableView.backgroundColor = .listBackground
        tableView.removeLastCellSeparator()
    }

    /// Since there is only a text field in this view, the text field become the first responder immediately when the view did appear
    ///
//    func configureTextFieldFirstResponder() {
//        if let indexPath = sections.indexPathForRow(.slug) {
//            let cell = tableView.cellForRow(at: indexPath) as? TextFieldTableViewCell
//            cell?.becomeFirstResponder()
//        }
//    }

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        tableView.register(TextFieldTableViewCell.loadNib(), forCellReuseIdentifier: TextFieldTableViewCell.reuseIdentifier)
        tableView.register(BasicTableViewCell.loadNib(), forCellReuseIdentifier: BasicTableViewCell.reuseIdentifier)
        ghostTableView.register(BasicTableViewCell.loadNib(), forCellReuseIdentifier: BasicTableViewCell.reuseIdentifier)
    }
}

// MARK: - Synchronize Tags
//
private extension ProductTagsViewController {
    func configureViewModel() {
        viewModel.performFetch()
        viewModel.observeTagListStateChanges { [weak self] syncState in
            switch syncState {
            case .initialized:
                break
            case .syncing:
                self?.displayGhostTableView()
            case let .failed(retryToken):
                self?.removeGhostTableView()
                self?.displaySyncingErrorNotice(retryToken: retryToken)
            case .synced:
                self?.removeGhostTableView()
            }
        }
    }
}

// MARK: - Placeholders & Errors
//
private extension ProductTagsViewController {

    /// Renders ghost placeholder categories.
    ///
    func displayGhostTableView() {
        let placeholderTagsPerSection = [3]
        let options = GhostOptions(displaysSectionHeader: false,
                                   reuseIdentifier: BasicTableViewCell.reuseIdentifier,
                                   rowsPerSection: placeholderTagsPerSection)
        ghostTableView.displayGhostContent(options: options,
                                           style: .wooDefaultGhostStyle)
        ghostTableView.isHidden = false
    }

    /// Removes ghost  placeholder categories.
    ///
    func removeGhostTableView() {
        tableView.reloadData()
        ghostTableView.removeGhostContent()
        ghostTableView.isHidden = true
    }

    /// Displays the Sync Error Notice.
    ///
    func displaySyncingErrorNotice(retryToken: ProductTagsViewModel.RetryToken) {
        let message = NSLocalizedString("Unable to load tags", comment: "Load Product Tags Action Failed")
        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
        let notice = Notice(title: message, feedbackType: .error, actionTitle: actionTitle) { [weak self] in
            self?.viewModel.retryTagSynchronization(retryToken: retryToken)
        }

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension ProductTagsViewController: UITableViewDataSource {

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
extension ProductTagsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Support for UITableViewDataSource
//
private extension ProductTagsViewController {
    /// Configure cellForRowAtIndexPath:
    ///
    func configure(_ cell: UITableViewCell, for row: ProductTagsViewModel.Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as TextFieldTableViewCell:
            configureTextField(cell: cell)
        case let cell as BasicTableViewCell:
            configureTag(cell: cell)
        default:
            fatalError("Unidentified product slug row type")
        }
    }

    func configureTextField(cell: TextFieldTableViewCell) {
        cell.accessoryType = .none

        let placeholder = NSLocalizedString("Tags", comment: "Placeholder in the Product Tag row on Edit Product Tags screen.")
        let tags: String = viewModel.selectedTags.map { $0.name }.joined(separator: ",")
        let viewModelCell = TextFieldTableViewCell.ViewModel(text: String(tags),
                                                             placeholder: placeholder,
                                                             onTextChange: { newTags in
            //if let newTags = newTags {
                //self?.productSettings.slug = newName
            //}
            }, onTextDidBeginEditing: {
                //TODO: Add analytics track
        }, inputFormatter: nil, keyboardType: .default)
        cell.configure(viewModel: viewModelCell)
        cell.applyStyle(style: .body)
    }

    func configureTag(cell: BasicTableViewCell) {

    }
}
