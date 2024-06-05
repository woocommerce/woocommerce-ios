import Foundation

typealias CardPresentPaymentAlertViewModel = CardPresentPaymentsModalViewModelContent & CardPresentPaymentsModalViewModelActions

enum CardPresentPaymentEvent {
    case idle
    case showAlert(_ alertViewModel: CardPresentPaymentAlertViewModel)
    case showReaderList(_ readerIDs: [String], selectionHandler: ((String) -> Void))
    case showOnboarding(_ onboardingViewModel: CardPresentPaymentsOnboardingViewModel)
    case showWCSettingsWebView(adminURL: URL, completion: () -> Void)
}
