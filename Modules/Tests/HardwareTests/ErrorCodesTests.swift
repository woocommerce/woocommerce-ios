import Testing
@testable import Hardware
import StripeTerminal

// We can not get errors directly from the Terminal SDK
// so all these test is that the mapping we do between Stripe's error codes
// and out own domain errors remains unchanged.
// Writing the tests has helped find a few cases missed
// The error codes are declared here:
// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html

struct `Card Reader Service Error Tests` {
    @Test func `stripe reader busy error maps to expected error`() {
        #expect(.readerBusy == domainError(stripeCode: 3010))
    }

    @Test func `stripe not connected to reader maps to expected error`() {
        #expect(.notConnectedToReader == domainError(stripeCode: 1100))
    }

    @Test func `stripe already connected to reader maps to expected error`() {
        #expect(.alreadyConnectedToReader == domainError(stripeCode: 1110))
    }

    @Test func `stripe confirm invalid payment intent maps to expected error`() {
        #expect(.confirmInvalidPaymentIntent == domainError(stripeCode: 1530))
    }

    @Test func `stripe unsupported sdk maps to expected error`() {
        #expect(.unsupportedSDK == domainError(stripeCode: 1870))
    }

    @Test func `stripe feature not available maps to expectd error`() {
        #expect(.featureNotAvailableWithConnectedReader == domainError(stripeCode: 1880))
    }

    @Test func `stripe cancelled maps to expected error`() {
        #expect(.commandCancelled(from: .unknown) == domainError(stripeCode: 2020))
    }

    @Test func `stripe location services disabled maps to expected error`() {
        #expect(.locationServicesDisabled == domainError(stripeCode: 2200))
    }

    @Test func `stripe bluetooth disabled maps to expected error`() {
        #expect(.bluetoothDisabled == domainError(stripeCode: 2320))
    }

    @Test func `stripe bluetooth error maps to expected error`() {
        #expect(.bluetoothError == domainError(stripeCode: 3200))
    }

    @Test func `stripe bluetooth scan timed out maps to expected error`() {
        #expect(.bluetoothScanTimedOut == domainError(stripeCode: 2330))
    }

    @Test func `stripe bluetooth low energy unsupprted maps to expected error`() {
        #expect(.bluetoothLowEnergyUnsupported == domainError(stripeCode: 2340))
    }

    @Test func `stripe software update failed low battery maps to expected error`() {
        #expect(.readerSoftwareUpdateFailedBatteryLow == domainError(stripeCode: 2650))
    }

    @Test func `stripe software update failed interrupted maps to expected error`() {
        #expect(.readerSoftwareUpdateFailedInterrupted == domainError(stripeCode: 2660))
    }

    @Test func `stripe unable to connect to reader the reader has a critically low battery`() {
        #expect(.bluetoothConnectionFailedBatteryCriticallyLow == domainError(stripeCode: 2680))
    }

    @Test func `stripe software update failed maps to expected error`() {
        #expect(.readerSoftwareUpdateFailed == domainError(stripeCode: 3800))
    }

    @Test func `stripe software update failed on reader maps to expected error`() {
        #expect(.readerSoftwareUpdateFailedReader == domainError(stripeCode: 3830))
    }

    @Test func `stripe software update failed on server maps to expected error`() {
        #expect(.readerSoftwareUpdateFailedServer == domainError(stripeCode: 3840))
    }

    @Test func `stripe card insert not read server maps to expected error`() {
        #expect(.cardInsertNotRead == domainError(stripeCode: 2810))
    }

    @Test func `stripe card swipe not read server maps to expected error`() {
        #expect(.cardSwipeNotRead == domainError(stripeCode: 2820))
    }

    @Test func `stripe card read timeout server maps to expected error`() {
        #expect(.cardReadTimeOut == domainError(stripeCode: 2830))
    }

