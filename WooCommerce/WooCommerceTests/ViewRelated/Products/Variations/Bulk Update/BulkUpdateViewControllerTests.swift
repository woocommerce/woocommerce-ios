import Foundation
import XCTest
import Yosemite
@testable import Storage

@testable import WooCommerce

/// Tests for `BulkUpdateViewController`.
///
final class BulkUpdateViewControllerTests: XCTestCase {

    func test_view_controller_displays_notice_on_sync_error() throws {
        // Given
        let storageManager =  MockStorageManager()
        let storesManager = MockStoresManager(sessionManager: SessionManager.makeForTesting())
        let noticePresenter = MockNoticePresenter()
        let viewModel = BulkUpdateViewModel(siteID: 0, productID: 0, onCancelButtonTapped: {}, storageManager: storageManager, storesManager: storesManager)
        storesManager.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case let .synchronizeProductVariations(_, _, _, _, onCompletion):
                onCompletion(NSError.init(domain: "sample error", code: 0, userInfo: nil))
            default:
                XCTFail("Unsupported Action")
            }
        }
        let viewController = BulkUpdateViewController(viewModel: viewModel, noticePresenter: noticePresenter)

        // When
        _ = try XCTUnwrap(viewController.view)

        waitUntil {
            noticePresenter.queuedNotices.count == 1
        }

        // Then
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        XCTAssertEqual(notice.feedbackType, .error)
    }
}
