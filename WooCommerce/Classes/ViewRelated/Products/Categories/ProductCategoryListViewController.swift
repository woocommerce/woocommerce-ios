import Combine
import UIKit
import Yosemite
import WordPressUI

/// ProductCategoryListViewController: Displays the list of ProductCategories associated to the active Account.
/// Please note that this class cannot be used as is, since there is not configuration for navigation.
/// Instead, it shall be embedded through view controller containment by adding it as a child to other view controllers.
///
final class ProductCategoryListViewController: UIViewController, GhostableViewController {

    @IBOutlet private var contentStackView: UIStackView!
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var searchBar: UISearchBar!
    @IBOutlet private var clearSelectionButtonBarView: UIView!
    @IBOutlet private var clearSelectionButton: UIButton!

    lazy var ghostTableViewController = GhostTableViewController(options: GhostTableViewOptions(cellClass: ProductCategoryTableViewCell.self))

    let viewModel: ProductCategoryListViewModel

    private let configuration: Configuration
    private var subscriptions: Set<AnyCancellable> = []

    /// Tracks if the swipe actions have been glanced to the user.
    ///
    private var swipeActionsGlanced = false

    /// The controller of the view to show if the search results are empty.
    ///
    private lazy var emptyStateViewController: EmptyStateViewController = {
        let emptyStateViewController = EmptyStateViewController(style: .list)
        let config: EmptyStateViewController.Config = .simple(
            message: .init(string: Localization.emptyStateMessage),
            image: .emptySearchResultsImage
        )
        emptyStateViewController.configure(config)
        return emptyStateViewController
    }()

    init(viewModel: ProductCategoryListViewModel, configuration: Configuration = .init()) {
        self.viewModel = viewModel
        self.configuration = configuration

        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureClearSelectionButton()
        registerTableViewCells()
        configureTableView()
        configureEmptyView()
        configureViewModel()
        handleSwipeBackGesture()
        configureDeletionError()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Note: configuring the search bar text color does not work in `viewDidLoad` and `viewWillAppear`.
        configureSearchBar()
    }
}

// MARK: - Configuration to customize the list
//
extension ProductCategoryListViewController {
    struct Configuration {
        var searchEnabled = false
        var clearSelectionEnabled = false
        var updateEnabled = false
    }
}

// MARK: - View Configuration
//
private extension ProductCategoryListViewController {
    func registerTableViewCells() {
        tableView.registerNib(for: ProductCategoryTableViewCell.self)
    }

    func configureTableView() {
        view.backgroundColor = .listForeground(modal: false)
        tableView.backgroundColor = .listBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.removeLastCellSeparator()
        tableView.keyboardDismissMode = .onDrag
        tableView.cellLayoutMarginsFollowReadableWidth = true
    }

    func configureSearchBar() {
        searchBar.isHidden = !configuration.searchEnabled
        searchBar.placeholder = Localization.searchBarPlaceholder
        searchBar.searchTextField.textColor = .text
        searchBar.delegate = self
    }

    func configureClearSelectionButton() {
        clearSelectionButton.setTitle(Localization.clearSelectionButtonTitle, for: .normal)
        clearSelectionButton.applyLinkButtonStyle()
        clearSelectionButton.addAction(UIAction { [weak self] _ in
            self?.viewModel.resetSelectedCategoriesAndReload()
        }, for: .touchUpInside)

        viewModel.$selectedCategories.combineLatest(viewModel.$categoryViewModels)
            .map { [weak self] selectedItems, models -> Bool in
                guard let self = self, self.configuration.clearSelectionEnabled else {
                    return true
                }
                return selectedItems.isEmpty || models.isEmpty
            }
            .assign(to: \.isHidden, on: clearSelectionButtonBarView)
            .store(in: &subscriptions)
    }

    func configureEmptyView() {
        addChild(emptyStateViewController)

        emptyStateViewController.view.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addSubview(emptyStateViewController.view)
        contentStackView.addArrangedSubview(emptyStateViewController.view)

        emptyStateViewController.didMove(toParent: self)
        emptyStateViewController.view.isHidden = true
    }
}

// MARK: - Synchronize Categories
//
private extension ProductCategoryListViewController {
    func configureViewModel() {
        viewModel.performFetch()
        viewModel.observeReloadNeeded { [weak self] in
            self?.tableView.reloadData()
        }

        viewModel.$syncCategoriesState.combineLatest(viewModel.$categoryViewModels)
            .sink { [weak self] syncState, models in
                guard let self = self else { return }
                self.emptyStateViewController.view.isHidden = true
                self.tableView.isHidden = false
                switch syncState {
                case .initialized:
                    break
                case .syncing:
                    if models.isEmpty {
                        self.displayGhostContent()
                    }
                case let .failed(retryToken):
                    self.removeGhostContent()
                    self.displaySyncingErrorNotice(retryToken: retryToken)
                case .synced:
                    self.tableView.reloadData()
                    self.removeGhostContent()
                    if models.isEmpty {
                        self.emptyStateViewController.view.isHidden = false
                        self.tableView.isHidden = true
                    }
                    self.glanceTrailingActionsIfNeeded()
                }
            }
            .store(in: &subscriptions)
    }

    /// Slightly reveal swipe actions of the first visible cell that contains at least one swipe action.
    /// This action is performed only once, using `swipeActionsGlanced` as a control variable.
    ///
    func glanceTrailingActionsIfNeeded() {
        guard configuration.updateEnabled else {
            return
        }
        if !swipeActionsGlanced {
            swipeActionsGlanced = true
            tableView.glanceTrailingSwipeActions()
        }
    }
}

