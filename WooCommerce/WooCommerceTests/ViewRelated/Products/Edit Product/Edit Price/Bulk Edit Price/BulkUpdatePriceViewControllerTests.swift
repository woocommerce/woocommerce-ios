import Foundation
import XCTest
import Yosemite

@testable import WooCommerce

/// Tests for `BulkUpdatePriceViewController`.
///
final class BulkUpdatePriceViewControllerTests: XCTestCase {

    func test_view_controller_displays_notice_on_update_error() throws {
        // Given
        let storesManager = MockStoresManager(sessionManager: SessionManager.makeForTesting())
        let noticePresenter = MockNoticePresenter()
        let viewModel = BulkUpdatePriceSettingsViewModel(siteID: 0,
                                                         productID: 0,
                                                         bulkUpdateOptionsModel: BulkUpdateOptionsModel(productVariations: []),
                                                         editingPriceType: .regular,
                                                         priceUpdateDidFinish: {},
                                                         storesManager: storesManager)
        storesManager.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case let .updateProductVariations(_, _, _, onCompletion):
                onCompletion(.failure(.unexpected))
            default:
                XCTFail("Unsupported Action")
            }
        }
        let viewController = BulkUpdatePriceViewController(viewModel: viewModel, noticePresenter: noticePresenter)

        // When
        _ = try XCTUnwrap(viewController.view)
        viewModel.handlePriceChange("42")
        viewModel.saveButtonTapped()

        waitUntil {
            noticePresenter.queuedNotices.count == 1
        }

        // Then
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        XCTAssertEqual(notice.feedbackType, .error)
    }

    func test_view_controller_displays_notice_on_no_regular_price_validation_error() throws {
        // Given
        let storesManager = MockStoresManager(sessionManager: SessionManager.makeForTesting())
        let noticePresenter = MockNoticePresenter()
        let variations = [MockProductVariation().productVariation().copy(dateOnSaleStart: Date(), dateOnSaleEnd: Date(), salePrice: "42")]
        let viewModel = BulkUpdatePriceSettingsViewModel(siteID: 0,
                                                         productID: 0,
                                                         bulkUpdateOptionsModel: BulkUpdateOptionsModel(productVariations: variations),
                                                         editingPriceType: .regular,
                                                         priceUpdateDidFinish: {},
                                                         storesManager: storesManager)
        storesManager.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case let .updateProductVariations(_, _, _, onCompletion):
                onCompletion(.failure(.unexpected))
            default:
                XCTFail("Unsupported Action")
            }
        }
        let viewController = BulkUpdatePriceViewController(viewModel: viewModel, noticePresenter: noticePresenter)

        // When
        _ = try XCTUnwrap(viewController.view)
        viewModel.handlePriceChange("")
        viewModel.saveButtonTapped()

        waitUntil {
            noticePresenter.queuedNotices.count == 1
        }

        // Then
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        XCTAssertEqual(notice.feedbackType, .error)
    }

    func test_view_controller_displays_notice_on_selected_regular_price_is_less_than_sale_price_validation_error() throws {
        // Given
        let storesManager = MockStoresManager(sessionManager: SessionManager.makeForTesting())
        let noticePresenter = MockNoticePresenter()
        let variations = [MockProductVariation().productVariation().copy(dateOnSaleStart: Date(), dateOnSaleEnd: Date(), salePrice: "42")]
        let viewModel = BulkUpdatePriceSettingsViewModel(siteID: 0,
                                                         productID: 0,
                                                         bulkUpdateOptionsModel: BulkUpdateOptionsModel(productVariations: variations),
                                                         editingPriceType: .regular,
                                                         priceUpdateDidFinish: {},
                                                         storesManager: storesManager)
        storesManager.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case let .updateProductVariations(_, _, _, onCompletion):
                onCompletion(.failure(.unexpected))
            default:
                XCTFail("Unsupported Action")
            }
        }
        let viewController = BulkUpdatePriceViewController(viewModel: viewModel, noticePresenter: noticePresenter)

        // When
        _ = try XCTUnwrap(viewController.view)
        viewModel.handlePriceChange("9")
        viewModel.saveButtonTapped()

        waitUntil {
            noticePresenter.queuedNotices.count == 1
        }

        // Then
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        XCTAssertEqual(notice.feedbackType, .error)
    }
}
