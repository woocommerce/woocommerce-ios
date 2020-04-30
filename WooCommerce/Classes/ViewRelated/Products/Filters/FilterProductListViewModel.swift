import UIKit
import Yosemite

/// `FilterListViewModel` for filtering a list of products.
final class FilterProductListViewModel: FilterListViewModel {
    /// Aggregates the filter values that can be updated in the Filter Products UI.
    struct Filters {
        let stockStatus: ProductStockStatus?
        let productStatus: ProductStatus?
        let productType: ProductType?
    }

    let filterActionTitle = NSLocalizedString("Show Products", comment: "Button title for applying filters to a list of products.")

    let filterTypeViewModels: [FilterTypeViewModel]

    private let stockStatusFilterViewModel: FilterTypeViewModel
    private let productStatusFilterViewModel: FilterTypeViewModel
    private let productTypeFilterViewModel: FilterTypeViewModel

    /// Used to dismiss the Filter Products UI.
    private let sourceViewController: UIViewController

    typealias FilterCompletion = (_ filters: Filters) -> Void
    private let onFilterCompletion: FilterCompletion

    /// - Parameters:
    ///   - sourceViewController: the view controller that presents the Filter Products UI, used to dismiss the screen upon user actions.
    ///   - filters: the filters to be applied initially.
    ///   - onFilterCompletion: called when the user taps the Filter CTA to apply the latest filters to the product list.
    init(sourceViewController: UIViewController, filters: Filters, onFilterCompletion: @escaping FilterCompletion) {
        self.sourceViewController = sourceViewController
        self.onFilterCompletion = onFilterCompletion

        self.stockStatusFilterViewModel = ProductListFilter.stockStatus.createViewModel(filters: filters)
        self.productStatusFilterViewModel = ProductListFilter.productStatus.createViewModel(filters: filters)
        self.productTypeFilterViewModel = ProductListFilter.productType.createViewModel(filters: filters)

        self.filterTypeViewModels = [
            stockStatusFilterViewModel,
            productStatusFilterViewModel,
            productTypeFilterViewModel
        ]
    }

    func onFilterActionTapped() {
        sourceViewController.dismiss(animated: true) { [weak self] in
            guard let self = self else {
                return
            }
            let stockStatus = self.stockStatusFilterViewModel.selectedValue as? ProductStockStatus ?? nil
            let productStatus = self.productStatusFilterViewModel.selectedValue as? ProductStatus ?? nil
            let productType = self.productTypeFilterViewModel.selectedValue as? ProductType ?? nil
            let filters = Filters(stockStatus: stockStatus, productStatus: productStatus, productType: productType)
            self.onFilterCompletion(filters)
        }
    }

    func onDismissActionTapped() {
        sourceViewController.dismiss(animated: true, completion: nil)
    }

    func onClearAllActionTapped() {
        let clearedStockStatus: ProductStockStatus? = nil
        stockStatusFilterViewModel.selectedValue = clearedStockStatus

        let clearedProductStatus: ProductStatus? = nil
        productStatusFilterViewModel.selectedValue = clearedProductStatus

        let clearedProductType: ProductType? = nil
        productTypeFilterViewModel.selectedValue = clearedProductType
    }
}

extension FilterProductListViewModel {
    /// Rows listed in the order they appear on screen
    ///
    enum ProductListFilter {
        case stockStatus
        case productStatus
        case productType
    }
}

private extension FilterProductListViewModel.ProductListFilter {
    var title: String {
        switch self {
        case .stockStatus:
            return NSLocalizedString("Stock status", comment: "Row title for filtering products by stock status.")
        case .productStatus:
            return NSLocalizedString("Product status", comment: "Row title for filtering products by product status.")
        case .productType:
            return NSLocalizedString("Product type", comment: "Row title for filtering products by product type.")
        }
    }
}

extension FilterProductListViewModel.ProductListFilter {
    func createViewModel(filters: FilterProductListViewModel.Filters) -> FilterTypeViewModel {
        switch self {
        case .stockStatus:
            let options: [ProductStockStatus?] = [nil, .inStock, .outOfStock, .onBackOrder]
            return FilterTypeViewModel(title: title,
                                       listSelectorConfig: .staticOptions(options: options),
                                       selectedValue: filters.stockStatus)
        case .productStatus:
            let options: [ProductStatus?] = [nil, .publish, .draft, .pending]
            return FilterTypeViewModel(title: title,
                                       listSelectorConfig: .staticOptions(options: options),
                                       selectedValue: filters.productStatus)
        case .productType:
            let options: [ProductType?] = [nil, .simple, .variable, .grouped, .affiliate]
            return FilterTypeViewModel(title: title,
                                       listSelectorConfig: .staticOptions(options: options),
                                       selectedValue: filters.productType)
        }
    }
}

extension FilterProductListViewModel.Filters: Equatable {
    static func == (lhs: FilterProductListViewModel.Filters, rhs: FilterProductListViewModel.Filters) -> Bool {
        return lhs.stockStatus == rhs.stockStatus &&
            lhs.productStatus == rhs.productStatus &&
            lhs.productType == rhs.productType
    }
}
