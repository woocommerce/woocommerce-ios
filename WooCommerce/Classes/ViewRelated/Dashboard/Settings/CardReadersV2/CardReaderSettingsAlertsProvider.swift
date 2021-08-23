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

    /// Defines a non-interactive alert indicating a connection is in progress to a particular reader
    ///
    func connectingToReader(from: UIViewController)

    /// Dismisses any alert being presented
    ///
    func dismiss()
}