// MARK: - Placeholders & Errors
//
private extension ProductCategoryListViewController {

    /// Displays the Sync Error Notice.
    ///
    func displaySyncingErrorNotice(retryToken: ProductCategoryListViewModel.RetryToken) {
        let message = Localization.syncErrorMessage
        let actionTitle = Localization.retryButtonTitle
        let notice = Notice(title: message, feedbackType: .error, actionTitle: actionTitle) { [weak self] in
            self?.viewModel.retryCategorySynchronization(retryToken: retryToken)
        }

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }
}

// MARK: - UITableViewConformace conformance
//
extension ProductCategoryListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.categoryViewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(ProductCategoryTableViewCell.self, for: indexPath)

        if let categoryViewModel = viewModel.categoryViewModels[safe: indexPath.row] {
            cell.configure(with: categoryViewModel)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewModel.selectOrDeselectCategory(index: indexPath.row)
        tableView.reloadData()
        searchBar.resignFirstResponder()
    }

    /// Provides an implementation to show cell swipe actions. Return `nil` to provide no action.
    ///
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        /// Only enable editing and deleting if update is enabled
        guard configuration.updateEnabled else {
            return nil
        }
        let deleteAction = UIContextualAction(style: .destructive, title: nil, handler: { [weak self] _, _, completionHandler in
            guard let self,
                let model = self.viewModel.categoryViewModels[safe: indexPath.row] else { return }
            self.showDeleteAlert(for: model)
            completionHandler(true) // Tells the table that the action was performed and forces it to go back to its original state (un-swiped)
        })
        deleteAction.backgroundColor = .error
        deleteAction.title = Localization.delete

        let editAction = UIContextualAction(style: .normal, title: nil, handler: { [weak self] _, _, completionHandler in
            guard let self,
                let model = self.viewModel.categoryViewModels[safe: indexPath.row] else { return }
            self.editCategory(model: model)
            completionHandler(true) // Tells the table that the action was performed and forces it to go back to its original state (un-swiped)
        })
        editAction.backgroundColor = .accent
        editAction.title = Localization.edit

        return UISwipeActionsConfiguration(actions: [editAction, deleteAction])
    }

    func editCategory(model: ProductCategoryCellViewModel) {
        guard let id = model.categoryID,
              let category = viewModel.findCategory(with: id) else {
            return
        }

        ServiceLocator.analytics.track(.productCategorySettingsEditButtonTapped)

        let parent = viewModel.findCategory(with: category.parentID)
        let viewModel = AddEditProductCategoryViewModel(siteID: viewModel.siteID,
                                                        existingCategory: category,
                                                        parentCategory: parent) { [weak self] _ in
            defer {
                self?.dismiss(animated: true, completion: nil)
            }
            self?.viewModel.performFetch()
        }
        let addCategoryViewController = AddEditProductCategoryViewController(viewModel: viewModel)
        let navController = WooNavigationController(rootViewController: addCategoryViewController)
        present(navController, animated: true, completion: nil)
    }

    func showDeleteAlert(for model: ProductCategoryCellViewModel) {
        let title = String.localizedStringWithFormat(Localization.DeleteAlert.title, model.name)
        let alertController = UIAlertController(title: title,
                                                message: Localization.DeleteAlert.message,
                                                preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: Localization.delete, style: .destructive) { [weak self] _ in
            guard let self, let id = model.categoryID else {
                return
            }
            ServiceLocator.analytics.track(.productCategorySettingsDeleteButtonTapped)
            Task { @MainActor in
                await self.viewModel.deleteCategory(id: id)
            }
        }
        let cancelAction = UIAlertAction(title: Localization.cancel, style: .cancel)
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        present(alertController, animated: true)
    }

    func configureDeletionError() {
        viewModel.$deletionFailure
            .sink { [weak self] error in
                guard let self, let error else {
                    return
                }
                self.showDeletionFailureAlert(error: error)
            }
            .store(in: &subscriptions)
    }

    func showDeletionFailureAlert(error: Error) {
        let alertController = UIAlertController(title: nil,
                                                message: error.localizedDescription,
                                                preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: Localization.cancel, style: .cancel)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
}

private extension ProductCategoryListViewController {
    enum Localization {
        static let searchBarPlaceholder = NSLocalizedString("Search Categories", comment: "Placeholder text on the search bar on the category list")
        static let syncErrorMessage = NSLocalizedString("Unable to load categories", comment: "Notice message when loading product categories fails")
        static let retryButtonTitle = NSLocalizedString("Retry", comment: "Retry Action on the notice when loading product categories fails")
        static let clearSelectionButtonTitle = NSLocalizedString("Clear Selection", comment: "Button to clear selection on the product categories list")
        static let emptyStateMessage = NSLocalizedString("No product categories found",
                                                         comment: "Message on the empty view when the category list or its search result is empty.")
        static let cancel = NSLocalizedString("Cancel", comment: "Button to dismiss an alert on the product category list screen")
        static let delete = NSLocalizedString("Delete", comment: "Button to delete a product category")
        static let edit = NSLocalizedString("Edit", comment: "Button to edit a product category")

        enum DeleteAlert {
            static let title = NSLocalizedString(
                "Delete %1$@",
                comment: "Title of the confirmation alert to delete product category. Reads like: Delete Clothing"
            )
            static let message = NSLocalizedString(
                "Are you sure you want to delete this category permanently?",
                comment: "Message on the confirmation alert to delete product category"
            )
        }
    }
}

// MARK: - UISearchBarDelegate conformance
//
extension ProductCategoryListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchQuery = searchText
    }
}
