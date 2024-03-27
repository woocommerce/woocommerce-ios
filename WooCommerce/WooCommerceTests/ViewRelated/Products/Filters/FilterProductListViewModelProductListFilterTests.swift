import XCTest
@testable import WooCommerce
@testable import Yosemite

final class FilterProductListViewModelProductListFilterTests: XCTestCase {
    let filterProductCategory = ProductCategory(categoryID: 0, siteID: 0, parentID: 0, name: "", slug: "")

    func testCreatingStockStatusFilterTypeViewModel() {
        let filterType = FilterProductListViewModel.ProductListFilter.stockStatus
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock,
                                                         productStatus: .draft,
                                                         promotableProductType: PromotableProductType(productType: .grouped,
                                                                                                      isAvailable: true,
                                                                                                      promoteUrl: nil),
                                                         productCategory: filterProductCategory,
                                                         numberOfActiveFilters: 4)
        let viewModel = filterType.createViewModel(filters: filters)
        XCTAssertEqual(viewModel.selectedValue as? ProductStockStatus, .inStock)
    }

    func testCreatingProductStatusFilterTypeViewModel() {
        let filterType = FilterProductListViewModel.ProductListFilter.productStatus
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock,
                                                         productStatus: .draft,
                                                         promotableProductType: PromotableProductType(productType: .grouped,
                                                                                                      isAvailable: true,
                                                                                                      promoteUrl: nil),
                                                         productCategory: filterProductCategory,
                                                         numberOfActiveFilters: 4)
        let viewModel = filterType.createViewModel(filters: filters)
        XCTAssertEqual(viewModel.selectedValue as? ProductStatus, .draft)
    }

    func testCreatingProductTypeFilterTypeViewModel() {
        let filterType = FilterProductListViewModel.ProductListFilter.productType(siteID: 123)
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock,
                                                         productStatus: .draft,
                                                         promotableProductType: PromotableProductType(productType: .grouped,
                                                                                                      isAvailable: true,
                                                                                                      promoteUrl: nil),
                                                         productCategory: filterProductCategory,
                                                         numberOfActiveFilters: 4)
        let viewModel = filterType.createViewModel(filters: filters)
        XCTAssertEqual((viewModel.selectedValue as? PromotableProductType)?.productType, .grouped)
    }

    func testCreatingProductCategoryFilterTypeViewModel() {
        let filterType = FilterProductListViewModel.ProductListFilter.productCategory(siteID: 0)

        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock,
                                                         productStatus: .draft,
                                                         promotableProductType: PromotableProductType(productType: .grouped,
                                                                                                      isAvailable: true,
                                                                                                      promoteUrl: nil),
                                                         productCategory: filterProductCategory,
                                                         numberOfActiveFilters: 4)
        let viewModel = filterType.createViewModel(filters: filters)
        XCTAssertEqual(viewModel.selectedValue as? ProductCategory, filterProductCategory)
    }

    func test_creating_promotable_product_types_with_no_plugins_outputs_correct_types() throws {
        // Given
        let filterType = FilterProductListViewModel.ProductListFilter.productType(siteID: 123)
        let filters = FilterProductListViewModel.Filters(stockStatus: nil,
                                                         productStatus: nil,
                                                         promotableProductType: nil,
                                                         productCategory: nil,
                                                         numberOfActiveFilters: 0)
        let mockStorage = MockStorageManager()

        // When
        let viewModel = filterType.createViewModel(filters: filters, storageManager: mockStorage)
        let options: [PromotableProductType?] = try {
            switch viewModel.listSelectorConfig {
            case .staticOptions(let options):
                return try XCTUnwrap(options as? [PromotableProductType?])
            default:
                XCTFail("Unexpected selector config")
                return []
            }
        }()

        // Then
        XCTAssertEqual(options, [
            nil,
            .init(productType: .simple, isAvailable: true, promoteUrl: nil),
            .init(productType: .variable, isAvailable: true, promoteUrl: nil),
            .init(productType: .grouped, isAvailable: true, promoteUrl: nil),
            .init(productType: .affiliate, isAvailable: true, promoteUrl: nil),
            .init(productType: .subscription, isAvailable: false, promoteUrl: WooConstants.URLs.subscriptionsExtension.asURL()),
            .init(productType: .variableSubscription, isAvailable: false, promoteUrl: WooConstants.URLs.subscriptionsExtension.asURL()),
            .init(productType: .bundle, isAvailable: false, promoteUrl: WooConstants.URLs.productBundlesExtension.asURL()),
            .init(productType: .composite, isAvailable: false, promoteUrl: WooConstants.URLs.compositeProductsExtension.asURL())
        ])
    }

    func test_creating_promotable_product_types_with_plugins_outputs_correct_types() throws {
        // Given
        let sampleSiteID: Int64 = 123
        let filterType = FilterProductListViewModel.ProductListFilter.productType(siteID: sampleSiteID)
        let filters = FilterProductListViewModel.Filters(stockStatus: nil,
                                                         productStatus: nil,
                                                         promotableProductType: nil,
                                                         productCategory: nil,
                                                         numberOfActiveFilters: 0)
        let mockStorage = MockStorageManager()
        mockStorage.insertSampleSystemPlugin(readOnlySystemPlugin: .fake().copy(siteID: sampleSiteID,
                                                                                name: SitePlugin.SupportedPlugin.WCSubscriptions[0],
                                                                                active: true))
        mockStorage.insertSampleSystemPlugin(readOnlySystemPlugin: .fake().copy(siteID: sampleSiteID,
                                                                                name: SitePlugin.SupportedPlugin.WCProductBundles[0],
                                                                                active: true))

        // When
        let viewModel = filterType.createViewModel(filters: filters, storageManager: mockStorage)
        let options: [PromotableProductType?] = try {
            switch viewModel.listSelectorConfig {
            case .staticOptions(let options):
                return try XCTUnwrap(options as? [PromotableProductType?])
            default:
                XCTFail("Unexpected selector config")
                return []
            }
        }()

        // Then
        XCTAssertEqual(options, [
            nil,
            .init(productType: .simple, isAvailable: true, promoteUrl: nil),
            .init(productType: .variable, isAvailable: true, promoteUrl: nil),
            .init(productType: .grouped, isAvailable: true, promoteUrl: nil),
            .init(productType: .affiliate, isAvailable: true, promoteUrl: nil),
            .init(productType: .subscription, isAvailable: true, promoteUrl: WooConstants.URLs.subscriptionsExtension.asURL()),
            .init(productType: .variableSubscription, isAvailable: true, promoteUrl: WooConstants.URLs.subscriptionsExtension.asURL()),
            .init(productType: .bundle, isAvailable: true, promoteUrl: WooConstants.URLs.productBundlesExtension.asURL()),
            .init(productType: .composite, isAvailable: false, promoteUrl: WooConstants.URLs.compositeProductsExtension.asURL())
        ])
    }
}
