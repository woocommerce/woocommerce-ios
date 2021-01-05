import UIKit
import Yosemite


/// Displays the name and url for a downloadable file of a product
final class ProductDownloadFileViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private let viewModel: ProductDownloadFileViewModelOutput & ProductDownloadFileActionHandler

    // Completion callback
    //
    typealias Completion = (_ fileName: String?,
        _ fileURL: String,
        _ fileID: String?,
        _ hasUnsavedChanges: Bool) -> Void
    private let onCompletion: Completion

    // Deletion callback
    //
    typealias Deletion = () -> Void
    private let onDeletion: Deletion


    private lazy var keyboardFrameObserver = KeyboardFrameObserver { [weak self] keyboardFrame in
        self?.handleKeyboardFrameUpdate(keyboardFrame: keyboardFrame)
    }

    private let updateBarButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: nil,
                                     style: .done,
                                     target: self,
                                     action: #selector(completeUpdating))
        return button
    }()

    /// Init
    ///
    init(productDownload: ProductDownload?, downloadFileIndex: Int?, formType: FormType, completion: @escaping Completion, deletion: @escaping Deletion) {
        viewModel = ProductDownloadFileViewModel(productDownload: productDownload, downloadFileIndex: downloadFileIndex, formType: formType)
        onCompletion = completion
        onDeletion = deletion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        startListeningToNotifications()
        configureNavigationBar()
        configureMainView()
        configureTableView()
        handleSwipeBackGesture()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        configureUrlTextFieldAsFirstResponder()
    }
}

// MARK: - Navigation actions handling
//
extension ProductDownloadFileViewController {

    @objc private func presentMoreActionSheetMenu(_ sender: UIBarButtonItem) {
        let menuAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        menuAlert.view.tintColor = .text

        let deleteTitle = Localization.actionSheetDeleteTitle
        let deleteAction = UIAlertAction(title: deleteTitle, style: .destructive) { [weak self] (action) in
            ServiceLocator.analytics.track(.productsDownloadableFile, withProperties: ["action": "deleted"])
            self?.onDeletion()
        }
        menuAlert.addAction(deleteAction)

        let cancelTitle = Localization.actionSheetCancelTitle
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel)
        menuAlert.addAction(cancelAction)

        let popoverController = menuAlert.popoverPresentationController
        popoverController?.barButtonItem = sender

        present(menuAlert, animated: true)
    }

    override func shouldPopOnBackButton() -> Bool {
        guard viewModel.hasUnsavedChanges() else {
            return true
        }
        presentBackNavigationActionSheet()
        return false
    }

    override func shouldPopOnSwipeBack() -> Bool {
        return shouldPopOnBackButton()
    }

    @objc private func completeUpdating() {
        switch viewModel.formType {
        case .add:
            ServiceLocator.analytics.track(.productsDownloadableFile, withProperties: ["action": "added"])
        case .edit:
            ServiceLocator.analytics.track(.productsDownloadableFile, withProperties: ["action": "updated"])
        }
        viewModel.completeUpdating { [weak self] (fileName, fileURL, fileID, hasUnsavedChanges) in
             self?.onCompletion(fileName, fileURL, fileID, hasUnsavedChanges)
        }
    }

    private func presentBackNavigationActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension ProductDownloadFileViewController: UITableViewDataSource {

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

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return viewModel.sections[section].footer
    }
}

// MARK: - Cell configuration
//
private extension ProductDownloadFileViewController {
    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as TitleAndTextFieldTableViewCell where row == .name:
            configureName(cell: cell)
        case let cell as TitleAndTextFieldTableViewCell where row == .url:
            configureURL(cell: cell)
        default:
            fatalError()
            break
        }
    }

    func configureName(cell: TitleAndTextFieldTableViewCell) {
        let cellViewModel = Product.createDownloadFileNameViewModel(fileName: viewModel.fileName) { [weak self] value in
            self?.viewModel.handleFileNameChange(value) { [weak self] (isValid) in
                self?.enableDoneButton(isValid)
                if let indexPath = self?.viewModel.sections.indexPathForRow(.name),
                    let cell = self?.tableView.cellForRow(at: indexPath) as? TitleAndTextFieldTableViewCell {
                    cell.textFieldBecomeFirstResponder()
                }
            }
        }
        cell.configure(viewModel: cellViewModel)
    }

    func configureURL(cell: TitleAndTextFieldTableViewCell) {
        let cellViewModel = Product.createDownloadFileUrlViewModel(fileUrl: viewModel.fileURL) { [weak self] value in
            self?.viewModel.handleFileUrlChange(value) { [weak self] (isValid) in
                self?.enableDoneButton(isValid)
                if let indexPath = self?.viewModel.sections.indexPathForRow(.url),
                    let cell = self?.tableView.cellForRow(at: indexPath) as? TitleAndTextFieldTableViewCell {
                    cell.textFieldBecomeFirstResponder()
                }
            }
        }
        cell.configure(viewModel: cellViewModel)
    }
}

