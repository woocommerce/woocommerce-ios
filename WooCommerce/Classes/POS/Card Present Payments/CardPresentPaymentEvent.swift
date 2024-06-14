import Foundation

enum CardPresentPaymentMessageType {
    case preparingForPayment
    case tapSwipeOrInsertCard
    case processing
    case displayReaderMessage(message: String)
    case success
    case error
}

enum CardPresentPaymentEvent {
    case idle
    case show(eventDetails: CardPresentPaymentEventDetails)
    case showPaymentMessage(_ message: CardPresentPaymentMessageType)
    case showReaderList(_ readerIDs: [String], selectionHandler: ((String?) -> Void))
    case showOnboarding(_ onboardingViewModel: CardPresentPaymentsOnboardingViewModel)
}