    @Test func `stripe card removed server maps to expected error`() {
        #expect(.cardRemoved == domainError(stripeCode: 2840))
    }

    @Test func `stripe card left in reader maps to expected error`() {
        #expect(.cardLeftInReader == domainError(stripeCode: 2850))
    }

    @Test func `stripe reader busy maps to expected error`() {
        #expect(.readerBusy == domainError(stripeCode: 3010))
    }

    @Test func `stripe reader incompatible maps to expected error`() {
        #expect(.readerIncompatible == domainError(stripeCode: 3030))
    }

    @Test func `stripe reader communication error maps to expected error`() {
        #expect(.readerCommunicationError == domainError(stripeCode: 3060))
    }

    @Test func `stripe bluetooth connect timed out maps to expected error`() {
        #expect(.bluetoothConnectTimedOut == domainError(stripeCode: 3210))
    }

    @Test func `stripe bluetooth disconnected maps to expected error`() {
        #expect(.bluetoothDisconnected == domainError(stripeCode: 3230))
    }

    @Test func `stripe unsupported reader version maps to expected error`() {
        #expect(.unsupportedReaderVersion == domainError(stripeCode: 3850))
    }

    @Test func `stripe connect failed reader in use maps to expected error`() {
        #expect(.connectFailedReaderIsInUse == domainError(stripeCode: 3880))
    }

    @Test func `stripe unexpected error maps to expected error`() {
        #expect(.unexpectedSDKError == domainError(stripeCode: 5000))
    }

    @Test func `stripe payment declined by processor api maps to expected error`() {
        #expect(.paymentDeclinedByPaymentProcessorAPI(declineReason: .unknown) == domainError(stripeCode: 6000))
    }

    @Test func `stripe payment declined by card reader maps to expected error`() {
        #expect(.paymentDeclinedByCardReader == domainError(stripeCode: 6500))
    }

    @Test func `stripe not connected to internet maps to expected error`() {
        #expect(.notConnectedToInternet == domainError(stripeCode: 9000))
    }

    @Test func `stripe request timed out maps to expected error`() {
        #expect(.requestTimedOut == domainError(stripeCode: 9010))
    }

    @Test func `stripe reader session expired maps to expected error`() {
        #expect(.readerSessionExpired == domainError(stripeCode: 9060))
    }

    @Test func `stripe error api maps to stripeAPI`() {
        #expect(.processorAPIError == domainError(stripeCode: 9020))
    }

    @Test func `stripe passcode not enabled maps to expected error`() {
        #expect(.passcodeNotEnabled == domainError(stripeCode: 2920))
    }

    @Test func `stripe TOS requires iCloud signin maps to expected error`() {
        #expect(.tapToPayReaderTOSAcceptanceRequiresiCloudSignIn == domainError(stripeCode: 2960))
    }

    @Test func `stripe nfc disabled maps to expected error`() {
        #expect(.nfcDisabled == domainError(stripeCode: 3100))
    }

    @Test func `stripe built in reader failed to prepare maps to expected error`() {
        #expect(.tapToPayReaderFailedToPrepare == domainError(stripeCode: 3910))
    }

    @Test func `stripe TOS acceptance cancelled maps to expected error`() {
        #expect(.tapToPayReaderTOSAcceptanceCanceled == domainError(stripeCode: 2970))
    }

    @Test func `stripe TOS not yet accepted maps to expected error`() {
        #expect(.tapToPayReaderTOSNotYetAccepted == domainError(stripeCode: 3930))
    }

    @Test func `stripe TOS acceptance failed maps to expected error`() {
        #expect(.tapToPayReaderTOSAcceptanceFailed == domainError(stripeCode: 3940))
    }

    @Test func `stripe merchant blocked maps to expected error`() {
        #expect(.tapToPayReaderMerchantBlocked == domainError(stripeCode: 3950))
    }

    @Test func `stripe invalid merchant maps to expected error`() {
        #expect(.tapToPayReaderInvalidMerchant == domainError(stripeCode: 3960))
    }

