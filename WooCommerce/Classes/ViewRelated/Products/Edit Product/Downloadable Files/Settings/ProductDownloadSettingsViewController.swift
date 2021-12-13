import UIKit
import Yosemite

// MARK: - ProductDownloadSettingsViewController
//
final class ProductDownloadSettingsViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private let viewModel: ProductDownloadSettingsViewModelOutput & ProductDownloadSettingsActionHandler
    private var sections: [Section] = []
    private var error: String?

    // Completion callback
    //
    typealias Completion = (_ downloadLimit: Int64, _ downloadExpiry: Int64, _ hasUnsavedChanges: Bool) -> Void
    private let onCompletion: Completion

    private lazy var keyboardFrameObserver = KeyboardFrameObserver { [weak self] keyboardFrame in
        self?.handleKeyboardFrameUpdate(keyboardFrame: keyboardFrame)
    }

    /// Init
    ///
    init(product: ProductFormDataModel, completion: @escaping Completion) {
        viewModel = ProductDownloadSettingsViewModel(product: product)
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

        // The limit text field becomes the first responder immediately when the view did appear
        getDownloadLimitCell()?.textFieldBecomeFirstResponder()
    }
}

// MARK: - Navigation actions handling
//
extension ProductDownloadSettingsViewController {

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
        viewModel.completeUpdating() { [weak self] (downloadLimit, downloadExpiry, hasUnsavedChanges) in
            ServiceLocator.analytics.track(.productDownloadableFilesSettingsChanged)
            self?.onCompletion(downloadLimit, downloadExpiry, hasUnsavedChanges)
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
extension ProductDownloadSettingsViewController: UITableViewDataSource {

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
private extension ProductDownloadSettingsViewController {

    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }

    func configureSections() {
        sections = viewModel.sections
    }

    func getDownloadLimitCell() -> TitleAndTextFieldTableViewCell? {
        guard let indexPath = sections.indexPathForRow(.limit) else {
            return nil
        }
        return tableView.cellForRow(at: indexPath) as? TitleAndTextFieldTableViewCell
    }

    func getDownloadExpiryCell() -> TitleAndTextFieldTableViewCell? {
        guard let indexPath = sections.indexPathForRow(.expiry) else {
            return nil
        }
        return tableView.cellForRow(at: indexPath) as? TitleAndTextFieldTableViewCell
    }
}


// MARK: - Cell configuration
//
private extension ProductDownloadSettingsViewController {
    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as TitleAndTextFieldTableViewCell where row == .limit:
            configureLimit(cell: cell)
        case let cell as TitleAndTextFieldTableViewCell where row == .expiry:
            configureExpiry(cell: cell)
        default:
            fatalError()
            break
        }
    }

    func configureLimit(cell: TitleAndTextFieldTableViewCell) {
        let cellViewModel = Product.createDownloadLimitViewModel(downloadLimit: viewModel.downloadLimit) { [weak self] value in
            self?.viewModel.handleDownloadLimitChange(value) { [weak self] (isValid) in
                self?.enableDoneButton(isValid)
                self?.getDownloadLimitCell()?.textFieldBecomeFirstResponder()
            }
        }
        cell.configure(viewModel: cellViewModel)
    }

    func configureExpiry(cell: TitleAndTextFieldTableViewCell) {
        let cellViewModel = Product.createDownloadExpiryViewModel(downloadExpiry: viewModel.downloadExpiry) { [weak self] value in
            self?.viewModel.handleDownloadExpiryChange(value) { [weak self] (isValid) in
                self?.enableDoneButton(isValid)
                self?.getDownloadExpiryCell()?.textFieldBecomeFirstResponder()
            }
        }
        cell.configure(viewModel: cellViewModel)
    }
}

// MARK: - View Configuration
//
private extension ProductDownloadSettingsViewController {

    func configureNavigationBar() {
        title = NSLocalizedString("Download Settings",
                                  comment: "Download file settings navigation title")

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                            target: self,
                                                            action: #selector(completeUpdating))
        enableDoneButton(false)
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.dataSource = self

        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground
        tableView.removeLastCellSeparator()

        registerTableViewCells()
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }
    }

    func enableDoneButton(_ enabled: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = enabled
    }
}

// MARK: - Keyboard management
//
extension ProductDownloadSettingsViewController: KeyboardScrollable {
    var scrollable: UIScrollView {
        return tableView
    }
}

private extension ProductDownloadSettingsViewController {
    /// Registers for all of the related Notifications
    ///
    func startListeningToNotifications() {
        keyboardFrameObserver.startObservingKeyboardFrame()
    }
}

extension ProductDownloadSettingsViewController {

    struct Section: RowIterable, Equatable {
        let footer: String?
        let rows: [Row]

        init(footer: String? = nil, rows: [Row]) {
            self.footer = footer
            self.rows = rows
        }
    }

    enum Row: CaseIterable {
        case limit
        case expiry

        var type: UITableViewCell.Type {
            switch self {
            case .limit, .expiry:
                return TitleAndTextFieldTableViewCell.self
            }
        }

        var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}
