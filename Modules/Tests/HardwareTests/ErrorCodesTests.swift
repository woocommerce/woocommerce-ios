import Testing
@testable import Hardware
import StripeTerminal

// We can not get errors directly from the Terminal SDK
// so all these test is that the mapping we do between Stripe's error codes
// and out own domain errors remains unchanged.
// Writing the tests has helped find a few cases missed
// The error codes are declared here:
// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html

@Suite("Card Reader Service Error Tests")
struct CardReaderServiceErrorTests {
    @Test func test_stripe_reader_busy_error_maps_to_expected_error() {
        #expect(.readerBusy == domainError(stripeCode: 3010))
    }

    @Test func test_stripe_not_connected_to_reader_maps_to_expected_error() {
        #expect(.notConnectedToReader == domainError(stripeCode: 1100))
    }

    @Test func test_stripe_already_connected_to_reader_maps_to_expected_error() {
        #expect(.alreadyConnectedToReader == domainError(stripeCode: 1110))
    }

    @Test func test_stripe_confirm_invalid_payment_intent_maps_to_expected_error() {
        #expect(.confirmInvalidPaymentIntent == domainError(stripeCode: 1530))
    }

    @Test func test_stripe_unsupported_sdk_maps_to_expected_error() {
        #expect(.unsupportedSDK == domainError(stripeCode: 1870))
    }

    @Test func test_stripe_feature_not_available_maps_to_expectd_error() {
        #expect(.featureNotAvailableWithConnectedReader == domainError(stripeCode: 1880))
    }

    @Test func test_stripe_cancelled_maps_to_expected_error() {
        #expect(.commandCancelled(from: .unknown) == domainError(stripeCode: 2020))
    }

    @Test func test_stripe_location_services_disabled_maps_to_expected_error() {
        #expect(.locationServicesDisabled == domainError(stripeCode: 2200))
    }

    @Test func test_stripe_bluetooth_disabled_maps_to_expected_error() {
        #expect(.bluetoothDisabled == domainError(stripeCode: 2320))
    }

    @Test func test_stripe_bluetooth_error_maps_to_expected_error() {
        #expect(.bluetoothError == domainError(stripeCode: 3200))
    }

    @Test func test_stripe_bluetooth_scan_timed_out_maps_to_expected_error() {
        #expect(.bluetoothScanTimedOut == domainError(stripeCode: 2330))
    }

    @Test func test_stripe_bluetooth_low_energy_unsupprted_maps_to_expected_error() {
        #expect(.bluetoothLowEnergyUnsupported == domainError(stripeCode: 2340))
    }

    @Test func test_stripe_software_update_failed_low_battery_maps_to_expected_error() {
        #expect(.readerSoftwareUpdateFailedBatteryLow == domainError(stripeCode: 2650))
    }

    @Test func test_stripe_software_update_failed_interrupted_maps_to_expected_error() {
        #expect(.readerSoftwareUpdateFailedInterrupted == domainError(stripeCode: 2660))
    }

    @Test func test_stripe_unable_to_connect_to_reader_the_reader_has_a_critically_low_battery() {
        #expect(.bluetoothConnectionFailedBatteryCriticallyLow == domainError(stripeCode: 2680))
    }

    @Test func test_stripe_software_update_failed_maps_to_expected_error() {
        #expect(.readerSoftwareUpdateFailed == domainError(stripeCode: 3800))
    }

    @Test func test_stripe_software_update_failed_on_reader_maps_to_expected_error() {
        #expect(.readerSoftwareUpdateFailedReader == domainError(stripeCode: 3830))
    }

    @Test func test_stripe_software_update_failed_on_server_maps_to_expected_error() {
        #expect(.readerSoftwareUpdateFailedServer == domainError(stripeCode: 3840))
    }

    @Test func test_stripe_card_insert_not_read_server_maps_to_expected_error() {
        #expect(.cardInsertNotRead == domainError(stripeCode: 2810))
    }

    @Test func test_stripe_card_swipe_not_read_server_maps_to_expected_error() {
        #expect(.cardSwipeNotRead == domainError(stripeCode: 2820))
    }

    @Test func test_stripe_card_read_timeout_server_maps_to_expected_error() {
        #expect(.cardReadTimeOut == domainError(stripeCode: 2830))
    }

