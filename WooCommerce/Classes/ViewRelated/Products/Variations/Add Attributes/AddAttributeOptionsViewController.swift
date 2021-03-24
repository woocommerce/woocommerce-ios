import UIKit
import Yosemite
import WordPressUI

final class AddAttributeOptionsViewController: UIViewController {

    @IBOutlet weak private var tableView: UITableView!
    private let ghostTableView = UITableView()

    private let viewModel: AddAttributeOptionsViewModel

    private let noticePresenter: NoticePresenter

    private let analytics: Analytics

    /// Closure to be invoked(with the updated product) when the update/create/remove attribute operation finishes successfully.
    ///
    private let onCompletion: (Product) -> Void

    /// Keyboard management
    ///
    private lazy var keyboardFrameObserver: KeyboardFrameObserver = KeyboardFrameObserver { [weak self] keyboardFrame in
        self?.handleKeyboardFrameUpdate(keyboardFrame: keyboardFrame)
    }

    /// Empty state screen
    ///
    private lazy var emptyStateViewController = EmptyStateViewController(style: .list)

    /// Sync error state config for EmptyStateViewController
    ///
    private lazy var errorStateConfig: EmptyStateViewController.Config = {
        let message = NSAttributedString(string: Localization.syncErrorMessage, attributes: [.font: EmptyStateViewController.Config.messageFont])
        return .withButton(message: message, image: .errorImage, details: "", buttonTitle: Localization.retryAction) { [weak self] _ in
            self?.viewModel.synchronizeOptions()
        }
    }()

    /// Initializer for `AddAttributeOptionsViewController`
    ///
    /// - Parameters:
    ///   - onCompletion: Closure to be invoked(with the updated product) when the update/create/remove attribute operation finishes successfully.
    init(viewModel: AddAttributeOptionsViewModel,
         noticePresenter: NoticePresenter = ServiceLocator.noticePresenter,
         analytics: Analytics = ServiceLocator.analytics,
         onCompletion: @escaping (Product) -> Void) {
        self.viewModel = viewModel
        self.noticePresenter = noticePresenter
        self.analytics = analytics
        self.onCompletion = onCompletion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureMainView()
        configureTableView()
        configureGhostTableView()
        registerTableViewHeaderSections()
        registerTableViewCells()
        startListeningToNotifications()
        observeViewModel()
        renderViewModel()
    }
}

// MARK: - View Configuration
//
private extension AddAttributeOptionsViewController {

