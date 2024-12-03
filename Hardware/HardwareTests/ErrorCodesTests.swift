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
    func test_stripe_reader_busy_error_maps_to_expected_error() {
        XCTAssertEqual(.readerBusy, domainError(stripeCode: 3010))
    }

    func test_stripe_not_connected_to_reader_maps_to_expected_error() {
        XCTAssertEqual(.notConnectedToReader, domainError(stripeCode: 1100))
    }

    func test_stripe_already_connected_to_reader_maps_to_expected_error() {
        XCTAssertEqual(.alreadyConnectedToReader, domainError(stripeCode: 1110))
    }

    func test_stripe_confirm_invalid_payment_intent_maps_to_expected_error() {
        XCTAssertEqual(.confirmInvalidPaymentIntent, domainError(stripeCode: 1530))
    }

    func test_stripe_unsupported_sdk_maps_to_expected_error() {
        XCTAssertEqual(.unsupportedSDK, domainError(stripeCode: 1870))
    }

    func test_stripe_feature_not_available_maps_to_expectd_error() {
        XCTAssertEqual(.featureNotAvailableWithConnectedReader, domainError(stripeCode: 1880))
    }

    func test_stripe_cancelled_maps_to_expected_error() {
        XCTAssertEqual(.commandCancelled(from: .unknown), domainError(stripeCode: 2020))
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

    func test_stripe_unable_to_connect_to_reader_the_reader_has_a_critically_low_battery() {
        XCTAssertEqual(.bluetoothConnectionFailedBatteryCriticallyLow, domainError(stripeCode: 2680))
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

    func test_stripe_passcode_not_enabled_maps_to_expected_error() {
        XCTAssertEqual(.passcodeNotEnabled, domainError(stripeCode: 2920))
    }

    func test_stripe_TOS_requires_iCloud_signin_maps_to_expected_error() {
        XCTAssertEqual(.appleBuiltInReaderTOSAcceptanceRequiresiCloudSignIn, domainError(stripeCode: 2960))
    }

    func test_stripe_nfc_disabled_maps_to_expected_error() {
        XCTAssertEqual(.nfcDisabled, domainError(stripeCode: 3100))
    }

    func test_stripe_built_in_reader_failed_to_prepare_maps_to_expected_error() {
        XCTAssertEqual(.appleBuiltInReaderFailedToPrepare, domainError(stripeCode: 3910))
    }

    func test_stripe_TOS_acceptance_cancelled_maps_to_expected_error() {
        XCTAssertEqual(.appleBuiltInReaderTOSAcceptanceCanceled, domainError(stripeCode: 2970))
    }

    func test_stripe_TOS_not_yet_accepted_maps_to_expected_error() {
        XCTAssertEqual(.appleBuiltInReaderTOSNotYetAccepted, domainError(stripeCode: 3930))
    }

    func test_stripe_TOS_acceptance_failed_maps_to_expected_error() {
        XCTAssertEqual(.appleBuiltInReaderTOSAcceptanceFailed, domainError(stripeCode: 3940))
    }

    func test_stripe_merchant_blocked_maps_to_expected_error() {
        XCTAssertEqual(.appleBuiltInReaderMerchantBlocked, domainError(stripeCode: 3950))
    }

    func test_stripe_invalid_merchant_maps_to_expected_error() {
        XCTAssertEqual(.appleBuiltInReaderInvalidMerchant, domainError(stripeCode: 3960))
    }

    func test_stripe_device_banned_maps_to_expected_error() {
        XCTAssertEqual(.appleBuiltInReaderDeviceBanned, domainError(stripeCode: 3920))
    }

    func test_stripe_unsupported_mobile_device_maps_to_expected_error() {
        XCTAssertEqual(.unsupportedMobileDeviceConfiguration, domainError(stripeCode: 2910))
    }

    func test_stripe_not_accessible_in_background_maps_to_expected_error() {
        XCTAssertEqual(.readerNotAccessibleInBackground, domainError(stripeCode: 3900))
    }

    func test_stripe_command_not_allowed_during_call_maps_to_expected_error() {
        XCTAssertEqual(.commandNotAllowedDuringCall, domainError(stripeCode: 2930))
    }

    func test_stripe_invalid_amount_maps_to_expected_error() {
        XCTAssertEqual(.invalidAmount, domainError(stripeCode: 2940))
    }

    func test_stripe_invalid_currency_maps_to_expected_error() {
        XCTAssertEqual(.invalidCurrency, domainError(stripeCode: 2950))
    }

    func test_stripe_cancel_failed_already_completed_maps_to_expected_error() {
        XCTAssertEqual(.cancelFailedAlreadyCompleted, domainError(stripeCode: 1010))
    }

    func test_stripe_nil_payment_intent_maps_to_expected_error() {
        XCTAssertEqual(.nilPaymentIntent, domainError(stripeCode: 1540))
    }

    func test_stripe_nil_setup_intent_maps_to_expected_error() {
        XCTAssertEqual(.nilSetupIntent, domainError(stripeCode: 1542))
    }

    func test_stripe_nil_refund_payment_method_maps_to_expected_error() {
        XCTAssertEqual(.nilRefundPaymentMethod, domainError(stripeCode: 1550))
    }

    func test_stripe_invalid_refund_parameters_maps_to_expected_error() {
        XCTAssertEqual(.invalidRefundParameters, domainError(stripeCode: 1555))
    }

    func test_stripe_invalid_client_secret_maps_to_expected_error() {
        XCTAssertEqual(.invalidClientSecret, domainError(stripeCode: 1560))
    }

    func test_stripe_invalid_discovery_configuration_maps_to_expected_error() {
        XCTAssertEqual(.invalidDiscoveryConfiguration, domainError(stripeCode: 1590))
    }

    func test_stripe_invalid_reader_for_update_maps_to_expected_error() {
        XCTAssertEqual(.invalidReaderForUpdate, domainError(stripeCode: 1861))
    }

    func test_stripe_feature_not_available_maps_to_expected_error() {
        XCTAssertEqual(.featureNotAvailable, domainError(stripeCode: 1890))
    }

    func test_stripe_bluetooth_connection_invalid_location_id_parameter_maps_to_expected_error() {
        XCTAssertEqual(.bluetoothConnectionInvalidLocationIdParameter, domainError(stripeCode: 1910))
    }

    func test_stripe_invalid_required_parameter_maps_to_expected_error() {
        XCTAssertEqual(.invalidRequiredParameter, domainError(stripeCode: 1920))
    }

    func test_stripe_forwarding_test_mode_payment_in_live_mode_maps_to_expected_error() {
        XCTAssertEqual(.forwardingTestModePaymentInLiveMode, domainError(stripeCode: 1937))
    }

    func test_stripe_forwarding_live_mode_payment_in_test_mode_maps_to_expected_error() {
        XCTAssertEqual(.forwardingLiveModePaymentInTestMode, domainError(stripeCode: 1938))
    }

    func test_stripe_reader_connection_configuration_invalid_maps_to_expected_error() {
        XCTAssertEqual(.readerConnectionConfigurationInvalid, domainError(stripeCode: 1940))
    }

    func test_stripe_reader_tipping_parameter_invalid_maps_to_expected_error() {
        XCTAssertEqual(.readerTippingParameterInvalid, domainError(stripeCode: 1950))
    }

    func test_stripe_invalid_location_id_parameter_maps_to_expected_error() {
        XCTAssertEqual(.invalidLocationIdParameter, domainError(stripeCode: 1960))
    }

    func test_stripe_reader_software_update_failed_expired_update_maps_to_expected_error() {
        XCTAssertEqual(.readerSoftwareUpdateFailedExpiredUpdate, domainError(stripeCode: 2670))
    }

    func test_stripe_missing_emv_data_maps_to_expected_error() {
        XCTAssertEqual(.missingEMVData, domainError(stripeCode: 2892))
    }

    func test_stripe_command_not_allowed_maps_to_expected_error() {
        XCTAssertEqual(.commandNotAllowed, domainError(stripeCode: 2900))
    }

    func test_stripe_bluetooth_peer_removed_pairing_information_maps_to_expected_error() {
        XCTAssertEqual(.bluetoothPeerRemovedPairingInformation, domainError(stripeCode: 3240))
    }

    func test_stripe_bluetooth_already_paired_with_another_device_maps_to_expected_error() {
        XCTAssertEqual(.bluetoothAlreadyPairedWithAnotherDevice, domainError(stripeCode: 3241))
    }

    func test_stripe_unknown_reader_ip_address_maps_to_expected_error() {
        XCTAssertEqual(.unknownReaderIpAddress, domainError(stripeCode: 3860))
    }

    func test_stripe_internet_connect_time_out_maps_to_expected_error() {
        XCTAssertEqual(.internetConnectTimeOut, domainError(stripeCode: 3870))
    }

    func test_stripe_bluetooth_reconnect_started_maps_to_expected_error() {
        XCTAssertEqual(.bluetoothReconnectStarted, domainError(stripeCode: 3890))
    }

    func test_stripe_apple_built_in_reader_account_deactivated_maps_to_expected_error() {
        XCTAssertEqual(.appleBuiltInReaderAccountDeactivated, domainError(stripeCode: 3970))
    }

    func test_stripe_reader_missing_encryption_keys_maps_to_expected_error() {
        XCTAssertEqual(.readerMissingEncryptionKeys, domainError(stripeCode: 3980))
    }

    func test_stripe_unexpected_reader_error_maps_to_expected_error() {
        XCTAssertEqual(.unexpectedReaderError, domainError(stripeCode: 5001))
    }

    func test_stripe_command_requires_cardholder_consent_maps_to_expected_error() {
        XCTAssertEqual(.commandRequiresCardholderConsent, domainError(stripeCode: 6700))
    }

    func test_stripe_refund_failed_maps_to_expected_error() {
        XCTAssertEqual(.refundFailed, domainError(stripeCode: 6800))
    }

    func test_stripe_card_swipe_not_available_maps_to_expected_error() {
        XCTAssertEqual(.cardSwipeNotAvailable, domainError(stripeCode: 6900))
    }

    func test_stripe_interac_not_supported_offline_maps_to_expected_error() {
        XCTAssertEqual(.interacNotSupportedOffline, domainError(stripeCode: 6901))
    }

    func test_stripe_offline_and_card_expired_maps_to_expected_error() {
        XCTAssertEqual(.offlineAndCardExpired, domainError(stripeCode: 6902))
    }

    func test_stripe_offline_transaction_declined_maps_to_expected_error() {
        XCTAssertEqual(.offlineTransactionDeclined, domainError(stripeCode: 6903))
    }

    func test_stripe_offline_collect_and_confirm_mismatch_maps_to_expected_error() {
        XCTAssertEqual(.offlineCollectAndConfirmMismatch, domainError(stripeCode: 6904))
    }

    func test_stripe_online_pin_not_supported_offline_maps_to_expected_error() {
        XCTAssertEqual(.onlinePinNotSupportedOffline, domainError(stripeCode: 6905))
    }

    func test_stripe_offline_test_card_in_livemode_maps_to_expected_error() {
        XCTAssertEqual(.offlineTestCardInLivemode, domainError(stripeCode: 6906))
    }

    func test_stripe_api_response_decoding_error_maps_to_expected_error() {
        XCTAssertEqual(.stripeAPIResponseDecodingError, domainError(stripeCode: 9030))
    }

    func test_stripe_internal_network_error_maps_to_expected_error() {
        XCTAssertEqual(.internalNetworkError, domainError(stripeCode: 9040))
    }

    func test_stripe_connection_token_provider_completed_with_error_maps_to_expected_error() {
        XCTAssertEqual(.connectionTokenProviderCompletedWithError, domainError(stripeCode: 9050))
    }

    func test_stripe_connection_token_provider_timed_out_maps_to_expected_error() {
        XCTAssertEqual(.connectionTokenProviderTimedOut, domainError(stripeCode: 9052))
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
