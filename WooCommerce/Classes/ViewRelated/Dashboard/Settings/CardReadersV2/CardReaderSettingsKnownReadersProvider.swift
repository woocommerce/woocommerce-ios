import Foundation
import Combine

/// Defines a protocol for wrappers around AppSettingsStore for "Known" Card Readers to confom to
/// Allows us to support multiple implementations/dependency injection, and avoid introducing
/// Combine into the Storage layer
///
protocol CardReaderSettingsKnownReaderProvider {

    /// Publishes changes to the known reader. (We remember only one reader.)
    ///
    var knownReader: AnyPublisher<String?, Never> { get }

    /// Remember this reader. Asynchronous.
    ///
    func rememberCardReader(cardReaderID: String)

    /// Forget the remembered reader. Asynchronous.
    ///
    func forgetCardReader()
}
