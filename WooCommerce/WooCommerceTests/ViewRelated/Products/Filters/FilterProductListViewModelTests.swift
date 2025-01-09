import XCTest
@testable import WooCommerce
@testable import Yosemite

final class FilterProductListViewModelTests: XCTestCase {
    let filterProductCategory = ProductCategory(categoryID: 0, siteID: 0, parentID: 0, name: "", slug: "")

    func testCriteriaWithDefaultFilters() {
        // Given
        let filters = FilterProductListViewModel.Filters()

        // When
        let viewModel = FilterProductListViewModel(filters: filters, siteID: 0)

        // Then
        let expectedCriteria = FilterProductListViewModel.Filters(stockStatus: nil,
                                                                  productStatus: nil,
                                                                  promotableProductType: nil,
                                                                  productCategory: nil,
                                                                  favoriteProduct: nil,
                                                                  numberOfActiveFilters: 0)
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }

    func test_criteria_with_non_nil_filters_then_it_returns_all_active_filters() {
        // Given
        let featureFlagService = MockFeatureFlagService(favoriteProducts: true)
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock,
                                                         productStatus: .draft,
                                                         promotableProductType: PromotableProductType(productType: .grouped,
                                                                                                      isAvailable: true,
                                                                                                      promoteUrl: nil),
                                                         productCategory: filterProductCategory,
                                                         favoriteProduct: FavoriteProductsFilter(),
                                                         numberOfActiveFilters: 5)

        // When
        let viewModel = FilterProductListViewModel(filters: filters,
                                                   siteID: 0,
                                                   featureFlagService: featureFlagService)

