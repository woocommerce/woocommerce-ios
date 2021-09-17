import Foundation
import Combine

/// Defines a protocol for wrappers around AppSettingsStore for "Known" Card Readers to confom to
/// Allows us to support multiple implementations/dependency injection, and avoid introducing
/// Combine into the Storage layer
///
protocol CardReaderSettingsKnownReadersProvider {

    /// Publishes changes to the known reader list.
    ///
    var knownReaders: AnyPublisher<[String], Never> { get }

    /// Remember a reader. Asynchronous.
    ///
    func rememberCardReader(cardReaderID: String)

    /// Forget any remembered reader. Asynchronous.
    ///
    func forgetCardReader()
}
