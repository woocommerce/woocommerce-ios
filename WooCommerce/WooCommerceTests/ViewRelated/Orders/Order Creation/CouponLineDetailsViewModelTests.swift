import XCTest

import WooFoundation
@testable import WooCommerce
@testable import struct Yosemite.OrderCouponLine
@testable import enum Yosemite.CouponAction

final class CouponLineDetailsViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 120934
    private var stores: MockStoresManager!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
    }

    override func tearDown() {
        super.tearDown()
        stores = nil
    }

    func test_view_model_disables_done_button_for_empty_state_and_enables_with_input() {
        // Given
        let viewModel = CouponLineDetailsViewModel(isExistingCouponLine: false,
                                                   code: "",
                                                   siteID: sampleSiteID,
                                                   didSelectSave: { _ in })
        XCTAssertTrue(viewModel.shouldDisableDoneButton)

        // When
        viewModel.code = "COUPON"

        // Then
        XCTAssertFalse(viewModel.shouldDisableDoneButton)

        // When
        viewModel.code = ""

        // Then
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }

    func test_view_model_disables_done_button_for_prefilled_data_and_enables_with_changes() {
        // Given
        let viewModel = CouponLineDetailsViewModel(isExistingCouponLine: false,
                                                   code: "COUPON",
                                                   siteID: sampleSiteID,
                                                   didSelectSave: { _ in })
        XCTAssertTrue(viewModel.shouldDisableDoneButton)

        // When
        viewModel.code = "COUPON1"

        // Then
        XCTAssertFalse(viewModel.shouldDisableDoneButton)

        // When
        viewModel.code = "COUPON"

        // Then
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }


    func test_view_model_creates_coupon_line_with_data_from_fields() {
        // Given
        var savedCouponLine: OrderCouponLine?
        let viewModel = CouponLineDetailsViewModel(isExistingCouponLine: false,
                                                   code: "COUPON",
                                                   siteID: sampleSiteID,
                                                   didSelectSave: { newCouponLine in
            savedCouponLine = newCouponLine
        })

        // When
        viewModel.code = "COUPON"
        viewModel.saveData()

        // Then
        XCTAssertEqual(savedCouponLine?.code, "COUPON")
    }

    func test_view_model_initializes_correctly_with_no_existing_coupon_line() {
        // Given
        let viewModel = CouponLineDetailsViewModel(isExistingCouponLine: false,
                                                   code: "",
                                                   siteID: sampleSiteID,
                                                   didSelectSave: { _ in })

        // Then
        XCTAssertFalse(viewModel.isExistingCouponLine)
    }

    func test_validateAndSaveData_then_calls_action_with_right_parameters() {
        // Given
        let passedCouponCode = "COUPON_CODE"

        let viewModel = CouponLineDetailsViewModel(isExistingCouponLine: false,
                                                   code: passedCouponCode,
                                                   siteID: sampleSiteID,
                                                   stores: stores,
                                                   didSelectSave: { _ in })

        viewModel.validateAndSaveData() { _ in }

        let parameters: (String, Int64) = waitFor { promise in
            self.stores.whenReceivingAction(ofType: CouponAction.self) { action in
                switch action {
                case let .validateCouponCode(code, siteID, _):
                    promise((code, siteID))
                default:
                    break
                }
            }
        }

        // Then
        XCTAssertEqual(parameters.0, passedCouponCode.lowercased())
        XCTAssertEqual(parameters.1, sampleSiteID)
    }

    func test_validateAndSaveData_when_coupon_is_validated_then_completes_successfully() {
        // Given
        let viewModel = CouponLineDetailsViewModel(isExistingCouponLine: false,
                                                   code: "",
                                                   siteID: sampleSiteID,
                                                   stores: stores,
                                                   didSelectSave: { _ in })

        stores.whenReceivingAction(ofType: CouponAction.self) { action in
            switch action {
            case let .validateCouponCode(_, _, onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }

        // When
        let result = waitFor { promise in
            viewModel.validateAndSaveData() { shouldDismiss in
                promise(shouldDismiss)
            }
        }

        // Then
        XCTAssertTrue(result)
    }

    func test_validateAndSaveData_when_coupon_is_not_validated_then_fails() {
        // Given
        let viewModel = CouponLineDetailsViewModel(isExistingCouponLine: false,
                                                   code: "",
                                                   siteID: sampleSiteID,
                                                   stores: stores,
                                                   didSelectSave: { _ in })

        stores.whenReceivingAction(ofType: CouponAction.self) { action in
            switch action {
            case let .validateCouponCode(_, _, onCompletion):
                let error = NSError(domain: "Test", code: 503, userInfo: nil)
                onCompletion(.failure(error))
            default:
                break
            }
        }

        // When
        let result = waitFor { promise in
            viewModel.validateAndSaveData() { shouldDismiss in
                promise(shouldDismiss)
            }
        }

        // Then
        XCTAssertFalse(result)
    }
}
