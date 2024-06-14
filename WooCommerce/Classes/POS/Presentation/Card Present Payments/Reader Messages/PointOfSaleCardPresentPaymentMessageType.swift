import Foundation

enum PointOfSaleCardPresentPaymentMessageType {
    case preparingForPayment
    case tapSwipeOrInsertCard
    case processing
    case displayReaderMessage(message: String)
    case success
    case error
    case nonRetryableError
    case cancelledOnReader
}

extension CardPresentPaymentEventDetails {
    func toMessageType() -> PointOfSaleCardPresentPaymentMessageType? {
        switch self {
        case .preparingForPayment(cancelPayment: let cancelPayment):
            return .preparingForPayment
        case .tapSwipeOrInsertCard(inputMethods: let inputMethods, cancelPayment: let cancelPayment):
            return .tapSwipeOrInsertCard
        case .success(done: let done):
            return .success
        case .error(error: let error, tryAgain: let tryAgain, cancelPayment: let cancelPayment):
            return .error
        case .errorNonRetryable(error: let error, cancelPayment: let cancelPayment):
            return .nonRetryableError
        case .processing:
            return .processing
        case .displayReaderMessage(message: let message):
            return .displayReaderMessage(message: message)
        case .cancelledOnReader:
            return .cancelledOnReader
        case .scanningForReaders,
                .scanningFailed,
                .bluetoothRequired,
                .connectingToReader,
                .connectingFailed,
                .connectingFailedNonRetryable,
                .connectingFailedUpdatePostalCode,
                .connectingFailedChargeReader,
                .connectingFailedUpdateAddress,
                .selectSearchType,
                .foundReader,
                .updateProgress,
                .updateFailed,
                .updateFailedNonRetryable,
                .updateFailedLowBattery,
                .validatingOrder:
            return nil
        }
    }
}
