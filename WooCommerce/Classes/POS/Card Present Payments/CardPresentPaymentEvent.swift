import Foundation

enum CardPresentPaymentAlertType {
    case scanningForReaders(viewModel: CardPresentPaymentScanningForReadersAlertViewModel)
    case scanningFailed(viewModel: CardPresentPaymentScanningFailedAlertViewModel)
    case foundReader(viewModel: CardPresentPaymentFoundReaderAlertViewModel)
    case updatingReader(viewModel: CardPresentPaymentUpdatingReaderAlertViewModel)
    case updateFailed(viewModel: CardPresentPaymentReaderUpdateFailedAlertViewModel)
    case connectingToReader(viewModel: CardPresentPaymentConnectingToReaderAlertViewModel)
    case connectingFailed(viewModel: CardPresentPaymentConnectingFailedAlertViewModel)
}

enum CardPresentPaymentMessageType {
    case preparingForPayment
//        Text("Preparing for payment")
    case tapSwipeOrInsertCard
//        Text("Tap card")
    case processing
//        Text("Processing")
    case displayReaderMessage(message: String)
//        Text("Display reader message")
    case success
//        Text("Success")
    case error
//        Text("Error")
}

enum CardPresentPaymentEvent {
    case idle
    case showAlert(_ alertDetails: CardPresentPaymentAlertType)
    case showPaymentMessage(_ message: CardPresentPaymentMessageType)
    case showReaderList(_ readerIDs: [String], selectionHandler: ((String) -> Void))
    case showOnboarding(_ onboardingViewModel: CardPresentPaymentsOnboardingViewModel)
}
