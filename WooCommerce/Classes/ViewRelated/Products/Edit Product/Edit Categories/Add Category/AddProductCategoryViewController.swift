import UIKit
import Networking
import Yosemite

/// AddProductCategoryViewController: Add a new category associated to the active site.
///
final class AddProductCategoryViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private let siteID: Int64

    /// Table Sections to be rendered
    ///
    private let sections: [Section] = [Section(rows: [.title]), Section(rows: [.parentCategory])]

    /// New category title
    ///
    private var newCategoryTitle: String? {
        didSet {
            navigationItem.rightBarButtonItem?.isEnabled = newCategoryTitle?.isNotEmpty == true
        }
    }

    /// Selected parent category
    ///
    private var selectedParentCategory: ProductCategory? {
        didSet {
            tableView.reloadData()
        }
    }

    /// Keyboard management
    ///
    private lazy var keyboardFrameObserver: KeyboardFrameObserver = KeyboardFrameObserver { [weak self] keyboardFrame in
        self?.handleKeyboardFrameUpdate(keyboardFrame: keyboardFrame)
    }

    // Completion callback
    //
    typealias Completion = (_ category: ProductCategory) -> Void
    private let onCompletion: Completion

    init(siteID: Int64, completion: @escaping Completion) {
        self.siteID = siteID
        onCompletion = completion
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureMainView()
        configureTableView()
        startListeningToNotifications()
    }
}

// MARK: - View Configuration
//
private extension AddProductCategoryViewController {

    func configureNavigationBar() {
        title = Strings.titleView

        addCloseNavigationBarButton(title: Strings.cancelButton)
        configureRightBarButtomitemAsSave()
        removeNavigationBackBarButtonText()
    }

    func configureRightBarButtomitemAsSave() {
        navigationItem.setRightBarButton(UIBarButtonItem(title: Strings.saveButton,
                                                         style: .done,
                                                         target: self,
                                                         action: #selector(saveNewCategory)),
                                         animated: true)
        navigationItem.rightBarButtonItem?.isEnabled = newCategoryTitle?.isNotEmpty == true
    }

    func configureRightButtonItemAsSpinner() {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.startAnimating()

        let rightBarButton = UIBarButtonItem(customView: activityIndicator)

        navigationItem.setRightBarButton(rightBarButton, animated: true)
        navigationItem.rightBarButtonItem?.isEnabled = false
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
}

// MARK: - Remote Update actions
//
extension AddProductCategoryViewController {

    @objc private func saveNewCategory() {
        ServiceLocator.analytics.track(.productCategorySettingsSaveNewCategoryTapped)

        titleCategoryTextFieldResignFirstResponder()
        configureRightButtonItemAsSpinner()

        guard let categoryName = newCategoryTitle else {
            return
        }

        let action = ProductCategoryAction.addProductCategory(siteID: siteID,
                                                              name: categoryName,
                                                              parentID: selectedParentCategory?.categoryID) { [weak self] (result) in
            self?.configureRightBarButtomitemAsSave()
            switch result {
            case .success(let category):
                self?.onCompletion(category)
            case .failure(let error):
                self?.displayErrorAlert(error: error)
            }
        }
        ServiceLocator.stores.dispatch(action)
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension AddProductCategoryViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension AddProductCategoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch sections[indexPath.section].rows[indexPath.row] {
        case .parentCategory:
            let parentCategoryViewController = ProductParentCategoriesViewController(siteID: siteID) { [weak self] (parentCategory) in
                defer {
                    self?.navigationController?.popViewController(animated: true)
                }
                self?.selectedParentCategory = parentCategory
            }
            navigationController?.pushViewController(parentCategoryViewController, animated: true)
        default:
            return
        }
    }

    /// Dismiss keyboard on Title Category Text Field
    ///
    private func titleCategoryTextFieldResignFirstResponder() {
        if let indexPath = sections.indexPathForRow(.title) {
            let cell = tableView.cellForRow(at: indexPath) as? TextFieldTableViewCell
            cell?.resignFirstResponder()
        }
    }
}

// MARK: - Keyboard management
//
private extension AddProductCategoryViewController {
    /// Registers for all of the related Notifications
    ///
    func startListeningToNotifications() {
        keyboardFrameObserver.startObservingKeyboardFrame()
    }
}

extension AddProductCategoryViewController: KeyboardScrollable {
    var scrollable: UIScrollView {
        return tableView
    }
}

// MARK: - Cell configuration
//
private extension AddProductCategoryViewController {
    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as TextFieldTableViewCell where row == .title:
            configureTitle(cell: cell)
        case let cell as TitleAndValueTableViewCell where row == .parentCategory:
            configureParentCategory(cell: cell)
        default:
            fatalError()
            break
        }
    }

    func configureTitle(cell: TextFieldTableViewCell) {
        let viewModel = TextFieldTableViewCell.ViewModel(text: newCategoryTitle,
                                                         placeholder: Strings.titleCellPlaceholder,
                                                         onTextChange: { [weak self] newCategoryName in
                                                            self?.newCategoryTitle = newCategoryName

            }, onTextDidBeginEditing: {
        }, inputFormatter: nil, keyboardType: .default)
        cell.configure(viewModel: viewModel)
        cell.applyStyle(style: .body)
    }

    func configureParentCategory(cell: TitleAndValueTableViewCell) {
        cell.updateUI(title: Strings.parentCellTitle, value: selectedParentCategory?.name ?? Strings.parentCellPlaceholder)
        cell.selectionStyle = .none
        cell.accessoryType = .disclosureIndicator
    }
}

// MARK: - Private Types
//
private extension AddProductCategoryViewController {

    struct Section: RowIterable {
        let rows: [Row]
    }

    enum Row: CaseIterable {
        case title
        case parentCategory

        var type: UITableViewCell.Type {
            switch self {
            case .title:
                return TextFieldTableViewCell.self
            case .parentCategory:
                return TitleAndValueTableViewCell.self
            }
        }

        var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}

// MARK: Error handling
//
private extension AddProductCategoryViewController {
    func displayErrorAlert(error: Error?) {
        let alertController = UIAlertController(title: Strings.errorAlertTitle,
                                                message: error?.localizedDescription,
                                                preferredStyle: .alert)
        let cancel = UIAlertAction(title: Strings.okErrorAlertButton,
                                   style: .cancel,
                                   handler: nil)
        alertController.addAction(cancel)
        present(alertController, animated: true)
    }
}


// MARK: - Constants!
//
private extension AddProductCategoryViewController {
    enum Strings {
        static let titleView = NSLocalizedString("Add Category", comment: "Product Add Category navigation title")
        static let cancelButton = NSLocalizedString("Cancel", comment: "Add Product Category. Cancel button title in navbar.")
        static let saveButton = NSLocalizedString("Save", comment: "Add Product Category. Save button title in navbar.")
        static let titleCellPlaceholder = NSLocalizedString("Title", comment: "Add Product Category. Placeholder of cell presenting the title of the category.")
        static let parentCellTitle = NSLocalizedString("Parent Category", comment: "Add Product Category. Title of cell presenting the parent category.")
        static let parentCellPlaceholder = NSLocalizedString("Optional", comment: "Add Product Category. Placeholder of cell presenting the parent category.")
        static let errorAlertTitle = NSLocalizedString("Cannot Add Category",
                                                       comment: "Title of the alert when there is an error creating a new product category")
        static let okErrorAlertButton = NSLocalizedString("OK",
                                                          comment: "Dismiss button on the alert when there is an error creating a new product category")
    }
}
