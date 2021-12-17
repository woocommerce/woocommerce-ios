import XCTest
@testable import Hardware
import StripeTerminal

// We can not get errors directly from the Terminal SDK
// so all these test is that the mapping we do between Stripe's error codes
// and out own domain errors remains unchanged.
// Writing the tests has helped find a few cases missed
// The error codes are declared here:
// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html

final class CardReaderServiceErrorTests: XCTestCase {
    func test_stripe_error_busy_maps_to_busy() {
        XCTAssertEqual(.busy, domainError(stripeCode: 1000))
    }

    func test_stripe_not_connected_to_reader_maps_to_expected_error() {
        XCTAssertEqual(.notConnectedToReader, domainError(stripeCode: 1100))
    }

    func test_stripe_already_connected_to_reader_maps_to_expected_error() {
        XCTAssertEqual(.alreadyConnectedToReader, domainError(stripeCode: 1110))
    }

    func test_stripe_process_invalid_payment_intent_maps_to_expected_error() {
        XCTAssertEqual(.processInvalidPaymentIntent, domainError(stripeCode: 1530))
    }

    func test_stripe_cant_connect_to_undiscovered_reader_maps_to_expected_error() {
        XCTAssertEqual(.connectingToUndiscoveredReader, domainError(stripeCode: 1580))
    }

    func test_stripe_unsupported_sdk_maps_to_expected_error() {
        XCTAssertEqual(.unsupportedSDK, domainError(stripeCode: 1870))
    }

    func test_stripe_feature_not_available_maps_to_expectd_error() {
        XCTAssertEqual(.featureNotAvailableWithConnectedReader, domainError(stripeCode: 1880))
    }

    func test_stripe_cancelled_maps_to_expected_error() {
        XCTAssertEqual(.commandCancelled, domainError(stripeCode: 2020))
    }

    func test_stripe_location_services_disabled_maps_to_expected_error() {
        XCTAssertEqual(.locationServicesDisabled, domainError(stripeCode: 2200))
    }

    func test_stripe_bluetooth_disabled_maps_to_expected_error() {
        XCTAssertEqual(.bluetoothDisabled, domainError(stripeCode: 2320))
    }

    func test_stripe_bluetooth_error_maps_to_expected_error() {
        XCTAssertEqual(.bluetoothError, domainError(stripeCode: 3200))
    }

    func test_stripe_bluetooth_scan_timed_out_maps_to_expected_error() {
        XCTAssertEqual(.bluetoothScanTimedOut, domainError(stripeCode: 2330))
    }

    func test_stripe_bluetooth_low_energy_unsupprted_maps_to_expected_error() {
        XCTAssertEqual(.bluetoothLowEnergyUnsupported, domainError(stripeCode: 2340))
    }

    func test_stripe_software_update_failed_low_battery_maps_to_expected_error() {
        XCTAssertEqual(.readerSoftwareUpdateFailedBatteryLow, domainError(stripeCode: 2650))
    }

    func test_stripe_software_update_failed_interrupted_maps_to_expected_error() {
        XCTAssertEqual(.readerSoftwareUpdateFailedInterrupted, domainError(stripeCode: 2660))
    }

    func test_stripe_software_update_failed_maps_to_expected_error() {
        XCTAssertEqual(.readerSoftwareUpdateFailed, domainError(stripeCode: 3800))
    }

    func test_stripe_software_update_failed_on_reader_maps_to_expected_error() {
        XCTAssertEqual(.readerSoftwareUpdateFailedReader, domainError(stripeCode: 3830))
    }

    func test_stripe_software_update_failed_on_server_maps_to_expected_error() {
        XCTAssertEqual(.readerSoftwareUpdateFailedServer, domainError(stripeCode: 3840))
    }

    func test_stripe_card_insert_not_read_server_maps_to_expected_error() {
        XCTAssertEqual(.cardInsertNotRead, domainError(stripeCode: 2810))
    }

    func test_stripe_card_swipe_not_read_server_maps_to_expected_error() {
        XCTAssertEqual(.cardSwipeNotRead, domainError(stripeCode: 2820))
    }

