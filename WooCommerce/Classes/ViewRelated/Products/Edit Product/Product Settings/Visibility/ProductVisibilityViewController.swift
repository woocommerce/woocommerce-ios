import UIKit
import Yosemite

final class ProductVisibilityViewController: UIViewController {

    @IBOutlet weak private var tableView: UITableView!

    private var sections: [Section] = []

    // Completion callback
    //
    typealias Completion = (_ productSettings: ProductSettings) -> Void
    private let onCompletion: Completion

    private let productSettings: ProductSettings

    private var visibility: ProductVisibility = .public

    private lazy var keyboardFrameObserver: KeyboardFrameObserver = {
        let keyboardFrameObserver = KeyboardFrameObserver { [weak self] keyboardFrame in
            self?.handleKeyboardFrameUpdate(keyboardFrame: keyboardFrame)
        }
        return keyboardFrameObserver
    }()

    /// Init
    ///
    init(settings: ProductSettings, completion: @escaping Completion) {
        productSettings = settings
        onCompletion = completion
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
        visibility = getProductVisibility(productSettings)
        reloadSections()
        handleSwipeBackGesture()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            /// if the visibility selected is different from protected by password, the password becomes always an empty string (no password)
            if visibility != .passwordProtected {
                productSettings.password = ""
            }

            onCompletion(productSettings)
        }
    }

    override func viewLayoutMarginsDidChange() {
        super.viewLayoutMarginsDidChange()
        reloadSections()
    }

    private func reloadSections() {
        if visibility == .passwordProtected {
            sections = [Section(rows: [.publicVisibility, .passwordVisibility, .passwordField, .privateVisibility])]
        }
        else {
            sections = [Section(rows: [.publicVisibility, .passwordVisibility, .privateVisibility])]
        }
        tableView.reloadData()
    }

    private func getProductVisibility(_ productSettings: ProductSettings) -> ProductVisibility {
        return ProductVisibility(status: productSettings.status, password: productSettings.password)
    }

    private func getProductStatus(_ productVibility: ProductVisibility) -> ProductStatus {
        switch productVibility {
        case .private:
            return .privateStatus
        default:
            return .publish
        }
    }
}

// MARK: - View Configuration
//
private extension ProductVisibilityViewController {

    func configureNavigationBar() {
        title = NSLocalizedString("Visibility", comment: "Product Visibility navigation title")
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.registerNib(for: BasicTableViewCell.self)
        tableView.registerNib(for: TitleAndTextFieldWithImageTableViewCell.self)

        tableView.dataSource = self
        tableView.delegate = self

        tableView.backgroundColor = .listBackground
        tableView.removeLastCellSeparator()

        keyboardFrameObserver.startObservingKeyboardFrame()
    }
}

// MARK: - Navigation actions handling
//
extension ProductVisibilityViewController {

    override func shouldPopOnBackButton() -> Bool {
        guard visibility == .passwordProtected else {
            return true
        }

        if productSettings.password?.isEmpty == true || productSettings.password == nil {
            presentBackNavigationAlertController()
            return false
        }
        return true
    }

    override func shouldPopOnSwipeBack() -> Bool {
        return shouldPopOnBackButton()
    }

    private func presentBackNavigationAlertController() {
        let messageTitle = NSLocalizedString(
            "Are you sure you want to discard your changes?",
            comment: "Alert title to confirm the user wants to discard changes in Product Visibility"
        )
        let messageDescription = NSLocalizedString(
            "You need to add a password to make your product password-protected",
            comment: "Alert message to confirm the user wants to discard changes in Product Visibility"
        )

        let alertController = UIAlertController(title: messageTitle, message: messageDescription, preferredStyle: .alert)

        let cancelText = NSLocalizedString("Discard", comment: "Alert button title - dismisses alert, which discard changes on Product Visibility screen")
        alertController.addActionWithTitle(cancelText, style: .cancel) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }

        let logoutText = NSLocalizedString("Keep Editing", comment: "Alert button title - which keeps the user on the Product Visibility screen")
        alertController.addDefaultActionWithTitle(logoutText) { _ in
        }

