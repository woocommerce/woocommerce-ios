import Foundation
import struct Yosemite.CardReaderInput

enum CardPresentPaymentAlertDetails {
    case scanningForReaders(endSearch: () -> Void)
    case scanningFailed(error: Error,
                        endSearch: () -> Void)
    case bluetoothRequired
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
    case connectingFailedUpdateAddress(wcSettingsAdminURL: URL?,
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
    case updateProgress(requiredUpdate: Bool,
                        progress: Float,
                        cancelUpdate: (() -> Void)?)
    case updateFailed(tryAgain: (() -> Void)?,
                      cancelUpdate: () -> Void)
    case updateFailedNonRetryable(cancelUpdate: () -> Void)
    case updateFailedLowBattery(batteryLevel: Double?,
                                cancelUpdate: () -> Void)
    case tapSwipeOrInsertCard(inputMethods: CardReaderInput,
                              cancelPayment: () -> Void)
    case success(done: () -> Void)
    case error(error: any Error,
               tryAgain: () -> Void,
               cancelPayment: () -> Void)
    case errorNonRetryable(error: any Error,
                           cancelPayment: () -> Void)
    case processing
    case displayReaderMessage(message: String)
    case cancelledOnReader
    case validatingOrder(cancelPayment: () -> Void)
}
