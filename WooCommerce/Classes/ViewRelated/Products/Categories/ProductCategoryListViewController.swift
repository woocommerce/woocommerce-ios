import UIKit
import Yosemite
import WordPressUI

/// ProductCategoryListViewController: Displays the list of ProductCategories associated to the active Account.
/// Please note that this class cannot be used as is, since there is not configuration for navigation.
/// Instead, it shall be embedded through view controller containment by adding it as a child to other view controllers.
///
final class ProductCategoryListViewController: UIViewController {

    @IBOutlet private var tableView: UITableView!
    private let ghostTableView = UITableView()

    let viewModel: ProductCategoryListViewModel

    private let siteID: Int64

    init(siteID: Int64, selectedCategories: [ProductCategory]) {
        viewModel = ProductCategoryListViewModel(siteID: siteID, selectedCategories: selectedCategories)
        self.siteID = siteID

        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        registerTableViewCells()
        configureTableView()
        configureGhostTableView()
        configureViewModel()
        handleSwipeBackGesture()
    }
}

// MARK: - View Configuration
//
private extension ProductCategoryListViewController {
    func registerTableViewCells() {
        tableView.registerNib(for: ProductCategoryTableViewCell.self)
        ghostTableView.registerNib(for: ProductCategoryTableViewCell.self)
    }

    func configureTableView() {
        view.backgroundColor = .listBackground
        tableView.backgroundColor = .listBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.removeLastCellSeparator()
    }

    func configureGhostTableView() {
        view.addSubview(ghostTableView)
        ghostTableView.isHidden = true
        ghostTableView.translatesAutoresizingMaskIntoConstraints = false
        ghostTableView.pinSubviewToAllEdges(view)
        ghostTableView.backgroundColor = .listBackground
        ghostTableView.removeLastCellSeparator()
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
                self?.displayGhostTableView()
            case let .failed(retryToken):
                self?.removeGhostTableView()
                self?.displaySyncingErrorNotice(retryToken: retryToken)
            case .synced:
                self?.removeGhostTableView()
            }
        }
    }
}

// MARK: - Placeholders & Errors
//
private extension ProductCategoryListViewController {

    /// Renders ghost placeholder categories.
    ///
    func displayGhostTableView() {
        let placeholderCategoriesPerSection = [3]
        let options = GhostOptions(displaysSectionHeader: false,
                                   reuseIdentifier: ProductCategoryTableViewCell.reuseIdentifier,
                                   rowsPerSection: placeholderCategoriesPerSection)
        ghostTableView.displayGhostContent(options: options,
                                           style: .wooDefaultGhostStyle)
        ghostTableView.isHidden = false
    }

    /// Removes ghost  placeholder categories.
    ///
    func removeGhostTableView() {
        tableView.reloadData()
        ghostTableView.removeGhostContent()
        ghostTableView.isHidden = true
    }

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
