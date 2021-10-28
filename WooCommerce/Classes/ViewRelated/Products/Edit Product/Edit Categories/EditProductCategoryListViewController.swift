import UIKit
import Yosemite
import WordPressUI

/// EditProductCategoryListViewController: Displays the list of ProductCategories associated to the active Account, and allows the creation of new categories.
///
final class EditProductCategoryListViewController: UIViewController {

    @IBOutlet weak var bottomContainerView: UIView!
    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private weak var addButtonSeparator: UIView!

    private let productCategoryListViewController: ProductCategoryListViewController
    private let viewModel: EditProductCategoryListViewModel
    private let product: Product

    private let siteID: Int64

    // Completion callback
    //
    typealias Completion = (_ categories: [ProductCategory]) -> Void
    private let onCompletion: Completion

    init(product: Product, completion: @escaping Completion) {
        self.product = product

        let productCategoryListViewModel = ProductCategoryListViewModel(siteID: product.siteID,
                                                                        selectedCategories: product.categories)
        productCategoryListViewController = ProductCategoryListViewController(viewModel: productCategoryListViewModel)
        viewModel = EditProductCategoryListViewModel(product: product,
                                                     baseProductCategoryListViewModel: productCategoryListViewController.viewModel,
                                                     completion: completion)
        siteID = product.siteID
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
        configureProductCategoryListView()
        configureNavigationBar()
        handleSwipeBackGesture()
    }
}

// MARK: - View Configuration
//
private extension EditProductCategoryListViewController {
    func configureAddButton() {
        addButton.setTitle(viewModel.addCategoryButtonTitle, for: .normal)
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        addButton.applySecondaryButtonStyle()
    }

    func configureAddButtonSeparator() {
        addButtonSeparator.backgroundColor = .systemColor(.separator)
    }

    func configureNavigationBar() {
        configureTitle()
        configureRightButton()
    }

    func configureTitle() {
        title = viewModel.addCategoryButtonTitle
    }

    func configureProductCategoryListView() {
        addChild(productCategoryListViewController)
        attachSubview(productCategoryListViewController.view)
        productCategoryListViewController.didMove(toParent: self)
    }

    func attachSubview(_ subview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        bottomContainerView.addSubview(subview)
        bottomContainerView.pinSubviewToAllEdges(subview)
    }

    func configureRightButton() {
        let applyButtonTitle = viewModel.doneButtonTitle
        let rightBarButton = UIBarButtonItem(title: applyButtonTitle,
                                             style: .done,
                                             target: self,
                                             action: #selector(doneButtonTapped))
        navigationItem.setRightBarButton(rightBarButton, animated: false)
    }
}


// MARK: - Navigation actions handling
//
extension EditProductCategoryListViewController {

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
        viewModel.onCompletion()
    }

    @objc private func addButtonTapped() {
        ServiceLocator.analytics.track(.productCategorySettingsAddButtonTapped)
        let addCategoryViewController = AddProductCategoryViewController(siteID: siteID) { [weak self] (newCategory) in
            defer {
                self?.dismiss(animated: true, completion: nil)
            }
            self?.viewModel.addAndSelectNewCategory(category: newCategory)
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
