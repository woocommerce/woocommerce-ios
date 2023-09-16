import UIKit
import Yosemite

/// ProductParentCategoriesViewController: fetch all the stored categories associated to the active site.
///
final class ProductParentCategoriesViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    /// The siteID for which we will fetch the product categories
    ///
    private let siteID: Int64

    /// Array of view models to be rendered by the View Controller.
    ///
    private var categoryViewModels: [ProductCategoryCellViewModel] = []

    private lazy var resultController: ResultsController<StorageProductCategory> = {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "siteID = %ld", siteID)
        let descriptor = NSSortDescriptor(keyPath: \StorageProductCategory.name, ascending: true)
        return ResultsController<StorageProductCategory>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    // Completion callback
    //
    typealias Completion = (_ category: ProductCategory?) -> Void
    private let onCompletion: Completion
    private let childCategory: ProductCategory?
    private let selectedCategory: ProductCategory?

    init(siteID: Int64,
         childCategory: ProductCategory?,
         selectedCategory: ProductCategory?,
         completion: @escaping Completion) {
        self.siteID = siteID
        self.onCompletion = completion
        self.childCategory = childCategory
        self.selectedCategory = selectedCategory
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTitle()
        registerTableViewCells()
        configureTableView()
        configureRemoveButton()

        try? resultController.performFetch()

        // Filter to not show child category on the list
        let fetchedCategories = resultController.fetchedObjects.filter { $0.categoryID != childCategory?.categoryID }

        categoryViewModels = ProductCategoryListViewModel.CellViewModelBuilder.viewModels(
            from: fetchedCategories,
            selectedCategories: [selectedCategory].compactMap { $0 }
        )
    }

}

// MARK: - View Configuration
//
private extension ProductParentCategoriesViewController {

    func configureTitle() {
        title = Localization.title
    }

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

    func configureRemoveButton() {
        guard selectedCategory != nil else {
            return
        }
        let containerView = UIView(frame: .zero)
        let removeParentButton = UIButton(frame: .zero)
        removeParentButton.applySecondaryButtonStyle()
        removeParentButton.setTitle(Localization.removeParent, for: .normal)
        removeParentButton.addTarget(self, action: #selector(removeParentCategory), for: .touchUpInside)
        removeParentButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(removeParentButton)
        containerView.pinSubviewToAllEdges(removeParentButton, insets: .init(top: 16, left: 16, bottom: 16, right: 16))
        tableView.tableHeaderView = containerView
        tableView.updateHeaderHeight()
    }

    @objc func removeParentCategory() {
        onCompletion(nil)
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension ProductParentCategoriesViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categoryViewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(ProductCategoryTableViewCell.self, for: indexPath)

        if let categoryViewModel = categoryViewModels[safe: indexPath.row] {
            cell.configure(with: categoryViewModel)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension ProductParentCategoriesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let category = resultController.fetchedObjects.first(where: { $0.categoryID == categoryViewModels[indexPath.row].categoryID }) {
            onCompletion(category)
        }
    }
}

private extension ProductParentCategoriesViewController {
    enum Localization {
        static let title = NSLocalizedString("Select Parent Category", comment: "Select parent category screen - Screen title")
        static let removeParent = NSLocalizedString("No Parent Category", comment: "Button to remove parent category for the existing category")
    }
}
