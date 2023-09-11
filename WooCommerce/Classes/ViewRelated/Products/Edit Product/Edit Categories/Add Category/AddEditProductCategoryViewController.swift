import UIKit
import Networking
import Yosemite
import Combine

/// Add or edit a new category associated to the active site.
///
final class AddEditProductCategoryViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    /// Table Sections to be rendered
    ///
    private let sections: [Section] = [Section(rows: [.title]), Section(rows: [.parentCategory])]

    /// Keyboard management
    ///
    private lazy var keyboardFrameObserver: KeyboardFrameObserver = KeyboardFrameObserver { [weak self] keyboardFrame in
        self?.handleKeyboardFrameUpdate(keyboardFrame: keyboardFrame)
    }

    private let viewModel: AddEditProductCategoryViewModel
    private var saveButtonSubscription: AnyCancellable?

    init(viewModel: AddEditProductCategoryViewModel) {
        self.viewModel = viewModel
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
private extension AddEditProductCategoryViewController {

    func configureNavigationBar() {
        title = {
            switch viewModel.editingMode {
            case .add:
                return Strings.addCategory
            case .editing:
                return Strings.updateCategory
            }
        }()

        addCloseNavigationBarButton(title: Strings.cancelButton)
        configureRightBarButtonItemAsSave()
    }

    func configureRightBarButtonItemAsSave() {
        navigationItem.setRightBarButton(UIBarButtonItem(title: Strings.saveButton,
                                                         style: .done,
                                                         target: self,
                                                         action: #selector(saveCategory)),
                                         animated: true)

        saveButtonSubscription = viewModel.$saveEnabled
            .sink { [weak self] enabled in
                self?.navigationItem.rightBarButtonItem?.isEnabled = enabled
            }
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
extension AddEditProductCategoryViewController {

    @objc private func saveCategory() {
        ServiceLocator.analytics.track(.productCategorySettingsSaveNewCategoryTapped)

        titleCategoryTextFieldResignFirstResponder()
        configureRightButtonItemAsSpinner()

        Task { @MainActor in
            do {
                try await viewModel.saveCategory()
            } catch {
                displayErrorAlert(error: error)
            }
            configureRightBarButtonItemAsSave()
        }
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension AddEditProductCategoryViewController: UITableViewDataSource {

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
extension AddEditProductCategoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch sections[indexPath.section].rows[indexPath.row] {
        case .parentCategory:
            let controller = ProductParentCategoriesViewController(
                siteID: viewModel.siteID,
                childCategory: viewModel.currentCategory,
                selectedCategory: viewModel.selectedParentCategory
            ) { [weak self] (parentCategory) in
                defer {
                    self?.navigationController?.popViewController(animated: true)
                }
                self?.viewModel.selectedParentCategory = parentCategory
                self?.tableView.reloadData()
            }
            navigationController?.pushViewController(controller, animated: true)
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
private extension AddEditProductCategoryViewController {
    /// Registers for all of the related Notifications
    ///
    func startListeningToNotifications() {
        keyboardFrameObserver.startObservingKeyboardFrame()
    }
}

extension AddEditProductCategoryViewController: KeyboardScrollable {
    var scrollable: UIScrollView {
        return tableView
    }
}

// MARK: - Cell configuration
//
private extension AddEditProductCategoryViewController {
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
        let viewModel = TextFieldTableViewCell.ViewModel(text: viewModel.categoryTitle,
                                                         placeholder: Strings.titleCellPlaceholder,
                                                         onTextChange: { [weak self] newCategoryName in
                                                            self?.viewModel.categoryTitle = newCategoryName ?? ""

            }, onTextDidBeginEditing: {
        }, onTextDidReturn: nil, inputFormatter: nil, keyboardType: .default)
        cell.configure(viewModel: viewModel)
        cell.applyStyle(style: .body)
    }

    func configureParentCategory(cell: TitleAndValueTableViewCell) {
        cell.updateUI(title: Strings.parentCellTitle, value: viewModel.selectedParentCategory?.name ?? Strings.parentCellPlaceholder)
        cell.selectionStyle = .none
        cell.accessoryType = .disclosureIndicator
    }
}

// MARK: - Private Types
//
private extension AddEditProductCategoryViewController {

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
private extension AddEditProductCategoryViewController {
    func displayErrorAlert(error: Error?) {
        let title = viewModel.editingMode == .add ? Strings.errorAddingTitle : Strings.errorUpdatingTitle
        let alertController = UIAlertController(title: title,
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
private extension AddEditProductCategoryViewController {
    enum Strings {
        static let addCategory = NSLocalizedString("Add Category", comment: "Product Add Category navigation title")
        static let updateCategory = NSLocalizedString("Update Category", comment: "Product Update Category navigation title")
        static let cancelButton = NSLocalizedString("Cancel", comment: "Add Product Category. Cancel button title in navbar.")
        static let saveButton = NSLocalizedString("Save", comment: "Add Product Category. Save button title in navbar.")
        static let titleCellPlaceholder = NSLocalizedString("Title", comment: "Add Product Category. Placeholder of cell presenting the title of the category.")
        static let parentCellTitle = NSLocalizedString("Parent Category", comment: "Add Product Category. Title of cell presenting the parent category.")
        static let parentCellPlaceholder = NSLocalizedString("Optional", comment: "Add Product Category. Placeholder of cell presenting the parent category.")
        static let errorAddingTitle = NSLocalizedString("Cannot Add Category",
                                                        comment: "Title of the alert when there is an error creating a new product category")
        static let errorUpdatingTitle = NSLocalizedString("Cannot Update Category",
                                                          comment: "Title of the alert when there is an error creating a new product category")
        static let okErrorAlertButton = NSLocalizedString("OK",
                                                          comment: "Dismiss button on the alert when there is an error creating a new product category")
    }
}