    @Test func `stripe device banned maps to expected error`() {
        #expect(.tapToPayReaderDeviceBanned == domainError(stripeCode: 3920))
    }

    @Test func `stripe unsupported mobile device maps to expected error`() {
        #expect(.unsupportedMobileDeviceConfiguration == domainError(stripeCode: 2910))
    }

    @Test func `stripe not accessible in background maps to expected error`() {
        #expect(.readerNotAccessibleInBackground == domainError(stripeCode: 3900))
    }

    @Test func `stripe command not allowed during call maps to expected error`() {
        #expect(.commandNotAllowedDuringCall == domainError(stripeCode: 2930))
    }

    @Test func `stripe invalid amount maps to expected error`() {
        #expect(.invalidAmount == domainError(stripeCode: 2940))
    }

    @Test func `stripe invalid currency maps to expected error`() {
        #expect(.invalidCurrency == domainError(stripeCode: 2950))
    }

    @Test func `stripe cancel failed already completed maps to expected error`() {
        #expect(.cancelFailedAlreadyCompleted == domainError(stripeCode: 1010))
    }

    @Test func `stripe nil payment intent maps to expected error`() {
        #expect(.nilPaymentIntent == domainError(stripeCode: 1540))
    }

    @Test func `stripe nil setup intent maps to expected error`() {
        #expect(.nilSetupIntent == domainError(stripeCode: 1542))
    }

    @Test func `stripe nil refund payment method maps to expected error`() {
        #expect(.nilRefundPaymentMethod == domainError(stripeCode: 1550))
    }

    @Test func `stripe invalid refund parameters maps to expected error`() {
        #expect(.invalidRefundParameters == domainError(stripeCode: 1555))
    }

    @Test func `stripe invalid client secret maps to expected error`() {
        #expect(.invalidClientSecret == domainError(stripeCode: 1560))
    }

    @Test func `stripe invalid discovery configuration maps to expected error`() {
        #expect(.invalidDiscoveryConfiguration == domainError(stripeCode: 1590))
    }

    @Test func `stripe invalid reader for update maps to expected error`() {
        #expect(.invalidReaderForUpdate == domainError(stripeCode: 1861))
    }

    @Test func `stripe feature not available maps to expected error`() {
        #expect(.featureNotAvailable == domainError(stripeCode: 1890))
    }

    @Test func `stripe bluetooth connection invalid location id parameter maps to expected error`() {
        #expect(.bluetoothConnectionInvalidLocationIdParameter == domainError(stripeCode: 1910))
    }

    @Test func `stripe invalid required parameter maps to expected error`() {
        #expect(.invalidRequiredParameter == domainError(stripeCode: 1920))
    }

    @Test func `stripe forwarding test mode payment in live mode maps to expected error`() {
        #expect(.forwardingTestModePaymentInLiveMode == domainError(stripeCode: 1937))
    }

    @Test func `stripe forwarding live mode payment in test mode maps to expected error`() {
        #expect(.forwardingLiveModePaymentInTestMode == domainError(stripeCode: 1938))
    }

    @Test func `stripe reader connection configuration invalid maps to expected error`() {
        #expect(.readerConnectionConfigurationInvalid == domainError(stripeCode: 1940))
    }

    @Test func `stripe reader tipping parameter invalid maps to expected error`() {
        #expect(.readerTippingParameterInvalid == domainError(stripeCode: 1950))
    }

    @Test func `stripe invalid location id parameter maps to expected error`() {
        #expect(.invalidLocationIdParameter == domainError(stripeCode: 1960))
    }

    @Test func `stripe reader software update failed expired update maps to expected error`() {
        #expect(.readerSoftwareUpdateFailedExpiredUpdate == domainError(stripeCode: 2670))
    }

    @Test func `stripe missing emv data maps to expected error`() {
        #expect(.missingEMVData == domainError(stripeCode: 2892))
    }

