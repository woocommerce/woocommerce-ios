import Foundation

enum CardPresentPaymentAlertType {
    case scanningForReaders(viewModel: CardPresentPaymentScanningForReadersAlertViewModel)
    case scanningFailed(viewModel: CardPresentPaymentScanningFailedAlertViewModel)
    case bluetoothRequired(viewModel: CardPresentPaymentBluetoothRequiredAlertViewModel)
    case foundReader(viewModel: CardPresentPaymentFoundReaderAlertViewModel)
    case updatingReader(viewModel: CardPresentPaymentUpdatingReaderAlertViewModel)
    case updateFailed(viewModel: CardPresentPaymentReaderUpdateFailedAlertViewModel)
    case connectingToReader(viewModel: CardPresentPaymentConnectingToReaderAlertViewModel)
    case connectingFailed(viewModel: CardPresentPaymentConnectingFailedAlertViewModel)
    case connectingFailedNonRetryable(viewModel: CardPresentPaymentConnectingFailedNonRetryableAlertViewModel)
    case connectingFailedChargeReader(viewModel: CardPresentPaymentConnectingFailedChargeReaderAlertViewModel)
    case connectingFailedUpdateAddress(viewModel: CardPresentPaymentConnectingFailedUpdateAddressAlertViewModel)
    case connectingFailedUpdatePostalCode(viewModel: CardPresentPaymentConnectingFailedUpdatePostalCodeAlertViewModel)
}

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
    case showAlert(_ alertDetails: CardPresentPaymentAlertType)
    case showPaymentMessage(_ message: CardPresentPaymentMessageType)
    case showReaderList(_ readerIDs: [String], selectionHandler: ((String?) -> Void))
    case showOnboarding(_ onboardingViewModel: CardPresentPaymentsOnboardingViewModel)
}
