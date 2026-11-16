import Foundation
import Synchronization

final class POSPINSessionTokens: Sendable {
    struct Token: Equatable, Sendable {
        fileprivate let id = UUID()
    }

    private let storage: POSSecureStorage
    private let latest = Mutex(Token())

    init(storage: POSSecureStorage) {
        self.storage = storage
    }

    func current() -> Token {
        latest.withLock { $0 }
    }

    func invalidate() -> Token {
        latest.withLock { latest in
            latest = Token()
            return latest
        }
    }

    func invalidate(ifCurrent token: Token) -> Token? {
        latest.withLock { latest in
            guard token == latest, !storage.isStale else {
                return nil
            }
            latest = Token()
            return latest
        }
    }

    func isCurrent(_ token: Token) -> Bool {
        latest.withLock { $0 == token } && !storage.isStale
    }
}
