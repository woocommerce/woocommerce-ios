import Foundation

enum CardPresentPaymentEvent {
    case idle
    case showAlert(_ alertDetails: CardPresentPaymentAlertDetails)
    case showReaderList(_ readerIDs: [String], selectionHandler: ((String?) -> Void))
    case showOnboarding(_ onboardingViewModel: CardPresentPaymentsOnboardingViewModel)
}
