import XCTest

import WooFoundation
@testable import WooCommerce
@testable import Yosemite

final class CouponLineDetailsViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 120934
    private let initialCode = "COUPON"
    private var stores: MockStoresManager!
    private var viewModel: CouponLineDetailsViewModel!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
        viewModel = CouponLineDetailsViewModel(code: initialCode,
                                               siteID: sampleSiteID,
                                               stores: stores,
                                               didSelectSave: { _ in })
    }

    override func tearDown() {
        super.tearDown()
        stores = nil
        viewModel = nil
    }

    func test_view_model_disables_done_button_for_empty_state_and_enables_with_input() {
        // Given
        XCTAssertTrue(viewModel.shouldDisableDoneButton)

        // When
        viewModel.code = "COUPON-1"

        // Then
        XCTAssertFalse(viewModel.shouldDisableDoneButton)

        // When
        viewModel.code = ""

        // Then
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }

    func test_view_model_disables_done_button_for_prefilled_data_and_enables_with_changes() {
        // Given
        XCTAssertTrue(viewModel.shouldDisableDoneButton)

        // When
        viewModel.code = "COUPON1"

        // Then
        XCTAssertFalse(viewModel.shouldDisableDoneButton)

        // When
        viewModel.code = initialCode

        // Then
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }

    func test_validateAndSaveData_then_calls_action_with_right_parameters() {
        // Given
        let passedCouponCode = "COUPON_CODE"
        viewModel.code = passedCouponCode

        var parameters: (String, Int64)?
        stores.whenReceivingAction(ofType: CouponAction.self) { action in
            switch action {
            case let .validateCouponCode(code, siteID, completion):
                parameters = (code, siteID)
                completion(.success(true))
            default:
                break
            }
        }

        waitFor { [weak self] promise in
            self?.viewModel.validateAndSaveData() { _ in
                promise(())
            }
        }

        // Then
        XCTAssertEqual(parameters?.0, passedCouponCode.lowercased())
        XCTAssertEqual(parameters?.1, sampleSiteID)
    }

    func test_validateAndSaveData_when_coupon_is_edited_and_validated_then_completes_successfully() {
        // Given
        var savedResult: CouponLineDetailsResult?
        viewModel.didSelectSave = { result in
            savedResult = result
        }

        let passedCouponCode = "COUPON"
        viewModel.code = passedCouponCode


        stores.whenReceivingAction(ofType: CouponAction.self) { action in
            switch action {
            case let .validateCouponCode(_, _, onCompletion):
                onCompletion(.success(true))
            default:
                break
            }
        }

        // When
        let shouldDismiss = waitFor { [weak self] promise in
            self?.viewModel.validateAndSaveData() { shouldDismiss in
                promise(shouldDismiss)
            }
        }

        // Then
        XCTAssertTrue(shouldDismiss)

        switch savedResult {
        case let .edited(oldCode, newCode):
            XCTAssertEqual(oldCode, initialCode)
            XCTAssertEqual(newCode, passedCouponCode)
        default:
            XCTFail("Result should be edited case")
        }
    }

    func test_validateAndSaveData_when_coupon_is_not_validated_then_fails() {
        // Given
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
        let result = waitFor { [weak self] promise in
            self?.viewModel.validateAndSaveData() { shouldDismiss in
                promise(shouldDismiss)
            }
        }

        // Then
        XCTAssertFalse(result)
    }
}
