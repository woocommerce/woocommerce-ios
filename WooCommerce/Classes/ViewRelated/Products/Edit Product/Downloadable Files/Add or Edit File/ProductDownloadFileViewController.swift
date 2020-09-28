import UIKit
import Yosemite


/// Displays the name and url for a downloadable file of a product
final class ProductDownloadFileViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private let viewModel: ProductDownloadFileViewModelOutput & ProductDownloadFileActionHandler
    private var sections: [Section] = []

    // Completion callback
    //
    typealias Completion = (_ fileName: String?,
        _ fileURL: String,
        _ fileID: String?,
        _ hasUnsavedChanges: Bool) -> Void
    private let onCompletion: Completion

    private lazy var keyboardFrameObserver = KeyboardFrameObserver { [weak self] keyboardFrame in
        self?.handleKeyboardFrameUpdate(keyboardFrame: keyboardFrame)
    }

    /// Init
    ///
    init(product: ProductFormDataModel, downloadFileIndex: Int?, formType: FormType, completion: @escaping Completion) {
        viewModel = ProductDownloadFileViewModel(product: product, downloadFileIndex: downloadFileIndex, formType: formType)
        onCompletion = completion
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
        configureSections()
        configureTableView()
        handleSwipeBackGesture()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        configureTextFieldAsFirstResponder()
    }
}

// MARK: - Navigation actions handling
//
extension ProductDownloadFileViewController {

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
        viewModel.completeUpdating(
            onCompletion: { [weak self] (fileName, fileURL, fileID, hasUnsavedChanges) in
                self?.onCompletion(fileName, fileURL, fileID, hasUnsavedChanges)
            }, onError: { [weak self] error in
                switch error {
                case .emptyFileName:
                    self?.displayEmptyFileNameErrorNotice()
                case .emptyFileUrl:
                    self?.displayInvalidUrlErrorNotice()
                case .invalidFileUrl:
                    self?.displayInvalidUrlErrorNotice()
                }
        })
    }

    @objc private func deleteDownloadableFile() {

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

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section].footer
    }
}

// MARK: - Convenience Methods
//
private extension ProductDownloadFileViewController {

    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }

    func configureSections() {
        sections = viewModel.sections
    }

    func getFileNameCell() -> TitleAndTextFieldTableViewCell? {
        guard let indexPath = sections.indexPathForRow(.name) else {
            return nil
        }
        return tableView.cellForRow(at: indexPath) as? TitleAndTextFieldTableViewCell
    }

    func getFileUrlCell() -> TitleAndTextFieldTableViewCell? {
        guard let indexPath = sections.indexPathForRow(.url) else {
            return nil
        }
        return tableView.cellForRow(at: indexPath) as? TitleAndTextFieldTableViewCell
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
            self?.viewModel.handleFileNameChange(value) { [weak self] (isValid, shouldBringUpKeyboard) in
                self?.enableDoneButton(isValid)
                if shouldBringUpKeyboard {
                    self?.getFileNameCell()?.textFieldBecomeFirstResponder()
                }
            }
        }
        cell.configure(viewModel: cellViewModel)
    }

    func configureURL(cell: TitleAndTextFieldTableViewCell) {
        let cellViewModel = Product.createDownloadFileUrlViewModel(fileUrl: viewModel.fileURL) { [weak self] value in
            self?.viewModel.handleFileUrlChange(value) { [weak self] (isValid, shouldBringUpKeyboard) in
                self?.enableDoneButton(isValid)
                if shouldBringUpKeyboard {
                    self?.getFileUrlCell()?.textFieldBecomeFirstResponder()
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
        title = NSLocalizedString(viewModel.formType == .add ? "Add Downloadable File" : viewModel.fileName ?? "",
                                  comment: "Individual downloadable file navigation title")

        var rightBarButtonItems = [UIBarButtonItem]()

        let deleteDownloadableFileBarButton: UIBarButtonItem = {
            let button = UIBarButtonItem(image: .moreImage,
                                         style: .plain,
                                         target: self,
                                         action: #selector(deleteDownloadableFile))
            button.accessibilityTraits = .button
            button.accessibilityLabel = NSLocalizedString("Delete downloadable file from list",
                                                          comment: "The action to delete downloadable file for the list")
            return button
        }()
        rightBarButtonItems.append(deleteDownloadableFileBarButton)

        let updateButtonTitle = NSLocalizedString("Update",
                                                comment: "Action for updating a Products' downloadable files' info remotely")
        let UpdateBarButton = UIBarButtonItem(title: updateButtonTitle,
                                             style: .done,
                                             target: self,
                                             action: #selector(completeUpdating))
        rightBarButtonItems.append(UpdateBarButton)

        navigationItem.rightBarButtonItems = rightBarButtonItems

        removeNavigationBackBarButtonText()
        self.enableDoneButton(false)
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
        view.pinSubviewToSafeArea(tableView)

        registerTableViewCells()
        registerTableViewHeaderFooters()
    }

    /// Since there is only a text field in this view for Product SKU form, the text field becomes the first responder immediately when the view did appear
    ///
    func configureTextFieldAsFirstResponder() {
        if let indexPath = sections.indexPathForRow(.url) {
            let cell = tableView.cellForRow(at: indexPath) as? TitleAndTextFieldTableViewCell
            cell?.textFieldBecomeFirstResponder()
        }
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.register(row.type.loadNib(), forCellReuseIdentifier: row.reuseIdentifier)
        }
    }

    func registerTableViewHeaderFooters() {
        let headersAndFooters = [ ErrorSectionHeaderView.self ]

        for kind in headersAndFooters {
            tableView.register(kind.loadNib(), forHeaderFooterViewReuseIdentifier: kind.reuseIdentifier)
        }
    }

    private func enableDoneButton(_ enabled: Bool) {
        navigationItem.rightBarButtonItems?.last?.isEnabled = enabled
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

// MARK: - Error handling
//
private extension ProductDownloadFileViewController {

    /// Displays a Notice onscreen, indicating that you can't add a sale price without adding before the regular price
    ///
    func displayEmptyFileNameErrorNotice() {
        UIApplication.shared.keyWindow?.endEditing(true)
        let message = NSLocalizedString("File name can not be empty",
                                        comment: "Download file error notice message, when file name is not given but done button is tapped")

        let notice = Notice(title: message, feedbackType: .error)
        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }

    /// Displays a Notice onscreen, indicating that the sale price need to be higher than the regular price
    ///
    func displayInvalidUrlErrorNotice() {
        UIApplication.shared.keyWindow?.endEditing(true)
        let message = NSLocalizedString("File url is empty or invalid",
                                        comment: "Download file url error notice message, when file url is not given/invalid but done button is tapped")

        let notice = Notice(title: message, feedbackType: .error)
        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }
}

extension ProductDownloadFileViewController {

    struct Section: RowIterable, Equatable {
        let errorTitle: String?
        let footer: String?
        let rows: [Row]

        init(errorTitle: String? = nil, footer: String? = nil, rows: [Row]) {
            self.errorTitle = errorTitle
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

    enum FormType {
        case add
        case edit
    }
}