        // Then
        let expectedCriteria = filters
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }

    func test_criteria_after_clearing_all_non_nil_filters_then_it_returns_no_active_filter() {
        // Given
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock,
                                                         productStatus: .draft,
                                                         promotableProductType: PromotableProductType(productType: .grouped,
                                                                                                      isAvailable: true,
                                                                                                      promoteUrl: nil),
                                                         productCategory: filterProductCategory,
                                                         favoriteProduct: FavoriteProductsFilter(),
                                                         numberOfActiveFilters: 5)

        // When
        let viewModel = FilterProductListViewModel(filters: filters, siteID: 0)
        viewModel.clearAll()

        // Then
        let expectedCriteria = FilterProductListViewModel.Filters(stockStatus: nil,
                                                                  productStatus: nil,
                                                                  promotableProductType: nil,
                                                                  productCategory: nil,
                                                                  favoriteProduct: nil,
                                                                  numberOfActiveFilters: 0)
        XCTAssertEqual(viewModel.criteria, expectedCriteria)
    }

    // MARK: Favorite product feature flag

    func test_filterTypeViewModels_does_not_contain_favorite_filter_view_model_when_feature_flag_off() {
        // Given
        let featureFlagService = MockFeatureFlagService(favoriteProducts: false)
        let filters = FilterProductListViewModel.Filters(stockStatus: .inStock,
                                                         productStatus: .draft,
                                                         promotableProductType: PromotableProductType(productType: .grouped,
                                                                                                      isAvailable: true,
                                                                                                      promoteUrl: nil),
                                                         productCategory: filterProductCategory,
                                                         favoriteProduct: FavoriteProductsFilter(),
                                                         numberOfActiveFilters: 5)

        // When
        let viewModel = FilterProductListViewModel(filters: filters,
                                                   siteID: 0,
                                                   featureFlagService: featureFlagService)

        // Then
        XCTAssertFalse(viewModel.filterTypeViewModels.contains(where: { $0.title == FilterProductListViewModel.ProductListFilter.Localization.favoriteProduct } ))
    }

    func test_applyPastFilter_updates_the_filters_correctly() {
        // Given
        let filters = createMockFilters(stockStatus: .inStock)
        let viewModel = FilterProductListViewModel(filters: filters, siteID: 0)

        // When
        let newFilter = createMockFilters(stockStatus: .onBackOrder)
        viewModel.applyPastFilter(newFilter)

        // Then
        XCTAssertEqual(viewModel.criteria.stockStatus, .onBackOrder)
    }

    @MainActor
    func test_retrieveFilterHistory_returns_correct_results() async throws {
        // Given
        let siteID: Int64 = 123
        let expectedFilters = createMockFilters(stockStatus: .outOfStock)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadProductFilterHistory(_, onCompletion):
                onCompletion(.success([StoredProductSettings.Setting(siteID: siteID,
                                                                     sort: nil,
                                                                     stockStatusFilter: expectedFilters.stockStatus,
                                                                     productStatusFilter: expectedFilters.productStatus,
                                                                     productTypeFilter: expectedFilters.promotableProductType?.productType,
                                                                     productCategoryFilter: expectedFilters.productCategory,
                                                                     favoriteProduct: expectedFilters.favoriteProduct?.isActive ?? false)]))
            default:
                break
            }
        }

        let viewModel = FilterProductListViewModel(filters: createMockFilters(), siteID: siteID, stores: stores)

        // When
        let retrievedFilters = try await viewModel.retrieveFilterHistory()

        // Then
        XCTAssertEqual(retrievedFilters, [expectedFilters])
    }

    func test_saveSelectedFilterToHistory_sends_correct_settings_to_storage() {
        // Given
        let siteID: Int64 = 123
        let filters = createMockFilters()
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        var savedSettings: StoredProductSettings.Setting?
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .upsertProductFilterHistory(settings, onCompletion):
                savedSettings = settings
                onCompletion(nil)
            default:
                break
            }
        }
        let viewModel = FilterProductListViewModel(filters: filters, siteID: siteID, stores: stores)

        // When
        viewModel.saveSelectedFilterToHistory(filters)

        // Then
        XCTAssertEqual(savedSettings?.stockStatusFilter, filters.stockStatus)
        XCTAssertEqual(savedSettings?.productTypeFilter, filters.promotableProductType?.productType)
        XCTAssertEqual(savedSettings?.productStatusFilter, filters.productStatus)
        XCTAssertEqual(savedSettings?.productCategoryFilter, filters.productCategory)
        XCTAssertEqual(savedSettings?.favoriteProduct, filters.favoriteProduct?.isActive ?? false)
    }

    func test_removeFilterFromHistory_removes_the_correct_settings_in_storage() {
        // Given
        let siteID: Int64 = 123
        let filters = createMockFilters()
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        var removedSettings: StoredProductSettings.Setting?
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .removeFromProductFilterHistory(settings, onCompletion):
                removedSettings = settings
                onCompletion(nil)
            default:
                break
            }
        }
        let viewModel = FilterProductListViewModel(filters: filters, siteID: siteID, stores: stores)

        // When
        viewModel.removeFilterFromHistory(filters)

        // Then
        XCTAssertEqual(removedSettings?.stockStatusFilter, filters.stockStatus)
        XCTAssertEqual(removedSettings?.productTypeFilter, filters.promotableProductType?.productType)
        XCTAssertEqual(removedSettings?.productStatusFilter, filters.productStatus)
        XCTAssertEqual(removedSettings?.productCategoryFilter, filters.productCategory)
        XCTAssertEqual(removedSettings?.favoriteProduct, filters.favoriteProduct?.isActive ?? false)
    }
}

private extension FilterProductListViewModelTests {
    func createMockFilters(stockStatus: ProductStockStatus? = .inStock) -> FilterProductListViewModel.Filters {
        FilterProductListViewModel.Filters(stockStatus: stockStatus,
                                           productStatus: .draft,
                                           promotableProductType: PromotableProductType(productType: .grouped,
                                                                                        isAvailable: true,
                                                                                        promoteUrl: nil),
                                           productCategory: filterProductCategory,
                                           favoriteProduct: FavoriteProductsFilter(),
                                           numberOfActiveFilters: 5)
    }
}
