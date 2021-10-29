import StripeTerminal
/// Maps Stripe SDK specific errors to domain errors:
/// the mapping is done according to the error codes documented here:
/// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html
extension UnderlyingError {
    init(with stripeError: Error) {
        let error = stripeError as NSError

        switch error.code {
        case ErrorCode.Code.busy.rawValue:
            self = .busy
        case ErrorCode.Code.notConnectedToReader.rawValue:
            self = .notConnectedToReader
        case ErrorCode.Code.alreadyConnectedToReader.rawValue:
            self = .alreadyConnectedToReader
        case ErrorCode.Code.processInvalidPaymentIntent.rawValue:
            self = .processInvalidPaymentIntent
        case ErrorCode.Code.cannotConnectToUndiscoveredReader.rawValue:
            self = .connectingToUndiscoveredReader
        case ErrorCode.Code.unsupportedSDK.rawValue:
            self = .unsupportedSDK
        case ErrorCode.Code.featureNotAvailableWithConnectedReader.rawValue:
            self = .featureNotAvailableWithConnectedReader
        case ErrorCode.Code.canceled.rawValue:
            self = .commandCancelled
        case ErrorCode.Code.locationServicesDisabled.rawValue:
            self = .locationServicesDisabled
        case ErrorCode.Code.bluetoothDisabled.rawValue:
            self = .bluetoothDisabled
        case ErrorCode.Code.bluetoothError.rawValue:
            self = .bluetoothError
        case ErrorCode.Code.bluetoothScanTimedOut.rawValue:
            self = .bluetoothScanTimedOut
        case ErrorCode.Code.bluetoothLowEnergyUnsupported.rawValue:
            self = .bluetoothLowEnergyUnsupported
        case ErrorCode.Code.readerSoftwareUpdateFailedBatteryLow.rawValue:
            self = .readerSoftwareUpdateFailedBatteryLow
        case ErrorCode.Code.readerSoftwareUpdateFailedInterrupted.rawValue:
            self = .readerSoftwareUpdateFailedInterrupted
        case ErrorCode.Code.readerSoftwareUpdateFailed.rawValue:
            self = .readerSoftwareUpdateFailed
        case ErrorCode.Code.readerSoftwareUpdateFailedReaderError.rawValue:
            self = .readerSoftwareUpdateFailedReader
        case ErrorCode.Code.readerSoftwareUpdateFailedServerError.rawValue:
            self = .readerSoftwareUpdateFailedServer
        case ErrorCode.Code.cardInsertNotRead.rawValue:
            self = .cardInsertNotRead
        case ErrorCode.Code.cardSwipeNotRead.rawValue:
            self = .cardSwipeNotRead
        case ErrorCode.Code.cardReadTimedOut.rawValue:
            self = .cardReadTimeOut
        case ErrorCode.Code.cardRemoved.rawValue:
            self = .cardRemoved
        case ErrorCode.Code.cardLeftInReader.rawValue:
            self = .cardLeftInReader
        case ErrorCode.Code.readerBusy.rawValue:
            self = .readerBusy
        case ErrorCode.Code.incompatibleReader.rawValue:
            self = .readerIncompatible
        case ErrorCode.Code.readerCommunicationError.rawValue:
            self = .readerCommunicationError
        case ErrorCode.Code.bluetoothConnectTimedOut.rawValue:
            self = .bluetoothConnectTimedOut
        case ErrorCode.Code.bluetoothDisconnected.rawValue:
            self = .bluetoothDisconnected
        case ErrorCode.Code.unsupportedReaderVersion.rawValue:
            self = .unsupportedReaderVersion
        case ErrorCode.Code.connectFailedReaderIsInUse.rawValue:
            self = .connectFailedReaderIsInUse
        case ErrorCode.Code.unexpectedSdkError.rawValue:
            self = .unexpectedSDKError
        case ErrorCode.Code.paymentDeclinedByStripeAPI.rawValue:
            self = .paymentDeclinedByPaymentProcessorAPI
        case ErrorCode.Code.paymentDeclinedByReader.rawValue:
            self = .paymentDeclinedByCardReader
        case ErrorCode.Code.notConnectedToInternet.rawValue:
            self = .notConnectedToInternet
        case ErrorCode.Code.requestTimedOut.rawValue:
            self = .requestTimedOut
        case ErrorCode.Code.sessionExpired.rawValue:
            self = .readerSessionExpired
        case ErrorCode.Code.stripeAPIError.rawValue:
            self = .processorAPIError
        default:
            self = .internalServiceError
        }
    }
}
