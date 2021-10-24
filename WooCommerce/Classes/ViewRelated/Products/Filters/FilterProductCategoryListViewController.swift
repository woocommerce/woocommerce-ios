
import Foundation
import UIKit
import Yosemite

/// FilterProductCategoryListViewController: Displays the list of ProductCategories associated to the active Account,
/// and allows the selection of one of them, or any.
///
final class FilterProductCategoryListViewController: UIViewController {

    private let siteID: Int64
    private let productCategoryListViewController: ProductCategoryListViewController
    private let viewModel: FilterProductCategoryListViewModel

    init(siteID: Int64) {
        self.siteID = siteID
        self.viewModel = FilterProductCategoryListViewModel()
        let productCategoryListViewModel = ProductCategoryListViewModel(siteID: siteID,
                                                                        selectedCategories: [],
                                                                        dataSource: viewModel,
                                                                        delegate: viewModel)

        productCategoryListViewController = ProductCategoryListViewController(viewModel: productCategoryListViewModel)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureProductCategoryListView()
        configureNavigationBar()
    }

    func configureProductCategoryListView() {
        addChild(productCategoryListViewController)
        attachSubview(productCategoryListViewController.view)
        productCategoryListViewController.didMove(toParent: self)
    }

    private func attachSubview(_ subview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subview)
        view.pinSubviewToAllEdges(subview)
    }

    private func configureNavigationBar() {
        configureTitle()
    }

    private func configureTitle() {
        title = NSLocalizedString("Categories", comment: "Filter product categories screen - Screen title")
    }
}
