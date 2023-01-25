import Foundation
import UIKit
import Yosemite

/// Defines a protocol for card reader connection alert providers to conform to - defining what
/// alert viewModels such a provider is expected to provide over the course of searching for
/// and connecting to a reader
///
protocol CardReaderConnectionAlertsProviding {
    /// Defines a cancellable alert indicating we are searching for a reader
    ///
    func scanningForReader(cancel: @escaping () -> Void) -> CardPresentPaymentsModalViewModel

    /// Defines a cancellable (closeable) alert indicating the search failed
    ///
    func scanningFailed(error: Error, close: @escaping () -> Void) -> CardPresentPaymentsModalViewModel

    /// Defines a non-interactive alert indicating a connection is in progress to a particular reader
    ///
    func connectingToReader() -> CardPresentPaymentsModalViewModel

    /// Defines an alert indicating connecting failed. The user may continue the search
    /// or cancel
    ///
    func connectingFailed(error: Error,
                          continueSearch: @escaping () -> Void,
                          cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel

    /// Defines an alert indicating connecting failed because their address needs updating.
    /// The user may try again or cancel
    ///
    func connectingFailedIncompleteAddress(openWCSettings: ((UIViewController) -> Void)?,
                                           retrySearch: @escaping () -> Void,
                                           cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel

    /// Defines an alert indicating connecting failed because their postal code needs updating.
    /// The user may try again or cancel
    ///
    func connectingFailedInvalidPostalCode(retrySearch: @escaping () -> Void,
                                           cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel

    /// Defines an alert indicating an update couldn't be installed.
    ///
    func updatingFailed(tryAgain: (() -> Void)?, close: @escaping () -> Void) -> CardPresentPaymentsModalViewModel

    /// Shows progress when a software update is being installed
    ///
    func updateProgress(requiredUpdate: Bool, progress: Float, cancel: (() -> Void)?) -> CardPresentPaymentsModalViewModel
}


/// Defines a protocol for card reader connection alert providers to conform to, if they support choosing
/// between several readers - defining what alert viewModels such a provider is expected to provide over
/// the course of searching for and connecting to a reader.
///
protocol MultipleCardReaderConnectionAlertsProviding {
    /// Defines an interactive alert indicating a reader has been found. The user must
    /// choose to connect to that reader or continue searching
    ///
    func foundReader(name: String,
                     connect: @escaping () -> Void,
                     continueSearch: @escaping () -> Void,
                     cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel

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
protocol BatteryPoweredCardReaderConnectionAlertsProviding {
    /// Defines an alert indicating connecting failed because the reader battery is critically low.
    /// The user may try searching again (i.e. for a different reader) or cancel
    ///
    func connectingFailedCriticallyLowBattery(retrySearch: @escaping () -> Void,
                                              cancelSearch: @escaping () -> Void) -> CardPresentPaymentsModalViewModel

    /// Defines an alert indicating an update couldn't be installed because the reader is low on battery.
    ///
    func updatingFailedLowBattery(batteryLevel: Double?,
                                  close: @escaping () -> Void) -> CardPresentPaymentsModalViewModel
}

typealias BluetoothReaderConnnectionAlertsProviding = CardReaderConnectionAlertsProviding &
                                                      MultipleCardReaderConnectionAlertsProviding &
                                                      BatteryPoweredCardReaderConnectionAlertsProviding
