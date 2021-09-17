import Yosemite
import Combine
@testable import WooCommerce

/// Allows mocking for CardReaderSettingsKnownReadersProvider
///
final class MockKnownReadersProvider: CardReaderSettingsKnownReadersProvider {
    var knownReaders: AnyPublisher<[String], Never> {
        knownReadersSubject.eraseToAnyPublisher()
    }
    private let knownReadersSubject = CurrentValueSubject<[String], Never>([])

    init(knownReaders: [String]? = nil) {
        if knownReaders != nil {
            knownReadersSubject.send(knownReaders!)
        }
    }

    func rememberCardReader(cardReaderID: String) {
        /// Note: We only remember a maximum of one reader now
        ///
        knownReadersSubject.send([cardReaderID])
    }

    func forgetCardReader() {
        knownReadersSubject.send([])
    }

}
