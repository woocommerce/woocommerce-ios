import Foundation
import XCTest
import Yosemite

@testable import WooCommerce

/// Tests for `PriceInputViewController`.
///
final class PriceInputViewControllerTests: XCTestCase {
    private let sampleSiteID: Int64 = 123
    private var storesManager: MockStoresManager!

    override func setUp() {
        super.setUp()
        storesManager = MockStoresManager(sessionManager: .makeForTesting())
    }

    override func tearDown() {
        storesManager = nil
        super.tearDown()
    }

    func test_view_controller_displays_notice_on_selected_regular_price_is_less_than_sale_price_validation_error() throws {
        // Given
        let noticePresenter = MockNoticePresenter()
        let listViewModel = ProductListViewModel(siteID: sampleSiteID, stores: storesManager)
        let sampleProduct1 = Product.fake().copy(productID: 1, dateOnSaleStart: Date(), dateOnSaleEnd: Date(), regularPrice: "100", salePrice: "42")
        listViewModel.selectProduct(sampleProduct1)

        let viewModel = PriceInputViewModel(productListViewModel: listViewModel)
        let viewController = PriceInputViewController(viewModel: viewModel, noticePresenter: noticePresenter)

        // When
        _ = try XCTUnwrap(viewController.view)
        viewModel.handlePriceChange("24")
        viewModel.applyButtonTapped()

        waitUntil {
            noticePresenter.queuedNotices.count == 1
        }

        // Then
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        XCTAssertEqual(notice.feedbackType, .error)
    }

    func test_view_controller_displays_notice_on_no_regular_price_validation_error() throws {
        // Given
        let noticePresenter = MockNoticePresenter()
        let listViewModel = ProductListViewModel(siteID: sampleSiteID, stores: storesManager)
        let sampleProduct1 = Product.fake().copy(productID: 1, dateOnSaleStart: Date(), dateOnSaleEnd: Date(), regularPrice: "100", salePrice: "42")
        listViewModel.selectProduct(sampleProduct1)

        let viewModel = PriceInputViewModel(productListViewModel: listViewModel)
        let viewController = PriceInputViewController(viewModel: viewModel, noticePresenter: noticePresenter)

        // When
        _ = try XCTUnwrap(viewController.view)
        viewModel.handlePriceChange("")
        viewModel.applyButtonTapped()

        waitUntil {
            noticePresenter.queuedNotices.count == 1
        }

        // Then
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        XCTAssertEqual(notice.feedbackType, .error)
    }
}
