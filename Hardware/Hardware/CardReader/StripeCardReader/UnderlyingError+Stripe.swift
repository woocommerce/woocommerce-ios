import StripeTerminal
/// Maps Stripe SDK specific errors to domain errors:
/// the mapping is done according to the error codes documented here:
/// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html
extension UnderlyingError {
    static func make(with stripeError: NSError) -> Self {
        switch stripeError.code {
        case ErrorCode.Code.busy.rawValue:
            return .busy
        case ErrorCode.Code.notConnectedToReader.rawValue:
            return .notConnectedToReader
        case ErrorCode.Code.alreadyConnectedToReader.rawValue:
            return .alreadyConnectedToReader
        case ErrorCode.Code.processInvalidPaymentIntent.rawValue:
            return .processInvalidPaymentIntent
        case ErrorCode.Code.cannotConnectToUndiscoveredReader.rawValue:
            return .connectingToUndiscoveredReader
        case ErrorCode.Code.unsupportedSDK.rawValue:
            return .unsupportedSDK
        case ErrorCode.Code.featureNotAvailableWithConnectedReader.rawValue:
            return .featureNotAvailableWithConnectedReader
        case ErrorCode.Code.canceled.rawValue:
            return .commandCancelled
        case ErrorCode.Code.locationServicesDisabled.rawValue:
            return .locationServicesDisabled
        case ErrorCode.Code.bluetoothDisabled.rawValue:
            return .bluetoothDisabled
        case ErrorCode.Code.bluetoothError.rawValue:
            return .bluetoothError
        case ErrorCode.Code.bluetoothScanTimedOut.rawValue:
            return .bluetoothScanTimedOut
        case ErrorCode.Code.bluetoothLowEnergyUnsupported.rawValue:
            return .bluetoothLowEnergyUnsupported
        case ErrorCode.Code.readerSoftwareUpdateFailedBatteryLow.rawValue:
            return .readerSoftwareUpdateFailedBatteryLow
        case ErrorCode.Code.readerSoftwareUpdateFailedInterrupted.rawValue:
            return .readerSoftwareUpdateFailedInterrupted
        case ErrorCode.Code.readerSoftwareUpdateFailed.rawValue:
            return .readerSoftwareUpdateFailed
        case ErrorCode.Code.readerSoftwareUpdateFailedReaderError.rawValue:
            return .readerSoftwareUpdateFailedReader
        case ErrorCode.Code.readerSoftwareUpdateFailedServerError.rawValue:
            return .readerSoftwareUpdateFailedServer
        case ErrorCode.Code.cardInsertNotRead.rawValue:
            return .cardInsertNotRead
        case ErrorCode.Code.cardSwipeNotRead.rawValue:
            return .cardSwipeNotRead
        case ErrorCode.Code.cardReadTimedOut.rawValue:
            return .cardReadTimeOut
        case ErrorCode.Code.cardRemoved.rawValue:
            return .cardRemoved
        case ErrorCode.Code.cardLeftInReader.rawValue:
            return .cardLeftInReader
        case ErrorCode.Code.readerBusy.rawValue:
            return .readerBusy
        case ErrorCode.Code.incompatibleReader.rawValue:
            return .readerIncompatible
        case ErrorCode.Code.readerCommunicationError.rawValue:
            return .readerCommunicationError
        case ErrorCode.Code.bluetoothConnectTimedOut.rawValue:
            return .bluetoothConnectTimedOut
        case ErrorCode.Code.bluetoothDisconnected.rawValue:
            return .bluetoothDisconnected
        case ErrorCode.Code.unsupportedReaderVersion.rawValue:
            return .unsupportedReaderVersion
        case ErrorCode.Code.connectFailedReaderIsInUse.rawValue:
            return .connectFailedReaderIsInUse
        case ErrorCode.Code.unexpectedSdkError.rawValue:
            return .unexpectedSDKError
        case ErrorCode.Code.paymentDeclinedByStripeAPI.rawValue:
            return .paymentDeclinedByPaymentProcessorAPI
        case ErrorCode.Code.paymentDeclinedByReader.rawValue:
            return .paymentDeclinedByCardReader
        case ErrorCode.Code.notConnectedToInternet.rawValue:
            return .notConnectedToInternet
        case ErrorCode.Code.requestTimedOut.rawValue:
            return .requestTimedOut
        case ErrorCode.Code.sessionExpired.rawValue:
            return .readerSessionExpired
        default:
            return .internalServiceError
        }
    }
}
