import XCTest

@testable import WooCommerce
@testable import Yosemite
@testable import Networking

final class FilterProductCategoryListViewModelTests: XCTestCase {
    private var filterProductCategoryListViewModel: FilterProductCategoryListViewModel!
    private var productCategoryListViewModel: ProductCategoryListViewModel!

    override func setUp() {
        super.setUp()

        filterProductCategoryListViewModel = FilterProductCategoryListViewModel()
        productCategoryListViewModel = ProductCategoryListViewModel(storesManager: MockProductCategoryStoresManager(),
                                                                    siteID: 0,
                                                                    dataSource: filterProductCategoryListViewModel,
                                                                    delegate: filterProductCategoryListViewModel)
    }

    override func tearDown() {
        super.tearDown()

        filterProductCategoryListViewModel = nil
        productCategoryListViewModel = nil
    }

    func test_enrichCategoryViewModels_then_it_adds_the_any_category_view_model() {
        // Given
        let categoryViewModel = ProductCategoryCellViewModel(categoryID: 1,
                                                              name: NSLocalizedString("Any", comment: "Title when there is no filter set."),
                                                              isSelected: true,
                                                              indentationLevel: 0)

        // When
        let enrichedViewModels = filterProductCategoryListViewModel.enrichCategoryViewModels([categoryViewModel])

        // Then
        let expectedAnyCategoryViewModel = ProductCategoryCellViewModel(categoryID: nil,
                                                                        name: NSLocalizedString("Any", comment: "Title when there is no filter set."),
                                                                        isSelected: true,
                                                                        indentationLevel: 0)
        XCTAssertEqual(enrichedViewModels.count, 2)
        XCTAssertEqual(enrichedViewModels.first, expectedAnyCategoryViewModel)
        XCTAssertEqual(enrichedViewModels.last, categoryViewModel)
    }

    func test_index_other_than_zero_is_selected_then_any_view_model_is_deselected() {
        // When
        filterProductCategoryListViewModel.viewModel(productCategoryListViewModel, didSelectRowAt: 1)

        // Then
        let expectedAnyCategoryViewModel = ProductCategoryCellViewModel(categoryID: nil,
                                                                        name: NSLocalizedString("Any", comment: "Title when there is no filter set."),
                                                                        isSelected: false,
                                                                        indentationLevel: 0)
        let enrichedViewModels = filterProductCategoryListViewModel.enrichCategoryViewModels([])
        XCTAssertEqual(enrichedViewModels.first, expectedAnyCategoryViewModel)
    }

    func test_index_zero_is_selected_then_any_view_model_is_selected() {
        // When
        filterProductCategoryListViewModel.viewModel(productCategoryListViewModel, didSelectRowAt: 0)

        // Then
        let expectedAnyCategoryViewModel = ProductCategoryCellViewModel(categoryID: nil,
                                                                        name: NSLocalizedString("Any", comment: "Title when there is no filter set."),
                                                                        isSelected: true,
                                                                        indentationLevel: 0)
        let enrichedViewModels = filterProductCategoryListViewModel.enrichCategoryViewModels([])
        XCTAssertEqual(enrichedViewModels.first, expectedAnyCategoryViewModel)
    }

    func test_select_index_then_productCategoryListViewModel_reset_categories() {
        // Given
        let exp = expectation(description: #function)

        // When
        productCategoryListViewModel.performFetch()
        productCategoryListViewModel.observeCategoryListStateChanges { [weak self] state in
            guard let self = self else {
                return
            }

            if state == .synced {
                self.filterProductCategoryListViewModel.viewModel(self.productCategoryListViewModel, didSelectRowAt: 0)

                exp.fulfill()
            }
        }

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        // Then
        let expectedAnyCategoryViewModel = ProductCategoryCellViewModel(categoryID: nil,
                                                                        name: NSLocalizedString("Any", comment: "Title when there is no filter set."),
                                                                        isSelected: true,
                                                                        indentationLevel: 0)
        XCTAssertEqual(productCategoryListViewModel.categoryViewModels.first, expectedAnyCategoryViewModel)
        XCTAssertEqual(productCategoryListViewModel.categoryViewModels.count, 1)
    }
}
