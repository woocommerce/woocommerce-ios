import UIKit
import Yosemite
import Experiments
import WooFoundation
import protocol Storage.StorageManagerType

/// `FilterListViewModel` for filtering a list of products.
final class FilterProductListViewModel: FilterListViewModel {
    typealias Criteria = Filters

    /// Aggregates the filter values that can be updated in the Filter Products UI.
    struct Filters: Equatable {
        let stockStatus: ProductStockStatus?
        let productStatus: ProductStatus?
        let promotableProductType: PromotableProductType?
        let productCategory: ProductCategory?

        let numberOfActiveFilters: Int

        init() {
            stockStatus = nil
            productStatus = nil
            promotableProductType = nil
            productCategory = nil
            numberOfActiveFilters = 0
        }

        init(stockStatus: ProductStockStatus?,
             productStatus: ProductStatus?,
             promotableProductType: PromotableProductType?,
             productCategory: ProductCategory?,
             numberOfActiveFilters: Int) {
            self.stockStatus = stockStatus
            self.productStatus = productStatus
            self.promotableProductType = promotableProductType
            self.productCategory = productCategory
            self.numberOfActiveFilters = numberOfActiveFilters
        }

        // Generate a string based on populated filters, like "instock,publish,simple,clothes"
        var analyticsDescription: String {
            let elements: [String?] = [stockStatus?.rawValue, productStatus?.rawValue, promotableProductType?.productType.rawValue, productCategory?.slug]
            return elements.compactMap { $0 }.joined(separator: ",")
        }
    }

    let filterActionTitle = NSLocalizedString("Show Products", comment: "Button title for applying filters to a list of products.")

    let filterTypeViewModels: [FilterTypeViewModel]

    private let stockStatusFilterViewModel: FilterTypeViewModel
    private let productStatusFilterViewModel: FilterTypeViewModel
    private let productTypeFilterViewModel: FilterTypeViewModel
    private let productCategoryFilterViewModel: FilterTypeViewModel

    /// - Parameters:
    ///   - filters: the filters to be applied initially.
    init(filters: Filters, siteID: Int64) {
        self.stockStatusFilterViewModel = ProductListFilter.stockStatus.createViewModel(filters: filters)
        self.productStatusFilterViewModel = ProductListFilter.productStatus.createViewModel(filters: filters)
        self.productTypeFilterViewModel = ProductListFilter.productType(siteID: siteID).createViewModel(filters: filters)
        self.productCategoryFilterViewModel = ProductListFilter.productCategory(siteID: siteID).createViewModel(filters: filters)

        self.filterTypeViewModels = [
            stockStatusFilterViewModel,
            productStatusFilterViewModel,
            productTypeFilterViewModel,
            productCategoryFilterViewModel
        ]
    }

    var criteria: Filters {
        let stockStatus = stockStatusFilterViewModel.selectedValue as? ProductStockStatus ?? nil
        let productStatus = productStatusFilterViewModel.selectedValue as? ProductStatus ?? nil
        let promotableProductType = productTypeFilterViewModel.selectedValue as? PromotableProductType ?? nil
        let productCategory = productCategoryFilterViewModel.selectedValue as? ProductCategory ?? nil

        let numberOfActiveFilters = filterTypeViewModels.numberOfActiveFilters

        return Filters(stockStatus: stockStatus,
                       productStatus: productStatus,
                       promotableProductType: promotableProductType,
                       productCategory: productCategory,
                       numberOfActiveFilters: numberOfActiveFilters)
    }

    func clearAll() {
        let clearedStockStatus: ProductStockStatus? = nil
        stockStatusFilterViewModel.selectedValue = clearedStockStatus

        let clearedProductStatus: ProductStatus? = nil
        productStatusFilterViewModel.selectedValue = clearedProductStatus

        let clearedProductType: PromotableProductType? = nil
        productTypeFilterViewModel.selectedValue = clearedProductType

        let clearedProductCategory: ProductCategory? = nil
        productCategoryFilterViewModel.selectedValue = clearedProductCategory
    }
}

