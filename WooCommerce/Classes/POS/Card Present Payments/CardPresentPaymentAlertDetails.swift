import Foundation
import struct Yosemite.CardReaderInput

enum CardPresentPaymentAlertDetails {
    case scanningForReaders(cancel: () -> Void)
    case scanningFailed(error: Error,
                        close: () -> Void)
    case bluetoothRequired
    case connectingToReader
    case connectingFailed(error: Error,
                          retrySearch: () -> Void,
                          cancelSearch: () -> Void)
    case connectingFailedNonRetryable(error: Error,
                                      close: () -> Void)
    case connectingFailedUpdatePostalCode(retrySearch: () -> Void,
                                          cancelSearch: () -> Void)
    case connectingFailedChargeReader(retrySearch: () -> Void,
                                      cancelSearch: () -> Void)
    case connectingFailedUpdateAddress(wcSettingsAdminURL: URL?,
                                       retrySearch: () -> Void,
                                       cancelSearch: () -> Void)
    case preparingForPayment(onCancel: () -> Void)
    case selectSearchType(tapToPay: () -> Void,
                          bluetooth: () -> Void,
                          cancel: () -> Void)
    case foundReader(name: String,
                     connect: () -> Void,
                     continueSearch: () -> Void,
                     cancelSearch: () -> Void)
    case updateProgress(requiredUpdate: Bool,
                        progress: Float,
                        cancel: (() -> Void)?)
    case updateFailed(tryAgain: (() -> Void)?,
                      close: () -> Void)
    case updateFailedNonRetryable(close: () -> Void)
    case updateFailedLowBattery(batteryLevel: Double?,
                                close: () -> Void)
    case tapSwipeOrInsertCard(inputMethods: CardReaderInput,
                              cancel: () -> Void)
    case success(done: () -> Void)
    case error(error: any Error,
               tryAgain: () -> Void,
               dismissCompletion: () -> Void)
    case errorNonRetryable(error: any Error,
                           dismissCompletion: () -> Void)
    case processing
    case displayReaderMessage(message: String)
    case cancelledOnReader
    case validatingOrder(onCancel: () -> Void)
}
