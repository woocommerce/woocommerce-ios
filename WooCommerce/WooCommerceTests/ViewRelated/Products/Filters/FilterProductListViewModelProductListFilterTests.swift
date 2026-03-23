import XCTest
import YosemiteTestHelpers
@testable import WooCommerce
@testable import Yosemite

final class FilterProductListViewModelProductListFilterTests: XCTestCase {
    let sampleSiteID: Int64 = 123
    let filterProductCategory = ProductCategory(categoryID: 0, siteID: 123, parentID: 0, name: "", slug: "")

    func testCreatingStockStatusFilterTypeViewModel() {
        let mockStorage = MockStorageManager()
        mockStorage.insertSampleSite(
            readOnlySite: Site.fake().copy(
                siteID: sampleSiteID,
                isGarden: false,
            )
        )
        let filterType = FilterProductListViewModel.ProductListFilter.stockStatus
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock,
                                                         productStatus: .draft,
                                                         promotableProductType: PromotableProductType(productType: .grouped,
                                                                                                      isAvailable: true,
                                                                                                      promoteUrl: nil),
                                                         productCategory: filterProductCategory,
                                                         favoriteProduct: nil,
                                                         numberOfActiveFilters: 4)
        let viewModel = filterType.createViewModel(filters: filters)
        XCTAssertEqual(viewModel.selectedValue as? ProductStockStatus, .inStock)
    }

    func testCreatingProductStatusFilterTypeViewModel() {
        let mockStorage = MockStorageManager()
        mockStorage.insertSampleSite(
            readOnlySite: Site.fake().copy(
                siteID: sampleSiteID,
                isGarden: false,
            )
        )
        let filterType = FilterProductListViewModel.ProductListFilter.productStatus
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock,
                                                         productStatus: .draft,
                                                         promotableProductType: PromotableProductType(productType: .grouped,
                                                                                                      isAvailable: true,
                                                                                                      promoteUrl: nil),
                                                         productCategory: filterProductCategory,
                                                         favoriteProduct: nil,
                                                         numberOfActiveFilters: 4)
        let viewModel = filterType.createViewModel(filters: filters)
        XCTAssertEqual(viewModel.selectedValue as? ProductStatus, .draft)
    }

    func testCreatingProductTypeFilterTypeViewModel() {
        let mockStorage = MockStorageManager()
        mockStorage.insertSampleSite(
            readOnlySite: Site.fake().copy(
                siteID: sampleSiteID,
                isGarden: false,
            )
        )

        let filterType = FilterProductListViewModel.ProductListFilter.productType(siteID: sampleSiteID)
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock,
                                                         productStatus: .draft,
                                                         promotableProductType: PromotableProductType(productType: .grouped,
                                                                                                      isAvailable: true,
                                                                                                      promoteUrl: nil),
                                                         productCategory: filterProductCategory,
                                                         favoriteProduct: nil,
                                                         numberOfActiveFilters: 4)
        let viewModel = filterType.createViewModel(filters: filters)
        XCTAssertEqual((viewModel.selectedValue as? PromotableProductType)?.productType, .grouped)
    }

    func testCreatingProductCategoryFilterTypeViewModel() {
        let mockStorage = MockStorageManager()
        mockStorage.insertSampleSite(
            readOnlySite: Site.fake().copy(
                siteID: sampleSiteID,
                isGarden: false,
            )
        )

        let filterType = FilterProductListViewModel.ProductListFilter.productCategory(siteID: sampleSiteID)

        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock,
                                                         productStatus: .draft,
                                                         promotableProductType: PromotableProductType(productType: .grouped,
                                                                                                      isAvailable: true,
                                                                                                      promoteUrl: nil),
                                                         productCategory: filterProductCategory,
                                                         favoriteProduct: nil,
                                                         numberOfActiveFilters: 4)
        let viewModel = filterType.createViewModel(filters: filters)
        XCTAssertEqual(viewModel.selectedValue as? ProductCategory, filterProductCategory)
    }

    func test_creating_promotable_product_types_with_no_plugins_outputs_correct_types() throws {
        // Given
        let filterType = FilterProductListViewModel.ProductListFilter.productType(siteID: sampleSiteID)
        let filters = FilterProductListViewModel.Filters(stockStatus: nil,
                                                         productStatus: nil,
                                                         promotableProductType: nil,
                                                         productCategory: nil,
                                                         favoriteProduct: nil,
                                                         numberOfActiveFilters: 0)
        let provider = StandardFilterableProductTypeProvider(activePlugins: [])

        // When
        let viewModel = filterType.createViewModel(filters: filters,
                                                   filterableProductTypeProvider: provider)
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
        let filterType = FilterProductListViewModel.ProductListFilter.productType(siteID: sampleSiteID)
        let filters = FilterProductListViewModel.Filters(stockStatus: nil,
                                                         productStatus: nil,
                                                         promotableProductType: nil,
                                                         productCategory: nil,
                                                         favoriteProduct: nil,
                                                         numberOfActiveFilters: 0)
        let provider = StandardFilterableProductTypeProvider(
            activePlugins: [.wooSubscriptions, .wooProductBundles]
        )

        // When
        let viewModel = filterType.createViewModel(filters: filters,
                                                   filterableProductTypeProvider: provider)
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

    func test_creating_promotable_product_types_for_ciab_site_outputs_correct_types() throws {
        // Given
        let filterType = FilterProductListViewModel.ProductListFilter.productType(
            siteID: sampleSiteID
        )

        let filters = FilterProductListViewModel.Filters(
            stockStatus: nil,
            productStatus: nil,
            promotableProductType: nil,
            productCategory: nil,
            favoriteProduct: nil,
            numberOfActiveFilters: 0
        )

        // When
        let viewModel = filterType.createViewModel(
            filters: filters,
            filterableProductTypeProvider: CIABFilterableProductTypeProvider()
        )

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
            .init(productType: .booking, isAvailable: true, promoteUrl: nil),
            .init(productType: .affiliate, isAvailable: true, promoteUrl: nil)
        ])
    }
}
