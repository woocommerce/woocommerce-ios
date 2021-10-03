import Yosemite
import Combine
@testable import WooCommerce

/// Allows mocking for CardReaderSettingsKnownReadersProvider
///
final class MockKnownReaderProvider: CardReaderSettingsKnownReaderProvider {
    var knownReader: AnyPublisher<String?, Never> {
        knownReaderSubject.eraseToAnyPublisher()
    }
    private let knownReaderSubject = CurrentValueSubject<String?, Never>(nil)

    init(knownReader: String? = nil) {
        if knownReader != nil {
            knownReaderSubject.send(knownReader!)
        }
    }

    func rememberCardReader(cardReaderID: String) {
        knownReaderSubject.send(cardReaderID)
    }

    func forgetCardReader() {
        knownReaderSubject.send(nil)
    }

}
