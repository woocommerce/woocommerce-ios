import Foundation

enum CardPresentPaymentEvent {
    case idle
    case show(eventDetails: CardPresentPaymentEventDetails)
    case showReaderList(_ readerIDs: [String], selectionHandler: ((String?) -> Void))
    case showOnboarding(_ onboardingViewModel: CardPresentPaymentsOnboardingViewModel)
}