        present(alertController, animated: true)
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension ProductVisibilityViewController: UITableViewDataSource {

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
extension ProductVisibilityViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = sections[indexPath.section].rows[indexPath.row]
        visibility = row.visibility
        productSettings.status = getProductStatus(visibility)
        reloadSections()
    }
}

// MARK: - Support for UITableViewDataSource
//
private extension ProductVisibilityViewController {

    /// Configure cellForRowAtIndexPath:
    ///
   func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as BasicTableViewCell where row == .passwordVisibility:
            configurePasswordVisibilityCell(cell: cell, indexPath: indexPath)
        case let cell as BasicTableViewCell:
            configureVisibilityCell(cell: cell, indexPath: indexPath)
        case let cell as TitleAndTextFieldWithImageTableViewCell:
            configurePasswordFieldCell(cell: cell, indexPath: indexPath)
        default:
            fatalError("Unidentified product visibility row type")
        }
    }

    func configureVisibilityCell(cell: BasicTableViewCell, indexPath: IndexPath) {
        let row = sections[indexPath.section].rows[indexPath.row]
        cell.selectionStyle = .default
        cell.textLabel?.text = row.description
        cell.accessoryType = row.visibility == visibility ? .checkmark : .none
        cell.showSeparator(inset: .init(top: 0, left: tableView.layoutMargins.left, bottom: 0, right: 0))
    }

    func configurePasswordVisibilityCell(cell: BasicTableViewCell, indexPath: IndexPath) {
        configureVisibilityCell(cell: cell, indexPath: indexPath)

        let isSelected: Bool = {
            let row = sections[indexPath.section].rows[indexPath.row]
            return row.visibility == visibility
        }()
        if isSelected {
            cell.hideSeparator()
        } else {
            cell.showSeparator(inset: .init(top: 0, left: tableView.layoutMargins.left, bottom: 0, right: 0))
        }
    }

    func configurePasswordFieldCell(cell: TitleAndTextFieldWithImageTableViewCell, indexPath: IndexPath) {
        let row = sections[indexPath.section].rows[indexPath.row]

        let placeholder = NSLocalizedString("Enter password", comment: "Enter password placeholder in Product Visibility")
        let viewModel = TitleAndTextFieldWithImageTableViewCell.ViewModel(title: row.description, text: productSettings.password,
                                                                          placeholder: placeholder, image: .visibilityImage) { [weak self] (text) in
            cell.rightImageViewIsHidden = text?.isEmpty == false
            self?.productSettings.password = text
        }
        cell.configure(viewModel: viewModel)

        /// Hides the image when there is a password, or show it if the password is empty
        cell.rightImageViewIsHidden = (productSettings.password?.isEmpty == false || productSettings.password == nil)

        cell.selectionStyle = .none
    }
}

// MARK: - Constants
//
extension ProductVisibilityViewController {

    /// Table Rows
    ///
    enum Row {
        /// Listed in the order they appear on screen
        case publicVisibility
        case passwordVisibility
        case passwordField
        case privateVisibility

        var reuseIdentifier: String {
            switch self {
            case .publicVisibility, .passwordVisibility, .privateVisibility:
                return BasicTableViewCell.reuseIdentifier
            case .passwordField:
                return TitleAndTextFieldWithImageTableViewCell.reuseIdentifier
            }
        }

        var description: String {
            switch self {
            case .publicVisibility, .passwordVisibility, .privateVisibility:
                return self.visibility.description
            case .passwordField:
                return NSLocalizedString("Password", comment: "Password field title in Product Visibility")
            }
        }

        var visibility: ProductVisibility {
            switch self {
            case .publicVisibility:
                return .public
            case .passwordVisibility, .passwordField:
                return .passwordProtected
            case .privateVisibility:
                return .private
            }
        }
    }

    /// Table Sections
    ///
    struct Section {
        let rows: [Row]

        init(rows: [Row]) {
            self.rows = rows
        }
    }
}

// MARK: - Keyboard management
//
extension ProductVisibilityViewController: KeyboardScrollable {
    var scrollable: UIScrollView {
        return tableView
    }
}