    @Test func test_stripe_card_removed_server_maps_to_expected_error() {
        #expect(.cardRemoved == domainError(stripeCode: 2840))
    }

    @Test func test_stripe_card_left_in_reader_maps_to_expected_error() {
        #expect(.cardLeftInReader == domainError(stripeCode: 2850))
    }

    @Test func test_stripe_reader_busy_maps_to_expected_error() {
        #expect(.readerBusy == domainError(stripeCode: 3010))
    }

    @Test func test_stripe_reader_incompatible_maps_to_expected_error() {
        #expect(.readerIncompatible == domainError(stripeCode: 3030))
    }

    @Test func test_stripe_reader_communication_error_maps_to_expected_error() {
        #expect(.readerCommunicationError == domainError(stripeCode: 3060))
    }

    @Test func test_stripe_bluetooth_connect_timed_out_maps_to_expected_error() {
        #expect(.bluetoothConnectTimedOut == domainError(stripeCode: 3210))
    }

    @Test func test_stripe_bluetooth_disconnected_maps_to_expected_error() {
        #expect(.bluetoothDisconnected == domainError(stripeCode: 3230))
    }

    @Test func test_stripe_unsupported_reader_version_maps_to_expected_error() {
        #expect(.unsupportedReaderVersion == domainError(stripeCode: 3850))
    }

    @Test func test_stripe_connect_failed_reader_in_use_maps_to_expected_error() {
        #expect(.connectFailedReaderIsInUse == domainError(stripeCode: 3880))
    }

    @Test func test_stripe_unexpected_error_maps_to_expected_error() {
        #expect(.unexpectedSDKError == domainError(stripeCode: 5000))
    }

    @Test func test_stripe_payment_declined_by_processor_api_maps_to_expected_error() {
        #expect(.paymentDeclinedByPaymentProcessorAPI(declineReason: .unknown) == domainError(stripeCode: 6000))
    }

    @Test func test_stripe_payment_declined_by_card_reader_maps_to_expected_error() {
        #expect(.paymentDeclinedByCardReader == domainError(stripeCode: 6500))
    }

    @Test func test_stripe_not_connected_to_internet_maps_to_expected_error() {
        #expect(.notConnectedToInternet == domainError(stripeCode: 9000))
    }

    @Test func test_stripe_request_timed_out_maps_to_expected_error() {
        #expect(.requestTimedOut == domainError(stripeCode: 9010))
    }

    @Test func test_stripe_reader_session_expired_maps_to_expected_error() {
        #expect(.readerSessionExpired == domainError(stripeCode: 9060))
    }

    @Test func test_stripe_error_api_maps_to_stripeAPI() {
        #expect(.processorAPIError == domainError(stripeCode: 9020))
    }

    @Test func test_stripe_passcode_not_enabled_maps_to_expected_error() {
        #expect(.passcodeNotEnabled == domainError(stripeCode: 2920))
    }

    @Test func test_stripe_TOS_requires_iCloud_signin_maps_to_expected_error() {
        #expect(.tapToPayReaderTOSAcceptanceRequiresiCloudSignIn == domainError(stripeCode: 2960))
    }

    @Test func test_stripe_nfc_disabled_maps_to_expected_error() {
        #expect(.nfcDisabled == domainError(stripeCode: 3100))
    }

    @Test func test_stripe_built_in_reader_failed_to_prepare_maps_to_expected_error() {
        #expect(.tapToPayReaderFailedToPrepare == domainError(stripeCode: 3910))
    }

    @Test func test_stripe_TOS_acceptance_cancelled_maps_to_expected_error() {
        #expect(.tapToPayReaderTOSAcceptanceCanceled == domainError(stripeCode: 2970))
    }

    @Test func test_stripe_TOS_not_yet_accepted_maps_to_expected_error() {
        #expect(.tapToPayReaderTOSNotYetAccepted == domainError(stripeCode: 3930))
    }

    @Test func test_stripe_TOS_acceptance_failed_maps_to_expected_error() {
        #expect(.tapToPayReaderTOSAcceptanceFailed == domainError(stripeCode: 3940))
    }

    @Test func test_stripe_merchant_blocked_maps_to_expected_error() {
        #expect(.tapToPayReaderMerchantBlocked == domainError(stripeCode: 3950))
    }

    @Test func test_stripe_invalid_merchant_maps_to_expected_error() {
        #expect(.tapToPayReaderInvalidMerchant == domainError(stripeCode: 3960))
    }