    func test_stripe_card_read_timeout_server_maps_to_expected_error() {
        XCTAssertEqual(.cardReadTimeOut, domainError(stripeCode: 2830))
    }

    func test_stripe_card_removed_server_maps_to_expected_error() {
        XCTAssertEqual(.cardRemoved, domainError(stripeCode: 2840))
    }

    func test_stripe_card_left_in_reader_maps_to_expected_error() {
        XCTAssertEqual(.cardLeftInReader, domainError(stripeCode: 2850))
    }

    func test_stripe_reader_busy_maps_to_expected_error() {
        XCTAssertEqual(.readerBusy, domainError(stripeCode: 3010))
    }

    func test_stripe_reader_incompatible_maps_to_expected_error() {
        XCTAssertEqual(.readerIncompatible, domainError(stripeCode: 3030))
    }

    func test_stripe_reader_communication_error_maps_to_expected_error() {
        XCTAssertEqual(.readerCommunicationError, domainError(stripeCode: 3060))
    }

    func test_stripe_bluetooth_connect_timed_out_maps_to_expected_error() {
        XCTAssertEqual(.bluetoothConnectTimedOut, domainError(stripeCode: 3210))
    }

    func test_stripe_bluetooth_disconnected_maps_to_expected_error() {
        XCTAssertEqual(.bluetoothDisconnected, domainError(stripeCode: 3230))
    }

    func test_stripe_unsupported_reader_version_maps_to_expected_error() {
        XCTAssertEqual(.unsupportedReaderVersion, domainError(stripeCode: 3850))
    }

    func test_stripe_connect_failed_reader_in_use_maps_to_expected_error() {
        XCTAssertEqual(.connectFailedReaderIsInUse, domainError(stripeCode: 3880))
    }

    func test_stripe_unexpected_error_maps_to_expected_error() {
        XCTAssertEqual(.unexpectedSDKError, domainError(stripeCode: 5000))
    }

    func test_stripe_payment_declined_by_processor_api_maps_to_expected_error() {
        XCTAssertEqual(.paymentDeclinedByPaymentProcessorAPI(declineReason: .unknown), domainError(stripeCode: 6000))
    }

    func test_stripe_payment_declined_by_card_reader_maps_to_expected_error() {
        XCTAssertEqual(.paymentDeclinedByCardReader, domainError(stripeCode: 6500))
    }

    func test_stripe_not_connected_to_internet_maps_to_expected_error() {
        XCTAssertEqual(.notConnectedToInternet, domainError(stripeCode: 9000))
    }

    func test_stripe_request_timed_out_maps_to_expected_error() {
        XCTAssertEqual(.requestTimedOut, domainError(stripeCode: 9010))
    }

    func test_stripe_reader_session_expired_maps_to_expected_error() {
        XCTAssertEqual(.readerSessionExpired, domainError(stripeCode: 9060))
    }

    func test_stripe_error_api_maps_to_stripeAPI() {
        XCTAssertEqual(.processorAPIError, domainError(stripeCode: 9020))
    }

    func test_stripe_catch_all_error() {
        // Any error code not mapped to an specific error will be
        // mapped to `internalServiceError`
        XCTAssertEqual(.internalServiceError, domainError(stripeCode: Int.max))
    }
}

private extension CardReaderServiceErrorTests {
    /// Creates an instance of UnderlyingError from
    /// one of the error codes provided by the Stripe Terminal SDK
    /// - Parameter stripeCode: An error code as declared in https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html
    /// - Returns: The UnderlyingError
    func domainError(stripeCode: Int) -> UnderlyingError {
        let stripeSDKError = stripeError(code: stripeCode)

        return underlyingError(error: stripeSDKError)
    }

    func underlyingError(error: NSError) -> UnderlyingError {
        return UnderlyingError(with: error)
    }

    func stripeError(code: Int) -> NSError {
        // The domain is true to the errors returned by the Terminal SDK
        return NSError(domain: "com.stripe-terminal", code: code, userInfo: nil)
    }
}
