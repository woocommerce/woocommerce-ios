import UIKit
import Yosemite
import WordPressUI

final class AddAttributeViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    private let ghostTableView = UITableView()

    private let viewModel: AddAttributeViewModel

    /// Closure to be invoked(with the updated product)  when the update/create attribute operation finishes successfully.
    ///
    private let onCompletion: (Product) -> Void

    /// Keyboard management
    ///
    private lazy var keyboardFrameObserver: KeyboardFrameObserver = KeyboardFrameObserver { [weak self] keyboardFrame in
        self?.handleKeyboardFrameUpdate(keyboardFrame: keyboardFrame)
    }

    /// Initializer for `AddAttributeViewController`
    ///
    /// - Parameters:
    ///   - onCompletion: Closure to be invoked(with the updated product)  when the update/create attribute operation finishes successfully.
    init(viewModel: AddAttributeViewModel, onCompletion: @escaping (Product) -> Void) {
        self.viewModel = viewModel
        self.onCompletion = onCompletion
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
        registerTableViewHeaderSections()
        registerTableViewCells()
        configureTableView()
        configureGhostTableView()
        configureViewModel()
        enableDoneButton(false)
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
                                                           action: #selector(doneButtonPressed))
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground

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

    func registerTableViewHeaderSections() {
        let headerNib = UINib(nibName: TwoColumnSectionHeaderView.reuseIdentifier, bundle: nil)
        tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: TwoColumnSectionHeaderView.reuseIdentifier)
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }
        ghostTableView.registerNib(for: WooBasicTableViewCell.self)
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

    func enableDoneButton(_ enabled: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = enabled
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
                                   reuseIdentifier: WooBasicTableViewCell.reuseIdentifier,
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

        let row = viewModel.sections[indexPath.section].rows[indexPath.row]
        guard row == .existingAttribute else {
            return
        }
        let attribute = viewModel.localAndGlobalAttributes[indexPath.row]
        presentAddAttributeOptions(for: .existing(attribute: attribute))
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let leftText = viewModel.sections[section].header else {
            return nil
        }

        let headerID = TwoColumnSectionHeaderView.reuseIdentifier
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerID) as? TwoColumnSectionHeaderView else {
            assertionFailure("Could not find section header view for reuseIdentifier \(headerID)")
            return nil
        }

        headerView.leftText = leftText
        headerView.rightText = nil

        return headerView
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return viewModel.sections[section].footer
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
            configureAttribute(cell: cell, attribute: viewModel.localAndGlobalAttributes[safe: indexPath.row])
        default:
            fatalError()
            break
        }
    }

    func configureTextField(cell: TextFieldTableViewCell) {
        let viewModel = TextFieldTableViewCell.ViewModel(text: nil,
                                                         placeholder: Localization.titleCellPlaceholder,
                                                         onTextChange: { [weak self] newAttributeName in
                                                            self?.viewModel.handleNewAttributeNameChange(newAttributeName)
                                                            self?.enableDoneButton(self?.viewModel.newAttributeName != nil)
                                                         }, onTextDidBeginEditing: {
                                                         }, onTextDidReturn: { [weak self] _ in
                                                            self?.doneButtonPressed()
                                                         }, inputFormatter: nil,
                                                         keyboardType: .default,
                                                         returnKeyType: .next)
        cell.configure(viewModel: viewModel)
        cell.applyStyle(style: .body)
    }

    func configureAttribute(cell: BasicTableViewCell, attribute: ProductAttribute?) {
        cell.textLabel?.text = attribute?.name
    }
}

// MARK: - Keyboard management
//
private extension AddAttributeViewController {
    /// Registers for all of the related Notifications
    ///
    func startListeningToNotifications() {
        keyboardFrameObserver.startObservingKeyboardFrame()
    }
}

extension AddAttributeViewController: KeyboardScrollable {
    var scrollable: UIScrollView {
        return tableView
    }
}


// MARK: - Navigation actions handling
//
extension AddAttributeViewController {

    @objc private func doneButtonPressed() {
        guard let name = viewModel.newAttributeName else {
            return
        }
        presentAddAttributeOptions(for: .new(name: name))
    }

    /// Presents `AddAttributeOptionsViewController` and passes the same `onCompletion` closure, for our presenterVC  to handle.
    ///
    private func presentAddAttributeOptions(for attribute: AddAttributeOptionsViewModel.Attribute) {
        let viewModel = AddAttributeOptionsViewModel(product: self.viewModel.product, attribute: attribute)
        let addAttributeOptionsVC = AddAttributeOptionsViewController(viewModel: viewModel, onCompletion: onCompletion)
        show(addAttributeOptionsVC, sender: nil)
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
        static let titleCellPlaceholder = NSLocalizedString("New Attribute Name",
                                                            comment: "Add Product Attribute. Placeholder of cell presenting the title of the new attribute.")
        static let syncErrorMessage = NSLocalizedString("Unable to load product attributes", comment: "Load Product Attributes Action Failed")
        static let retryAction = NSLocalizedString("Retry", comment: "Retry Action")
    }
}
