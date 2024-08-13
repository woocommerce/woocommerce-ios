import Foundation
import struct Yosemite.CardReaderInput

enum CardPresentPaymentEventDetails {
    case scanningForReaders(endSearch: () -> Void)
    case scanningFailed(error: Error,
                        endSearch: () -> Void)
    case bluetoothRequired(error: Error,
                           endSearch: () -> Void)
    case connectingToReader
    case connectingFailed(error: Error,
                          retrySearch: () -> Void,
                          endSearch: () -> Void)
    case connectingFailedNonRetryable(error: Error,
                                      endSearch: () -> Void)
    case connectingFailedUpdatePostalCode(retrySearch: () -> Void,
                                          endSearch: () -> Void)
    case connectingFailedChargeReader(retrySearch: () -> Void,
                                      endSearch: () -> Void)
    case connectingFailedUpdateAddress(wcSettingsAdminURL: URL,
                                       showsInAuthenticatedWebView: Bool,
                                       retrySearch: () -> Void,
                                       endSearch: () -> Void)
    case preparingForPayment(cancelPayment: () -> Void)
    case selectSearchType(tapToPay: () -> Void,
                          bluetooth: () -> Void,
                          endSearch: () -> Void)
    case foundReader(name: String,
                     connect: () -> Void,
                     continueSearch: () -> Void,
                     endSearch: () -> Void)
    case foundMultipleReaders(readerIDs: [String],
                              selectionHandler: (String?) -> Void)
    case updateProgress(requiredUpdate: Bool,
                        progress: Float,
                        cancelUpdate: (() -> Void)?)
    case updateFailed(tryAgain: () -> Void,
                      cancelUpdate: () -> Void)
    case updateFailedNonRetryable(cancelUpdate: () -> Void)
    case updateFailedLowBattery(batteryLevel: Double?,
                                cancelUpdate: () -> Void)
    case connectionSuccess(done: () -> Void)
    case tapSwipeOrInsertCard(inputMethods: CardReaderInput,
                              cancelPayment: () -> Void)
    case paymentSuccess(done: () -> Void)
    case paymentError(error: any Error,
                      retryApproach: CardPresentPaymentRetryApproach,
                      cancelPayment: () -> Void)
    case paymentCaptureError(cancelPayment: () -> Void)
    case processing
    case displayReaderMessage(message: String)
    case cancelledOnReader
    case validatingOrder(cancelPayment: () -> Void)
}
