import UIKit
import Yosemite
import WordPressUI

/// ProductCategoryListViewController: Displays the list of ProductCategories associated to the active Account.
///
final class ProductCategoryListViewController: UIViewController {

    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private weak var addButtonSeparator: UIView!
    @IBOutlet private var tableView: UITableView!
    private let ghostTableView = UITableView()

    private let viewModel: ProductCategoryListViewModel

    private let siteID: Int64

    // Completion callback
    //
    typealias Completion = (_ categories: [ProductCategory]) -> Void
    private let onCompletion: Completion

    init(product: Product, completion: @escaping Completion) {
        self.viewModel = ProductCategoryListViewModel(product: product)
        self.siteID = product.siteID
        onCompletion = completion
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAddButton()
        configureAddButtonSeparator()
        registerTableViewCells()
        configureTableView()
        configureGhostTableView()
        configureNavigationBar()
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

    func configureAddButton() {
        addButton.setTitle(NSLocalizedString("Add Category", comment: "Action to add category on the Product Categories screen"), for: .normal)
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        addButton.applySecondaryButtonStyle()
    }

    func configureAddButtonSeparator() {
        addButtonSeparator.backgroundColor = .systemColor(.separator)
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

    func configureNavigationBar() {
        configureTitle()
        configureRightButton()
    }

    func configureTitle() {
        title = NSLocalizedString("Categories", comment: "Edit product categories screen - Screen title")
    }

    func configureRightButton() {
        let applyButtonTitle = NSLocalizedString("Done",
                                               comment: "Edit product categories screen - button title to apply categories selection")
        let rightBarButton = UIBarButtonItem(title: applyButtonTitle,
                                             style: .done,
                                             target: self,
                                             action: #selector(doneButtonTapped))
        navigationItem.setRightBarButton(rightBarButton, animated: false)
    }
}

// MARK: - Synchronize Categories
//
private extension ProductCategoryListViewController {
    func configureViewModel() {
        viewModel.performFetch()
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

// MARK: - Navigation actions handling
//
extension ProductCategoryListViewController {

    override func shouldPopOnBackButton() -> Bool {
        if viewModel.hasUnsavedChanges() {
            presentBackNavigationActionSheet()
            return false
        }
        return true
    }

    override func shouldPopOnSwipeBack() -> Bool {
        return shouldPopOnBackButton()
    }

    @objc private func doneButtonTapped() {
        ServiceLocator.analytics.track(.productCategorySettingsDoneButtonTapped)
        onCompletion(viewModel.selectedCategories)
    }

    @objc private func addButtonTapped() {
        ServiceLocator.analytics.track(.productCategorySettingsAddButtonTapped)
        let addCategoryViewController = AddProductCategoryViewController(siteID: siteID) { [weak self] (newCategory) in
            defer {
                self?.dismiss(animated: true, completion: nil)
            }
            self?.viewModel.addAndSelectNewCategory(category: newCategory)
            self?.tableView.reloadData()
        }
        let navController = WooNavigationController(rootViewController: addCategoryViewController)
        present(navController, animated: true, completion: nil)
    }

    private func presentBackNavigationActionSheet() {
        UIAlertController.presentDiscardChangesActionSheet(viewController: self, onDiscard: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
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