    func configureRightButtonItem() {
        // The update indicator has precedence over the next button
        if viewModel.showUpdateIndicator {
            return navigationItem.rightBarButtonItems = [createUpdateIndicatorButton()]
        }

        // Assemble buttons based view model visibility
        let moreButton = UIBarButtonItem(image: .moreImage, style: .plain, target: self, action: #selector(moreButtonPressed(_:)))
        let buttons = [
            createNextButton(enabled: viewModel.isNextButtonEnabled),
            viewModel.showMoreButton ? moreButton : nil
        ]

        navigationItem.rightBarButtonItems = buttons.compactMap { $0 }
    }

    func createUpdateIndicatorButton() -> UIBarButtonItem {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .navigationBarLoadingIndicator
        indicator.startAnimating()
        return UIBarButtonItem(customView: indicator)
    }

    func createNextButton(enabled: Bool) -> UIBarButtonItem {
        let button = UIBarButtonItem(title: Localization.nextNavBarButton, style: .plain, target: self, action: #selector(nextButtonPressed))
        button.isEnabled = enabled
        return button
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
        tableView.isEditing = true
        tableView.allowsSelectionDuringEditing = true
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
        tableView.registerNib(for: BasicTableViewCell.self)
        tableView.registerNib(for: TextFieldTableViewCell.self)
        ghostTableView.registerNib(for: WooBasicTableViewCell.self)
    }

    func observeViewModel() {
        viewModel.onChange = { [weak self] in
            guard let self = self else { return }
            self.renderViewModel()
        }
    }

    func renderViewModel() {
        title = viewModel.getCurrentAttributeName
        configureRightButtonItem()
        tableView.reloadData()

        if viewModel.showGhostTableView {
            displayGhostTableView()
        } else {
            removeGhostTableView()
        }

        if viewModel.showSyncError {
            displaySyncErrorViewController()
        } else {
            removeEmptyStateViewController()
        }
    }

    /// Shows the EmptyStateViewController for options sync error state
    ///
    func displaySyncErrorViewController() {
        addChild(emptyStateViewController)

        emptyStateViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateViewController.view)

        emptyStateViewController.view.pinSubviewToAllEdges(view)
        emptyStateViewController.didMove(toParent: self)
        emptyStateViewController.configure(errorStateConfig)
    }

    func removeEmptyStateViewController() {
        guard emptyStateViewController.parent == self else {
            return
        }

        emptyStateViewController.willMove(toParent: nil)
        emptyStateViewController.view.removeFromSuperview()
        emptyStateViewController.removeFromParent()
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension AddAttributeOptionsViewController: UITableViewDataSource {

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

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .none // Don't show the default red delete button
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        false // Don't indent content
    }

    func tableView(_ tableView: UITableView,
                   targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
                   toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        // Constraint reorder destination to sections that support it.
        let proposedSection = viewModel.sections[proposedDestinationIndexPath.section]
        guard proposedSection.allowsReorder else {
            return sourceIndexPath
        }
        return proposedDestinationIndexPath
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Only allow reorder if the section allows it.
        let section = viewModel.sections[indexPath.section]
        return section.allowsReorder
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        viewModel.reorderSelectedOptions(fromIndex: sourceIndexPath.row, toIndex: destinationIndexPath.row)
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension AddAttributeOptionsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard viewModel.sections[indexPath.section].allowsSelection else {
            return
        }
        viewModel.selectExistingOption(atIndex: indexPath.row)
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
private extension AddAttributeOptionsViewController {
    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch (row, cell) {
        case (.optionTextField, let cell as TextFieldTableViewCell):
            configureTextField(cell: cell)
        case (let .selectedOptions(name), let cell as BasicTableViewCell):
            configureOptionOffered(cell: cell, text: name, index: indexPath.row)
        case (let .existingOptions(name), let cell as BasicTableViewCell):
            configureOptionAdded(cell: cell, text: name)
        default:
            fatalError("Unsupported Cell")
            break
        }
    }

    func configureTextField(cell: TextFieldTableViewCell) {
        let viewModel = TextFieldTableViewCell.ViewModel(text: nil,
                                                         placeholder: Localization.optionNameCellPlaceholder,
                                                         onTextChange: nil,
                                                         onTextDidBeginEditing: nil,
                                                         onTextDidReturn: { [weak self] text in
                                                            if let text = text {
                                                                self?.viewModel.addNewOption(name: text)
                                                            }

                                                         }, inputFormatter: nil,
                                                         keyboardType: .default)
        cell.configure(viewModel: viewModel)
        cell.applyStyle(style: .body)
    }

    func configureOptionOffered(cell: BasicTableViewCell, text: String, index: Int) {
        cell.imageView?.tintColor = .tertiaryLabel
        cell.imageView?.image = UIImage.deleteCellImage
        cell.textLabel?.text = text

        // Listen to taps on the cell's image view
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.on { [weak self] _ in
            self?.viewModel.removeSelectedOption(atIndex: index)
        }
        cell.imageView?.addGestureRecognizer(tapRecognizer)
        cell.imageView?.isUserInteractionEnabled = true
    }

    func configureOptionAdded(cell: BasicTableViewCell, text: String) {
        cell.textLabel?.text = text
        cell.imageView?.image = nil
        cell.imageView?.isUserInteractionEnabled = false
    }
}

// MARK: - Placeholders
//
private extension AddAttributeOptionsViewController {
    /// Renders ghost placeholder while options are being synched.
    ///
    func displayGhostTableView() {
        let options = GhostOptions(displaysSectionHeader: false,
                                   reuseIdentifier: WooBasicTableViewCell.reuseIdentifier,
                                   rowsPerSection: [3])
        ghostTableView.displayGhostContent(options: options, style: .wooDefaultGhostStyle)
        ghostTableView.isHidden = false
    }

    /// Removes ghost placeholder
    ///
    func removeGhostTableView() {
        ghostTableView.removeGhostContent()
        ghostTableView.isHidden = true
    }
}

// MARK: - Keyboard management
//
private extension AddAttributeOptionsViewController {
    /// Registers for all of the related Notifications
    ///
    func startListeningToNotifications() {
        keyboardFrameObserver.startObservingKeyboardFrame()
    }
}

extension AddAttributeOptionsViewController: KeyboardScrollable {
    var scrollable: UIScrollView {
        return tableView
    }
}


// MARK: - Navigation actions handling
//
extension AddAttributeOptionsViewController {

    @objc private func nextButtonPressed() {
        viewModel.updateProductAttributes { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(product):
                self.onCompletion(product)
            case let .failure(error):
                self.noticePresenter.enqueue(notice: .init(title: Localization.updateAttributeError, feedbackType: .error))
                DDLogError(error.localizedDescription)
            }
        }
    }

    /// Present an action-sheet with `Remove` and `Rename` options.
    ///
    @objc private func moreButtonPressed(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = .text

        if viewModel.allowsRename {
            let renameAction = UIAlertAction(title: Localization.renameAction, style: .default) { [weak self] _ in
                self?.trackRenameAttributeButtonTapped()
                self?.navigateToRenameAttribute()
            }
            actionSheet.addAction(renameAction)
        }

        let removeAction = UIAlertAction(title: Localization.removeAction, style: .destructive) { [weak self] _ in
            self?.presentRemoveAttributeConfirmation()
        }
        actionSheet.addAction(removeAction)

        let cancelAction = UIAlertAction(title: Localization.cancelAction, style: .cancel)
        actionSheet.addAction(cancelAction)

        let popoverController = actionSheet.popoverPresentationController
        popoverController?.barButtonItem = sender

        present(actionSheet, animated: true)
    }

    func trackRenameAttributeButtonTapped() {
        analytics.track(event: WooAnalyticsEvent.Variations.renameAttributeButtonTapped(productID: viewModel.product.productID))
    }

    /// Navigates to `RenameAttributesViewController`
    ///
    private func navigateToRenameAttribute() {
        let viewModel = RenameAttributesViewModel(attributeName: self.viewModel.getCurrentAttributeName)
        let renameAttributeViewController = RenameAttributesViewController(viewModel: viewModel) { [weak self] updatedAttributeName in
            // Sets new attribute name
            self?.viewModel.setCurrentAttributeName(updatedAttributeName)
            self?.navigationController?.popViewController(animated: true)
        }
        show(renameAttributeViewController, sender: nil)
    }

    /// Presents a confirmation alert and removes the attribute if the merchant confirms it.
    ///
    private func presentRemoveAttributeConfirmation() {
        let alertController = UIAlertController(title: Localization.removeConfirmationTitle,
                                                message: Localization.removeConfirmationInfo,
                                                preferredStyle: .alert)
        alertController.view.tintColor = .text

        alertController.addCancelActionWithTitle(Localization.cancelAction)
        alertController.addDestructiveActionWithTitle(Localization.removeAction) { [weak self] _ in
            guard let self = self else { return }
            self.analytics.track(event: WooAnalyticsEvent.Variations.removeAttributeButtonTapped(productID: self.viewModel.product.productID))
            self.removeCurrentAttribute()
        }

        present(alertController, animated: true)
    }

    /// Tells the view model to remove the current attribute and pops the view controller after completion
    ///
    func removeCurrentAttribute() {
        viewModel.removeCurrentAttribute { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(product):
                self.onCompletion(product)
            case let .failure(error):
                self.noticePresenter.enqueue(notice: .init(title: Localization.removeAttributeError, feedbackType: .error))
                DDLogError(error.localizedDescription)
            }
        }
    }
}

extension AddAttributeOptionsViewController {

