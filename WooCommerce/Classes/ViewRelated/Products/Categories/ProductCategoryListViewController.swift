import Combine
import UIKit
import Yosemite
import WordPressUI

/// ProductCategoryListViewController: Displays the list of ProductCategories associated to the active Account.
/// Please note that this class cannot be used as is, since there is not configuration for navigation.
/// Instead, it shall be embedded through view controller containment by adding it as a child to other view controllers.
///
final class ProductCategoryListViewController: UIViewController, GhostableViewController {

    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var searchBar: UISearchBar!
    @IBOutlet private var clearSelectionButtonBarView: UIView!
    @IBOutlet private var clearSelectionButton: UIButton!

    lazy var ghostTableViewController = GhostTableViewController(options: GhostTableViewOptions(cellClass: ProductCategoryTableViewCell.self))

    let viewModel: ProductCategoryListViewModel

    private let configuration: Configuration
    private var selectedListSubscription: AnyCancellable?

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

        configureSearchBar()
        configureClearSelectionButton()
        registerTableViewCells()
        configureTableView()
        configureViewModel()
        handleSwipeBackGesture()
    }
}

// MARK: - Configuration to customize the list
//
extension ProductCategoryListViewController {
    struct Configuration {
        var searchEnabled: Bool = false
        var clearSelectionEnabled: Bool = false
    }
}

// MARK: - View Configuration
//
private extension ProductCategoryListViewController {
    func registerTableViewCells() {
        tableView.registerNib(for: ProductCategoryTableViewCell.self)
    }

    func configureTableView() {
        view.backgroundColor = .listBackground
        tableView.backgroundColor = .listBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.removeLastCellSeparator()
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

        selectedListSubscription = viewModel.$selectedCategories
            .map { [weak self] selectedItems -> Bool in
                guard let self = self, self.configuration.clearSelectionEnabled else {
                    return true
                }
                return selectedItems.isEmpty
            }
            .sink { [weak self] shouldHideClearSelection in
                self?.clearSelectionButtonBarView.isHidden = shouldHideClearSelection
            }
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
        viewModel.observeCategoryListStateChanges { [weak self] syncState in
            guard let self = self else { return }
            switch syncState {
            case .initialized:
                break
            case .syncing:
                if self.viewModel.categoryViewModels.isEmpty {
                    self.displayGhostContent()
                }
            case let .failed(retryToken):
                self.removeGhostContent()
                self.displaySyncingErrorNotice(retryToken: retryToken)
            case .synced:
                self.tableView.reloadData()
                self.removeGhostContent()
            }
        }
    }
}

// MARK: - Placeholders & Errors
//
private extension ProductCategoryListViewController {

    /// Displays the Sync Error Notice.
    ///
    func displaySyncingErrorNotice(retryToken: ProductCategoryListViewModel.RetryToken) {
        let message = Localization.synchErrorMessage
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
    }
}

private extension ProductCategoryListViewController {
    enum Localization {
        static let searchBarPlaceholder = NSLocalizedString("Search Categories", comment: "Placeholder text on the search bar on the category list")
        static let synchErrorMessage = NSLocalizedString("Unable to load categories", comment: "Notice message when loading product categories fails")
        static let retryButtonTitle = NSLocalizedString("Retry", comment: "Retry Action on the notice when loading product categories fails")
        static let clearSelectionButtonTitle = NSLocalizedString("Clear Selection", comment: "Button to clear selection on the product categories list")
    }
}

// MARK: - UISearchBarDelegate conformance
//
extension ProductCategoryListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchQuery = searchText
    }
}
