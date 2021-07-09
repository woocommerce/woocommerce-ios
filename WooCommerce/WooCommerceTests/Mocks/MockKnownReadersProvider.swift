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
        var readerIDs = knownReadersSubject.value
        readerIDs.append(cardReaderID)
        knownReadersSubject.send(readerIDs)
    }

    func forgetCardReader(cardReaderID: String) {
        var readerIDs = knownReadersSubject.value
        readerIDs = readerIDs.filter {$0 != cardReaderID}
        knownReadersSubject.send(readerIDs)
    }

}
