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
