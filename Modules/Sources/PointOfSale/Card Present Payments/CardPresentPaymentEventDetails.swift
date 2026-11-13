import Foundation
import struct Yosemite.CardReaderInput

public enum CardPresentPaymentEventDetails: Sendable {
    case scanningForReaders(endSearch: @MainActor @Sendable () -> Void)
    case scanningFailed(error: Error,
                        endSearch: @MainActor @Sendable () -> Void)
    case bluetoothRequired(error: Error,
                           endSearch: @MainActor @Sendable () -> Void)
    case connectingToReader
    case connectingFailed(error: Error,
                          retrySearch: @MainActor @Sendable () -> Void,
                          endSearch: @MainActor @Sendable () -> Void)
    case connectingFailedNonRetryable(error: Error,
                                      endSearch: @MainActor @Sendable () -> Void)
    case connectingFailedUpdatePostalCode(retrySearch: @MainActor @Sendable () -> Void,
                                          endSearch: @MainActor @Sendable () -> Void)
    case connectingFailedChargeReader(retrySearch: @MainActor @Sendable () -> Void,
                                      endSearch: @MainActor @Sendable () -> Void)
    case connectingFailedUpdateAddress(wcSettingsAdminURL: URL,
                                       showsInAuthenticatedWebView: Bool,
                                       retrySearch: @MainActor @Sendable () -> Void,
                                       endSearch: @MainActor @Sendable () -> Void)
    case preparingForPayment(cancelPayment: @MainActor @Sendable () -> Void)
    case selectSearchType(tapToPay: @MainActor @Sendable () -> Void,
                          bluetooth: @MainActor @Sendable () -> Void,
                          endSearch: @MainActor @Sendable () -> Void)
    case foundReader(name: String,
                     connect: @MainActor @Sendable () -> Void,
                     continueSearch: @MainActor @Sendable () -> Void,
                     endSearch: @MainActor @Sendable () -> Void)
    case foundMultipleReaders(readerIDs: [String],
                              selectionHandler: @MainActor @Sendable (String?) -> Void)
    case updateProgress(requiredUpdate: Bool,
                        progress: Float,
                        cancelUpdate: (@MainActor @Sendable () -> Void)?)
    case updateFailed(tryAgain: @MainActor @Sendable () -> Void,
                      cancelUpdate: @MainActor @Sendable () -> Void)
    case updateFailedNonRetryable(cancelUpdate: @MainActor @Sendable () -> Void)
    case updateFailedLowBattery(batteryLevel: Double?,
                                retrySearch: @MainActor @Sendable () -> Void,
                                cancelUpdate: @MainActor @Sendable () -> Void)
    case connectionSuccess(done: @MainActor @Sendable () -> Void)
    case tapSwipeOrInsertCard(inputMethods: CardReaderInput,
                              cancelPayment: @MainActor @Sendable () -> Void)
    case cardInserted(cancelPayment: @MainActor @Sendable () -> Void)
    case paymentSuccess(done: @MainActor @Sendable () -> Void)
    case paymentError(error: any Error,
                      retryApproach: CardPresentPaymentRetryApproach,
                      cancelPayment: @MainActor @Sendable () -> Void)
    case paymentCaptureError(cancelPayment: @MainActor @Sendable () -> Void)
    case paymentIntentCreationError(error: any Error,
                                    cancelPayment: @MainActor @Sendable () -> Void)
    case processing
    case displayReaderMessage(message: String)
    case cancelledOnReader
    case paymentCancellationConfirmation(onDismiss: @MainActor @Sendable () -> Void)
    case validatingOrder(cancelPayment: @MainActor @Sendable () -> Void)

    case locationRequestPreAlert(requestPermission: @MainActor @Sendable () -> Void)
    case locationRequired(cancel: @MainActor @Sendable () -> Void)
}
