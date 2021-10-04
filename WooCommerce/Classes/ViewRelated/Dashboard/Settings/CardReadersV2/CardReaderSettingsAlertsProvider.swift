import Foundation
import UIKit

/// Defines a protocol for card reader alert providers to conform to - defining what
/// alerts such a provider is expected to provide over the course of searching for
/// and connecting to a reader
///
protocol CardReaderSettingsAlertsProvider {
    /// Defines a cancellable alert indicating we are searching for a reader
    ///
    func scanningForReader(from: UIViewController, cancel: @escaping () -> Void)

    /// Defines a cancellable (closeable) alert indicating the search failed
    ///
    func scanningFailed(from: UIViewController, error: Error, close: @escaping () -> Void)

    /// Defines an interactive alert indicating a reader has been found. The user must
    /// choose to connect to that reader or continue searching
    ///
    func foundReader(from: UIViewController,
                     name: String,
                     connect: @escaping () -> Void,
                     continueSearch: @escaping () -> Void)

    /// Defines an interactive alert indicating more than one reader has been found. The user must
    /// choose to connect to that reader or cancel searching
    ///
    func foundSeveralReaders(from: UIViewController,
                             readerIDs: [String],
                             connect: @escaping (String) -> Void,
                             cancelSearch: @escaping () -> Void)

    /// Allows updating the list of readers found in the several readers alert
    ///
    func updateSeveralReadersList(readerIDs: [String])

    /// Defines a non-interactive alert indicating a connection is in progress to a particular reader
    ///
    func connectingToReader(from: UIViewController)

    /// Defines an alert indicating connecting failed. The user may continue the search
    /// or cancel
    ///
    func connectingFailed(from: UIViewController,
                          continueSearch: @escaping () -> Void,
                          cancelSearch: @escaping () -> Void)

    /// Defines an alert indicating an update couldn't be installed because the reader is low on battery.
    ///
    func updatingFailedLowBattery(from: UIViewController,
                                  batteryLevel: Double?,
                                  close: @escaping () -> Void)

    /// Defines an alert indicating an update couldn't be installed.
    ///
    func updatingFailed(from: UIViewController, tryAgain: (() -> Void)?, close: @escaping () -> Void)

    /// Shows progress when a software update is being installed
    ///
    func updateProgress(from: UIViewController, requiredUpdate: Bool, progress: Float, cancel: (() -> Void)?)

    /// Dismisses any alert being presented
    ///
    func dismiss()
}
