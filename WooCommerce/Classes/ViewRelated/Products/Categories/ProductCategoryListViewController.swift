import UIKit
import Yosemite
import WordPressUI

/// ProductCategoryListViewController: Displays the list of ProductCategories associated to the active Account.
/// Please note that this class cannot be used as is, since there is not configuration for navigation.
/// Instead, it shall be embedded through view controller containment by adding it as a child to other view controllers.
///
final class ProductCategoryListViewController: UIViewController, GhostableViewController {

    @IBOutlet private var tableView: UITableView!

    lazy var ghostTableViewController = GhostTableViewController(options: GhostTableViewOptions(displaysSectionHeader: false,
                                                                                                cellClass: ProductCategoryTableViewCell.self,
                                                                                                tableViewStyle: .plain))

    let viewModel: ProductCategoryListViewModel

    init(viewModel: ProductCategoryListViewModel) {
        self.viewModel = viewModel

        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        registerTableViewCells()
        configureTableView()
        configureViewModel()
        handleSwipeBackGesture()
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
            switch syncState {
            case .initialized:
                break
            case .syncing:
                self?.displayGhostContent()
            case let .failed(retryToken):
                self?.removeGhostContent()
                self?.displaySyncingErrorNotice(retryToken: retryToken)
            case .synced:
                self?.tableView.reloadData()
                self?.removeGhostContent()
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
        let message = NSLocalizedString("Unable to load categories", comment: "Load Product Categories Action Failed")
        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
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