    @Test func `stripe command not allowed maps to expected error`() {
        #expect(.commandNotAllowed == domainError(stripeCode: 2900))
    }

    @Test func `stripe bluetooth peer removed pairing information maps to expected error`() {
        #expect(.bluetoothPeerRemovedPairingInformation == domainError(stripeCode: 3240))
    }

    @Test func `stripe bluetooth already paired with another device maps to expected error`() {
        #expect(.bluetoothAlreadyPairedWithAnotherDevice == domainError(stripeCode: 3241))
    }

    @Test func `stripe unknown reader ip address maps to expected error`() {
        #expect(.unknownReaderIpAddress == domainError(stripeCode: 3860))
    }

    @Test func `stripe internet connect time out maps to expected error`() {
        #expect(.internetConnectTimeOut == domainError(stripeCode: 3870))
    }

    @Test func `stripe bluetooth reconnect started maps to expected error`() {
        #expect(.bluetoothReconnectStarted == domainError(stripeCode: 3890))
    }

    @Test func `stripe apple built in reader account deactivated maps to expected error`() {
        #expect(.tapToPayReaderAccountDeactivated == domainError(stripeCode: 3970))
    }

    @Test func `stripe reader missing encryption keys maps to expected error`() {
        #expect(.readerMissingEncryptionKeys == domainError(stripeCode: 3980))
    }

    @Test func `stripe unexpected reader error maps to expected error`() {
        #expect(.unexpectedReaderError == domainError(stripeCode: 5001))
    }

    @Test func `stripe command requires cardholder consent maps to expected error`() {
        #expect(.commandRequiresCardholderConsent == domainError(stripeCode: 6700))
    }

    @Test func `stripe refund failed maps to expected error`() {
        #expect(.refundFailed == domainError(stripeCode: 6800))
    }

    @Test func `stripe card swipe not available maps to expected error`() {
        #expect(.cardSwipeNotAvailable == domainError(stripeCode: 6900))
    }

    @Test func `stripe interac not supported offline maps to expected error`() {
        #expect(.interacNotSupportedOffline == domainError(stripeCode: 6901))
    }

    @Test func `stripe offline and card expired maps to expected error`() {
        #expect(.offlineAndCardExpired == domainError(stripeCode: 6902))
    }

    @Test func `stripe offline transaction declined maps to expected error`() {
        #expect(.offlineTransactionDeclined == domainError(stripeCode: 6903))
    }

    @Test func `stripe offline collect and confirm mismatch maps to expected error`() {
        #expect(.offlineCollectAndConfirmMismatch == domainError(stripeCode: 6904))
    }

    @Test func `stripe online pin not supported offline maps to expected error`() {
        #expect(.onlinePinNotSupportedOffline == domainError(stripeCode: 6905))
    }

    @Test func `stripe offline test card in livemode maps to expected error`() {
        #expect(.offlineTestCardInLivemode == domainError(stripeCode: 6906))
    }

    @Test func `stripe api response decoding error maps to expected error`() {
        #expect(.stripeAPIResponseDecodingError == domainError(stripeCode: 9030))
    }

    @Test func `stripe internal network error maps to expected error`() {
        #expect(.internalNetworkError == domainError(stripeCode: 9040))
    }

    @Test func `stripe connection token provider completed with error maps to expected error`() {
        #expect(.connectionTokenProviderCompletedWithError == domainError(stripeCode: 9050))
    }

    @Test func `stripe connection token provider timed out maps to expected error`() {
        #expect(.connectionTokenProviderTimedOut == domainError(stripeCode: 9052))
    }

    @Test func `stripe catch all error`() {
        // Any error code not mapped to an specific error will be
        // mapped to `internalServiceError`
        #expect(.internalServiceError == domainError(stripeCode: Int.max))
    }
}

private extension `Card Reader Service Error Tests` {
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
