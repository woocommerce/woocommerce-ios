import Foundation
import UIKit
import Yosemite

/// Defines a protocol for card reader connection alert providers to conform to - defining what
/// alert viewModels such a provider is expected to provide over the course of searching for
/// and connecting to a reader
///
protocol CardReaderConnectionAlertsProviding<AlertDetails> {
    associatedtype AlertDetails
    /// Defines a cancellable alert indicating we are searching for a reader
    ///
    func scanningForReader(cancel: @escaping () -> Void) -> AlertDetails

    /// Defines a cancellable (closeable) alert indicating the search failed
    ///
    func scanningFailed(error: Error, close: @escaping () -> Void) -> AlertDetails

    /// Defines a non-interactive alert indicating a connection is in progress to a particular reader
    ///
    func connectingToReader() -> AlertDetails

    /// Defines an alert indicating connecting failed. The user may continue the search
    /// or cancel
    ///
    func connectingFailed(error: Error,
                          retrySearch: @escaping () -> Void,
                          cancelSearch: @escaping () -> Void) -> AlertDetails

    /// Defines an alert indicating connecting failed, in a way which must be resolved outside
    /// the connection flow. The user can close the alert.
    ///
    func connectingFailedNonRetryable(error: Error,
                                      close: @escaping () -> Void) -> AlertDetails

    /// Defines an alert indicating connecting failed because their address needs updating.
    /// The user may try again or cancel
    ///
    func connectingFailedIncompleteAddress(wcSettingsAdminURL: URL?,
                                           showsInAuthenticatedWebView: Bool,
                                           openWCSettings: (() -> Void)?,
                                           retrySearch: @escaping () -> Void,
                                           cancelSearch: @escaping () -> Void) -> AlertDetails

    /// Defines an alert indicating connecting failed because their postal code needs updating.
    /// The user may try again or cancel
    ///
    func connectingFailedInvalidPostalCode(retrySearch: @escaping () -> Void,
                                           cancelSearch: @escaping () -> Void) -> AlertDetails

    /// Defines an alert indicating an update couldn't be installed.
    ///
    func updatingFailed(tryAgain: (() -> Void)?, close: @escaping () -> Void) -> AlertDetails

    /// Shows progress when a software update is being installed
    ///
    func updateProgress(requiredUpdate: Bool, progress: Float, cancel: (() -> Void)?) -> AlertDetails

    func selectSearchType(tapToPay: @escaping () -> Void,
                          bluetooth: @escaping () -> Void,
                          cancel: @escaping () -> Void) -> AlertDetails
}


/// Defines a protocol for card reader connection alert providers to conform to, if they support choosing
/// between several readers - defining what alert viewModels such a provider is expected to provide over
/// the course of searching for and connecting to a reader.
///
protocol MultipleCardReaderConnectionAlertsProviding<AlertDetails> {
    associatedtype AlertDetails
    /// Defines an interactive alert indicating a reader has been found. The user must
    /// choose to connect to that reader or continue searching
    ///
    func foundReader(name: String,
                     connect: @escaping () -> Void,
                     continueSearch: @escaping () -> Void,
                     cancelSearch: @escaping () -> Void) -> AlertDetails

    // TODO: implement this approach, allowing us to remove the several readers logic from CardPresentPaymentAlertsPresenter
    // https://github.com/woocommerce/woocommerce-ios/issues/8296
    /// Defines an interactive alert indicating more than one reader has been found. The user must
    /// choose to connect to that reader or cancel searching
    ///
//    func foundSeveralReaders(readerIDs: [String],
//                             connect: @escaping (String) -> Void,
//                             cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel

    /// Allows updating the list of readers found in the several readers alert
    ///
//    func updateSeveralReadersList(readerIDs: [String]) -> CardPresentPaymentsModalViewModel
}

/// Defines a protocol for card reader connection alert providers to conform to, if they support battery
/// powered readers - defining what alert viewModels such a provider is expected to provide over
/// the course of searching for and connecting to a reader.
///
protocol BatteryPoweredCardReaderConnectionAlertsProviding<AlertDetails> {
    associatedtype AlertDetails
    /// Defines an alert indicating connecting failed because the reader battery is critically low.
    /// The user may try searching again (i.e. for a different reader) or cancel
    ///
    func connectingFailedCriticallyLowBattery(retrySearch: @escaping () -> Void,
                                              cancelSearch: @escaping () -> Void) -> AlertDetails

    /// Defines an alert indicating an update couldn't be installed because the reader is low on battery.
    ///
    func updatingFailedLowBattery(batteryLevel: Double?,
                                  close: @escaping () -> Void) -> AlertDetails
}

protocol BluetoothReaderConnnectionAlertsProviding<AlertDetails>: CardReaderConnectionAlertsProviding,
                                                                  MultipleCardReaderConnectionAlertsProviding,
                                                                  BatteryPoweredCardReaderConnectionAlertsProviding {
    associatedtype AlertDetails
}
