import Foundation
import Combine

/// Defines a protocol for wrappers around AppSettingsStore for "Known" Card Readers to confom to
/// Allows us to support multiple implementations/dependency injection, and avoid introducing
/// Combine into the Storage layer
///
protocol CardReaderSettingsKnownReadersProvider {

    /// We can't use a @Published wrapper for knownReaders as part of a protocol declaration, but we can
    /// require its synthesized methods explicitly
    ///
    var knownReaders: [String] { get }
    var knownReadersPublished: Published<[String]> { get }
    var knownReadersPublisher: Published<[String]>.Publisher { get }

    /// Remember a reader. Asynchronous.
    ///
    func rememberCardReader(cardReaderID: String)

    /// Forget a reader. Asynchronous.
    ///
    func forgetCardReader(cardReaderID: String)
}
