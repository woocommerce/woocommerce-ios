import Foundation

enum CardPresentPaymentAlertDetails {
    case scanningForReaders
    case scanningFailed
    case bluetoothRequired
    case connectingToReader
    case connectingFailed
    case connectingFailedUpdatePostalCode
    case connectingFailedChargeReader
    case connectingFailedUpdateAddress
    case preparingForPayment
    case selectSearchType
    case foundReader
    case updateProgress
    case updateFailed
    case updateFailedLowBattery
    case updateFailedNonRetryable
    case tapCard
    case success
    case successWithoutEmail
    case error
    case errorNonRetryable
    case processing
    case displayReaderMessage
    case cancelledOnReader
    case validatingOrder
}