    @Test func test_stripe_device_banned_maps_to_expected_error() {
        #expect(.tapToPayReaderDeviceBanned == domainError(stripeCode: 3920))
    }

    @Test func test_stripe_unsupported_mobile_device_maps_to_expected_error() {
        #expect(.unsupportedMobileDeviceConfiguration == domainError(stripeCode: 2910))
    }

    @Test func test_stripe_not_accessible_in_background_maps_to_expected_error() {
        #expect(.readerNotAccessibleInBackground == domainError(stripeCode: 3900))
    }

    @Test func test_stripe_command_not_allowed_during_call_maps_to_expected_error() {
        #expect(.commandNotAllowedDuringCall == domainError(stripeCode: 2930))
    }

    @Test func test_stripe_invalid_amount_maps_to_expected_error() {
        #expect(.invalidAmount == domainError(stripeCode: 2940))
    }

    @Test func test_stripe_invalid_currency_maps_to_expected_error() {
        #expect(.invalidCurrency == domainError(stripeCode: 2950))
    }

    @Test func test_stripe_cancel_failed_already_completed_maps_to_expected_error() {
        #expect(.cancelFailedAlreadyCompleted == domainError(stripeCode: 1010))
    }

    @Test func test_stripe_nil_payment_intent_maps_to_expected_error() {
        #expect(.nilPaymentIntent == domainError(stripeCode: 1540))
    }

    @Test func test_stripe_nil_setup_intent_maps_to_expected_error() {
        #expect(.nilSetupIntent == domainError(stripeCode: 1542))
    }

    @Test func test_stripe_nil_refund_payment_method_maps_to_expected_error() {
        #expect(.nilRefundPaymentMethod == domainError(stripeCode: 1550))
    }

    @Test func test_stripe_invalid_refund_parameters_maps_to_expected_error() {
        #expect(.invalidRefundParameters == domainError(stripeCode: 1555))
    }

    @Test func test_stripe_invalid_client_secret_maps_to_expected_error() {
        #expect(.invalidClientSecret == domainError(stripeCode: 1560))
    }

    @Test func test_stripe_invalid_discovery_configuration_maps_to_expected_error() {
        #expect(.invalidDiscoveryConfiguration == domainError(stripeCode: 1590))
    }

    @Test func test_stripe_invalid_reader_for_update_maps_to_expected_error() {
        #expect(.invalidReaderForUpdate == domainError(stripeCode: 1861))
    }

    @Test func test_stripe_feature_not_available_maps_to_expected_error() {
        #expect(.featureNotAvailable == domainError(stripeCode: 1890))
    }

    @Test func test_stripe_bluetooth_connection_invalid_location_id_parameter_maps_to_expected_error() {
        #expect(.bluetoothConnectionInvalidLocationIdParameter == domainError(stripeCode: 1910))
    }

    @Test func test_stripe_invalid_required_parameter_maps_to_expected_error() {
        #expect(.invalidRequiredParameter == domainError(stripeCode: 1920))
    }

    @Test func test_stripe_forwarding_test_mode_payment_in_live_mode_maps_to_expected_error() {
        #expect(.forwardingTestModePaymentInLiveMode == domainError(stripeCode: 1937))
    }

    @Test func test_stripe_forwarding_live_mode_payment_in_test_mode_maps_to_expected_error() {
        #expect(.forwardingLiveModePaymentInTestMode == domainError(stripeCode: 1938))
    }

    @Test func test_stripe_reader_connection_configuration_invalid_maps_to_expected_error() {
        #expect(.readerConnectionConfigurationInvalid == domainError(stripeCode: 1940))
    }

    @Test func test_stripe_reader_tipping_parameter_invalid_maps_to_expected_error() {
        #expect(.readerTippingParameterInvalid == domainError(stripeCode: 1950))
    }

    @Test func test_stripe_invalid_location_id_parameter_maps_to_expected_error() {
        #expect(.invalidLocationIdParameter == domainError(stripeCode: 1960))
    }

    @Test func test_stripe_reader_software_update_failed_expired_update_maps_to_expected_error() {
        #expect(.readerSoftwareUpdateFailedExpiredUpdate == domainError(stripeCode: 2670))
    }

