import Foundation
import UIKit
import Yosemite

/// Defines a protocol for card reader alert providers to conform to - defining what
/// alerts such a provider is expected to provide over the course of searching for
/// and connecting to a reader
///
protocol CardReaderSettingsAlertsProvider {
    /// Allows updating the list of readers found in the several readers alert
    ///
    func updateSeveralReadersList(readerIDs: [String])

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