// MARK: - View Configuration
//
private extension ProductDownloadFileViewController {

    func configureNavigationBar() {
        if let fileName = viewModel.fileName {
            title = fileName
        } else {
            title = Localization.navigationBarTitle
        }

        var rightBarButtonItems = [UIBarButtonItem]()

        if viewModel.formType == .edit {
            let moreBarButton: UIBarButtonItem = {
                let button = UIBarButtonItem(image: .moreImage,
                                             style: .plain,
                                             target: self,
                                             action: #selector(presentMoreActionSheetMenu(_:)))
                button.accessibilityLabel = Localization.moreButtonAccessibilityLabel
                return button
            }()
            rightBarButtonItems.append(moreBarButton)
        }

        updateBarButton.title = viewModel.formType == .add ? Localization.addButton : Localization.updateButton
        updateBarButton.accessibilityLabel = viewModel.formType == .add ? Localization.addButtonAccessibilityLabel : Localization.updateButtonAccessibilityLabel
        rightBarButtonItems.append(updateBarButton)

        navigationItem.rightBarButtonItems = rightBarButtonItems

        removeNavigationBackBarButtonText()
        enableDoneButton(viewModel.hasUnsavedChanges())
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.dataSource = self

        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground
        tableView.removeLastCellSeparator()

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        registerTableViewCells()
    }

    /// Since the file url is the mandatory text field in this view for Product Downloadable file form,
    /// the text field becomes the first responder immediately when the view did appear
    ///
    func configureUrlTextFieldAsFirstResponder() {
        if let indexPath = viewModel.sections.indexPathForRow(.url) {
            let cell = tableView.cellForRow(at: indexPath) as? TitleAndTextFieldTableViewCell
            cell?.textFieldBecomeFirstResponder()
        }
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.register(row.type.loadNib(), forCellReuseIdentifier: row.reuseIdentifier)
        }
    }

    func enableDoneButton(_ enabled: Bool) {
        updateBarButton.isEnabled = enabled
    }
}

// MARK: - Keyboard management
//
extension ProductDownloadFileViewController: KeyboardScrollable {
    var scrollable: UIScrollView {
        return tableView
    }
}

private extension ProductDownloadFileViewController {
    /// Registers for all of the related Notifications
    ///
    func startListeningToNotifications() {
        keyboardFrameObserver.startObservingKeyboardFrame()
    }
}

extension ProductDownloadFileViewController {

    struct Section: RowIterable, Equatable {
        let footer: String?
        let rows: [Row]

        init(footer: String? = nil, rows: [Row]) {
            self.footer = footer
            self.rows = rows
        }
    }

    enum Row: CaseIterable {
        case name
        case url

        fileprivate var type: UITableViewCell.Type {
            switch self {
            case .name, .url:
                return TitleAndTextFieldTableViewCell.self
            }
        }

        fileprivate var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }

    /// The type of downloadable file form: adding a new one or editing an existing one.
    enum FormType {
        case add
        case edit
    }
}

// MARK: - Constants

private extension ProductDownloadFileViewController {
    enum Localization {
        static let navigationBarTitle = NSLocalizedString("Add Downloadable File",
                                                          comment: "Downloadable file screen navigation title")
        static let moreButtonAccessibilityLabel = NSLocalizedString("Show bottom action sheet options for a downloadable file",
                                                                    comment: "Accessibility label to show bottom action sheet options for a downloadable file")
        static let addButton = NSLocalizedString("Add",
                                                 comment: "Action for adding a Products' downloadable files' info remotely")
        static let addButtonAccessibilityLabel = NSLocalizedString("Add products' downloadable files' info remotely",
                                                                   comment: "Accessibility label to add products' downloadable files' info remotely")
        static let updateButton = NSLocalizedString("Update",
                                                    comment: "Action for updating a Products' downloadable files' info remotely")
        static let updateButtonAccessibilityLabel = NSLocalizedString("Update products' downloadable files' info remotely",
                                                                      comment: "Accessibility label to update products' downloadable files' info remotely")
        static let actionSheetDeleteTitle = NSLocalizedString("Delete",
                                                              comment: "Button title Delete in Downloadable File Options Action Sheet")
        static let actionSheetCancelTitle = NSLocalizedString("Cancel",
                                                              comment: "Button title Cancel in Downloadable File More Options Action Sheet")
    }
}
