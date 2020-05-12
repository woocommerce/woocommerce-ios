import UIKit
import Yosemite

/// `FilterListViewModel` for filtering a list of products.
final class FilterProductListViewModel: FilterListViewModel {
    typealias Criteria = Filters

    /// Aggregates the filter values that can be updated in the Filter Products UI.
    struct Filters {
        let stockStatus: ProductStockStatus?
        let productStatus: ProductStatus?
        let productType: ProductType?

        let numberOfActiveFilters: Int

        init() {
            stockStatus = nil
            productStatus = nil
            productType = nil
            numberOfActiveFilters = 0
        }

        init(stockStatus: ProductStockStatus?, productStatus: ProductStatus?, productType: ProductType?, numberOfActiveFilters: Int) {
            self.stockStatus = stockStatus
            self.productStatus = productStatus
            self.productType = productType
            self.numberOfActiveFilters = numberOfActiveFilters
        }
    }

    let filterActionTitle = NSLocalizedString("Show Products", comment: "Button title for applying filters to a list of products.")

    let filterTypeViewModels: [FilterTypeViewModel]

    private let stockStatusFilterViewModel: FilterTypeViewModel
    private let productStatusFilterViewModel: FilterTypeViewModel
    private let productTypeFilterViewModel: FilterTypeViewModel

    /// - Parameters:
    ///   - filters: the filters to be applied initially.
    init(filters: Filters) {
        self.stockStatusFilterViewModel = ProductListFilter.stockStatus.createViewModel(filters: filters)
        self.productStatusFilterViewModel = ProductListFilter.productStatus.createViewModel(filters: filters)
        self.productTypeFilterViewModel = ProductListFilter.productType.createViewModel(filters: filters)

        self.filterTypeViewModels = [
            stockStatusFilterViewModel,
            productStatusFilterViewModel,
            productTypeFilterViewModel
        ]
    }

    var criteria: Filters {
        let stockStatus = stockStatusFilterViewModel.selectedValue as? ProductStockStatus ?? nil
        let productStatus = productStatusFilterViewModel.selectedValue as? ProductStatus ?? nil
        let productType = productTypeFilterViewModel.selectedValue as? ProductType ?? nil
        let numberOfActiveFilters = filterTypeViewModels.numberOfActiveFilters
        return Filters(stockStatus: stockStatus, productStatus: productStatus, productType: productType, numberOfActiveFilters: numberOfActiveFilters)
    }

    func clearAll() {
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
            return NSLocalizedString("Stock Status", comment: "Row title for filtering products by stock status.")
        case .productStatus:
            return NSLocalizedString("Product Status", comment: "Row title for filtering products by product status.")
        case .productType:
            return NSLocalizedString("Product Type", comment: "Row title for filtering products by product type.")
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