    struct Section: Equatable {
        let header: String?
        let footer: String?
        let rows: [Row]
        let allowsReorder: Bool
        let allowsSelection: Bool
    }

    enum Row: Equatable {
        case optionTextField
        case selectedOptions(name: String)
        case existingOptions(name: String)

        fileprivate var type: UITableViewCell.Type {
            switch self {
            case .optionTextField:
                return TextFieldTableViewCell.self
            case .selectedOptions, .existingOptions:
                return BasicTableViewCell.self
            }
        }

        fileprivate var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}

private extension AddAttributeOptionsViewController {
    enum Localization {
        static let nextNavBarButton = NSLocalizedString("Next", comment: "Next nav bar button title in Add Product Attribute Options screen")
        static let optionNameCellPlaceholder = NSLocalizedString("Option name",
                                                            comment: "Placeholder of cell presenting the title of the new attribute option.")
        static let updateAttributeError = NSLocalizedString("The attribute couldn't be saved.",
                                                            comment: "Error title when trying to update or create an attribute remotely.")

        static let syncErrorMessage = NSLocalizedString("Unable to load attribute options", comment: "Load Attribute Options Action Failed")
        static let retryAction = NSLocalizedString("Retry", comment: "Retry Action")

        static let removeAttributeError = NSLocalizedString("The attribute couldn't be removed.",
                                                            comment: "Error title when trying to remove an attribute remotely.")

        static let renameAction = NSLocalizedString("Rename", comment: "Title for renaming an attribute in the edit attribute action sheet.")
        static let removeAction = NSLocalizedString("Remove", comment: "Title for removing an attribute in the edit attribute action sheet.")
        static let cancelAction = NSLocalizedString("Cancel", comment: "Title for canceling the edit attribute action sheet.")

        static let removeConfirmationTitle = NSLocalizedString("Remove Attribute",
                                                               comment: "Confirmation title before removing an attribute from a variation.")
        static let removeConfirmationInfo = NSLocalizedString("Are you sure you want to remove this attribute?",
                                                              comment: "Confirmation text before removing an attribute from a variation.")
    }
}
