import Foundation
import Yosemite
import Combine

/// Combine aware wrapper around AppSettingsActions for Known Card Readers
///
final class CardReaderSettingsKnownReaderStorage: CardReaderSettingsKnownReaderProvider {
    private let stores: StoresManager

    var knownReader: AnyPublisher<String?, Never> {
        knownReaderSubject.eraseToAnyPublisher()
    }
    private let knownReaderSubject = CurrentValueSubject<String?, Never>(nil)

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
        self.loadReader()
    }

    func rememberCardReader(cardReaderID: String) {
        let action = AppSettingsAction.rememberCardReader(cardReaderID: cardReaderID, onCompletion: { [weak self] _ in
            self?.loadReader()
        })
        stores.dispatch(action)
    }

    func forgetCardReader() {
        let action = AppSettingsAction.forgetCardReader(onCompletion: { [weak self] _ in
            self?.loadReader()
        })
        stores.dispatch(action)
    }

    private func loadReader() {
        let action = AppSettingsAction.loadCardReader(onCompletion: { [knownReaderSubject] result in
            switch result {
            case .success(let reader):
                knownReaderSubject.send(reader)
            case .failure(let error):
                DDLogError("⛔️ Error synchronizing known reader: \(error)")
            }
        })
        stores.dispatch(action)
    }
}
