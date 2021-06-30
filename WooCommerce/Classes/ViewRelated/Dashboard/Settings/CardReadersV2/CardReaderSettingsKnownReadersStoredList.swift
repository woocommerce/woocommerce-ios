import Foundation
import Yosemite
import Combine

/// Combine aware wrapper around AppSettingsActions for Known Card Readers
///
final class CardReaderSettingsKnownReadersStoredList: CardReaderSettingsKnownReadersProvider {
    private let stores: StoresManager

    @Published private(set) var knownReaders: [String]
    var knownReadersPublished: Published<[String]> { _knownReaders }
    var knownReadersPublisher: Published<[String]>.Publisher { $knownReaders }

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
        self.knownReaders = []

        self.loadReaders()
    }

    func rememberCardReader(cardReaderID: String) {
        let action = AppSettingsAction.rememberCardReader(cardReaderID: cardReaderID, onCompletion: { [weak self] _ in
            self?.loadReaders()
        })
        stores.dispatch(action)
    }

    func forgetCardReader(cardReaderID: String) {
        let action = AppSettingsAction.forgetCardReader(cardReaderID: cardReaderID, onCompletion: { [weak self] _ in
            self?.loadReaders()
        })
        stores.dispatch(action)
    }

    private func loadReaders() {
        let action = AppSettingsAction.loadCardReaders(onCompletion: { [weak self] result in
            switch result {
            case .success(let readers):
                self?.knownReaders = readers
            case .failure(let error):
                DDLogError("⛔️ Error synchronizing known readers: \(error)")
            }
        })
        stores.dispatch(action)
    }
}