extension FilterProductListViewModel {
    /// Rows listed in the order they appear on screen
    ///
    enum ProductListFilter {
        case stockStatus
        case productStatus
        case productType(siteID: Int64)
        case productCategory(siteID: Int64)
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
        case .productCategory:
            return NSLocalizedString("Product Category", comment: "Row title for filtering products by product category.")
        }
    }
}

extension FilterProductListViewModel.ProductListFilter {
    func createViewModel(filters: FilterProductListViewModel.Filters,
                         storageManager: StorageManagerType = ServiceLocator.storageManager) -> FilterTypeViewModel {
        switch self {
        case .stockStatus:
            let options: [ProductStockStatus?] = [nil, .inStock, .outOfStock, .onBackOrder]
            return FilterTypeViewModel(title: title,
                                       listSelectorConfig: .staticOptions(options: options),
                                       selectedValue: filters.stockStatus)
        case .productStatus:
            let options: [ProductStatus?] = [nil, .published, .draft, .pending, .privateStatus]
            return FilterTypeViewModel(title: title,
                                       listSelectorConfig: .staticOptions(options: options),
                                       selectedValue: filters.productStatus)
        case let .productType(siteID):
            let options = buildPromotableTypes(siteID: siteID, storageManager: storageManager)
            return FilterTypeViewModel(title: title,
                                       listSelectorConfig: .staticOptions(options: options),
                                       selectedValue: filters.promotableProductType)
        case let .productCategory(siteID):
            return FilterTypeViewModel(title: title,
                                       listSelectorConfig: .productCategories(siteID: siteID),
                                       selectedValue: filters.productCategory)
        }
    }

    /// Builds the products types filter array identifying which extension is available or not.
    ///
    private func buildPromotableTypes(siteID: Int64, storageManager: StorageManagerType) -> [PromotableProductType?] {
        let activePluginNames = fetchActivePluginNames(siteID: siteID, storageManager: storageManager)
        let isSubscriptionsAvailable = Set(activePluginNames).intersection(SitePlugin.SupportedPlugin.WCSubscriptions).count > 0
        let isCompositeProductsAvailable = activePluginNames.contains(SitePlugin.SupportedPlugin.WCCompositeProducts)
        let isProductBundlesAvailable = activePluginNames.contains(where: SitePlugin.SupportedPlugin.WCProductBundles.contains)

        return [nil,
                .init(productType: .simple, isAvailable: true, promoteUrl: nil),
                .init(productType: .variable, isAvailable: true, promoteUrl: nil),
                .init(productType: .grouped, isAvailable: true, promoteUrl: nil),
                .init(productType: .affiliate, isAvailable: true, promoteUrl: nil),
                .init(productType: .subscription,
                      isAvailable: isSubscriptionsAvailable,
                      promoteUrl: WooConstants.URLs.subscriptionsExtension.asURL()),
                .init(productType: .variableSubscription,
                      isAvailable: isSubscriptionsAvailable,
                      promoteUrl: WooConstants.URLs.subscriptionsExtension.asURL()),
                .init(productType: .bundle,
                      isAvailable: isProductBundlesAvailable,
                      promoteUrl: WooConstants.URLs.productBundlesExtension.asURL()),
                .init(productType: .composite,
                      isAvailable: isCompositeProductsAvailable,
                      promoteUrl: WooConstants.URLs.compositeProductsExtension.asURL())]
    }

    /// Fetches the active plugin names for the provided site IDs using a `ResultsController`
    ///
    private func fetchActivePluginNames(siteID: Int64, storageManager: StorageManagerType) -> [String] {
        let predicate = \StorageSystemPlugin.siteID == siteID && \StorageSystemPlugin.active == true
        let resultsController = ResultsController<StorageSystemPlugin>(storageManager: storageManager, sortedBy: [])
        resultsController.predicate = predicate

        try? resultsController.performFetch()
        return resultsController.fetchedObjects.map { $0.name }
    }
}
