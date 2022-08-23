import XCTest
import TestKit

@testable import WooCommerce
import Yosemite
import Networking

final class InPersonPaymentsCashOnDeliveryPaymentGatewayNotSetUpViewModelTests: XCTestCase {

    private var stores: MockStoresManager!

    private var noticePresenter: MockNoticePresenter!

    private var sut: InPersonPaymentsCashOnDeliveryPaymentGatewayNotSetUpViewModel!

    override func setUp() {
        stores = MockStoresManager(sessionManager: .testingInstance)
        stores.sessionManager.setStoreId(12345)
        noticePresenter = MockNoticePresenter()
        sut = InPersonPaymentsCashOnDeliveryPaymentGatewayNotSetUpViewModel(stores: stores, noticePresenter: noticePresenter, completion: {})
    }

    func test_skip_always_calls_completion() {
        // Given
        let completionCalled: Bool = waitFor { promise in
            let sut = InPersonPaymentsCashOnDeliveryPaymentGatewayNotSetUpViewModel(stores: self.stores,
                                                                         noticePresenter: self.noticePresenter,
                                                                         completion: {
                promise(true)
            })

            // When
            sut.skipTapped()
        }

        // Then
        XCTAssert(completionCalled)
    }

    func test_skip_saves_skipped_preference_for_the_current_site() {
        // Given
        var spySavedOnboardingSkipForSiteID: Int64? = nil
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .setSkippedCashOnDeliveryOnboardingStep(siteID):
                spySavedOnboardingSkipForSiteID = siteID
            default:
                break
            }
        }

        // When
        sut.skipTapped()

        // Then
        XCTAssertNotNil(spySavedOnboardingSkipForSiteID)
        assertEqual(12345, spySavedOnboardingSkipForSiteID)
    }

    func test_enable_success_calls_completion() {
        // Given
        stores.whenReceivingAction(ofType: PaymentGatewayAction.self) { action in
            switch action {
            case let .updatePaymentGateway(paymentGateway, onCompletion):
                onCompletion(.success(paymentGateway))
            default:
                break
            }
        }

        let completionCalled: Bool = waitFor { promise in
            let sut = InPersonPaymentsCashOnDeliveryPaymentGatewayNotSetUpViewModel(stores: self.stores,
                                                                          noticePresenter: self.noticePresenter,
                                                                          completion: {
                promise(true)
            })
            // When
            sut.enableTapped()
        }

        // Then
        XCTAssert(completionCalled)
    }

    func test_enable_failure_displays_notice() throws {
        // Given
        stores.whenReceivingAction(ofType: PaymentGatewayAction.self) { action in
            switch action {
            case let .updatePaymentGateway(_, onCompletion):
                onCompletion(.failure(DotcomError.noRestRoute))
            default:
                break
            }
        }

        // When
        sut.enableTapped()

        // Then
        let notice = try XCTUnwrap(noticePresenter.queuedNotices.first)
        let expectedTitle = "Failed to enable Pay in Person. Please try again later."
        assertEqual(expectedTitle, notice.title)
    }

}