    @Test func test_stripe_missing_emv_data_maps_to_expected_error() {
        #expect(.missingEMVData == domainError(stripeCode: 2892))
    }

    @Test func test_stripe_command_not_allowed_maps_to_expected_error() {
        #expect(.commandNotAllowed == domainError(stripeCode: 2900))
    }

    @Test func test_stripe_bluetooth_peer_removed_pairing_information_maps_to_expected_error() {
        #expect(.bluetoothPeerRemovedPairingInformation == domainError(stripeCode: 3240))
    }

    @Test func test_stripe_bluetooth_already_paired_with_another_device_maps_to_expected_error() {
        #expect(.bluetoothAlreadyPairedWithAnotherDevice == domainError(stripeCode: 3241))
    }

    @Test func test_stripe_unknown_reader_ip_address_maps_to_expected_error() {
        #expect(.unknownReaderIpAddress == domainError(stripeCode: 3860))
    }

    @Test func test_stripe_internet_connect_time_out_maps_to_expected_error() {
        #expect(.internetConnectTimeOut == domainError(stripeCode: 3870))
    }

    @Test func test_stripe_bluetooth_reconnect_started_maps_to_expected_error() {
        #expect(.bluetoothReconnectStarted == domainError(stripeCode: 3890))
    }

    @Test func test_stripe_apple_built_in_reader_account_deactivated_maps_to_expected_error() {
        #expect(.tapToPayReaderAccountDeactivated == domainError(stripeCode: 3970))
    }

    @Test func test_stripe_reader_missing_encryption_keys_maps_to_expected_error() {
        #expect(.readerMissingEncryptionKeys == domainError(stripeCode: 3980))
    }

    @Test func test_stripe_unexpected_reader_error_maps_to_expected_error() {
        #expect(.unexpectedReaderError == domainError(stripeCode: 5001))
    }

    @Test func test_stripe_command_requires_cardholder_consent_maps_to_expected_error() {
        #expect(.commandRequiresCardholderConsent == domainError(stripeCode: 6700))
    }

    @Test func test_stripe_refund_failed_maps_to_expected_error() {
        #expect(.refundFailed == domainError(stripeCode: 6800))
    }

    @Test func test_stripe_card_swipe_not_available_maps_to_expected_error() {
        #expect(.cardSwipeNotAvailable == domainError(stripeCode: 6900))
    }

    @Test func test_stripe_interac_not_supported_offline_maps_to_expected_error() {
        #expect(.interacNotSupportedOffline == domainError(stripeCode: 6901))
    }

    @Test func test_stripe_offline_and_card_expired_maps_to_expected_error() {
        #expect(.offlineAndCardExpired == domainError(stripeCode: 6902))
    }

    @Test func test_stripe_offline_transaction_declined_maps_to_expected_error() {
        #expect(.offlineTransactionDeclined == domainError(stripeCode: 6903))
    }

    @Test func test_stripe_offline_collect_and_confirm_mismatch_maps_to_expected_error() {
        #expect(.offlineCollectAndConfirmMismatch == domainError(stripeCode: 6904))
    }

    @Test func test_stripe_online_pin_not_supported_offline_maps_to_expected_error() {
        #expect(.onlinePinNotSupportedOffline == domainError(stripeCode: 6905))
    }

    @Test func test_stripe_offline_test_card_in_livemode_maps_to_expected_error() {
        #expect(.offlineTestCardInLivemode == domainError(stripeCode: 6906))
    }

    @Test func test_stripe_api_response_decoding_error_maps_to_expected_error() {
        #expect(.stripeAPIResponseDecodingError == domainError(stripeCode: 9030))
    }

    @Test func test_stripe_internal_network_error_maps_to_expected_error() {
        #expect(.internalNetworkError == domainError(stripeCode: 9040))
    }

    @Test func test_stripe_connection_token_provider_completed_with_error_maps_to_expected_error() {
        #expect(.connectionTokenProviderCompletedWithError == domainError(stripeCode: 9050))
    }

    @Test func test_stripe_connection_token_provider_timed_out_maps_to_expected_error() {
        #expect(.connectionTokenProviderTimedOut == domainError(stripeCode: 9052))
    }

    @Test func test_stripe_catch_all_error() {
        // Any error code not mapped to an specific error will be
        // mapped to `internalServiceError`
        #expect(.internalServiceError == domainError(stripeCode: Int.max))
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
