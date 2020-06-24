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
    typealias Completion = (_ category: ProductCategory) -> Void
    private let onCompletion: Completion


    init(siteID: Int64, completion: @escaping Completion) {
        self.siteID = siteID
        onCompletion = completion
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

        try? resultController.performFetch()
        let fetchedCategories = resultController.fetchedObjects
        categoryViewModels = ProductCategoryListViewModel.CellViewModelBuilder.viewModels(from: fetchedCategories, selectedCategories: [])
    }

}

// MARK: - View Configuration
//
private extension ProductParentCategoriesViewController {

    func configureTitle() {
        title = NSLocalizedString("Select Parent Category", comment: "Select parent category screen - Screen title")
    }

    func registerTableViewCells() {
        tableView.register(ProductCategoryTableViewCell.loadNib(), forCellReuseIdentifier: ProductCategoryTableViewCell.reuseIdentifier)
    }

    func configureTableView() {
        view.backgroundColor = .listBackground
        tableView.backgroundColor = .listBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.removeLastCellSeparator()
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension ProductParentCategoriesViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categoryViewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProductCategoryTableViewCell.reuseIdentifier,
                                                       for: indexPath) as? ProductCategoryTableViewCell else {
            fatalError()
        }

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
