import Foundation

enum PaymentSequence {
    case successAfterDelay(TimeInterval)
    case failAtStep(PaymentStep, message: String)
    case readerDisconnectsDuring(PaymentStep)
    case cashOnly
}

enum PaymentStep: CaseIterable {
    case scanning
    case connecting
    case preparingReader
    case acceptingCard
    case cardInserted
    case processing
    case success
}
