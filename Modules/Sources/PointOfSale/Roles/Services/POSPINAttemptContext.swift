import Foundation
import Synchronization

/// Invalidates authentication synchronously while storage work remains on the limiter's actor.
final class POSPINAttemptContext: Sendable {
    struct Token: Equatable, Sendable {
        let session: UUID
        let logout: UUID
    }

    private static let logout = Mutex<[String: UUID]>([:])
    private let scopeID: String

    init(scopeID: String) { self.scopeID = scopeID }
    private static let writes = Mutex(())
    private let session = Mutex(UUID())
    @MainActor private var pendingPINChanges = 0

    @MainActor var hasPendingPINChanges: Bool { pendingPINChanges > 0 }

    @MainActor func beginPINChange() -> POSPINChangeRegistration {
        pendingPINChanges += 1
        return POSPINChangeRegistration { self.pendingPINChanges -= 1 }
    }

    func current() -> Token {
        Self.logout.withLock { logout in
            let epoch = logout[scopeID] ?? UUID()
            logout[scopeID] = epoch
            return session.withLock { Token(session: $0, logout: epoch) }
        }
    }

    func invalidate() -> Token {
        Self.logout.withLock { logout in
            session.withLock {
                $0 = UUID()
                let epoch = logout[scopeID] ?? UUID()
                logout[scopeID] = epoch
                return Token(session: $0, logout: epoch)
            }
        }
    }

    func isCurrent(_ token: Token) -> Bool {
        Self.logout.withLock { logout in
            session.withLock { token.logout == logout[scopeID] && token.session == $0 }
        }
    }

    func invalidate(ifCurrent token: Token) -> Token? {
        Self.logout.withLock { logout in
            session.withLock {
                guard token.logout == logout[scopeID], token.session == $0 else { return nil }
                $0 = UUID()
                return Token(session: $0, logout: token.logout)
            }
        }
    }

    func withCurrent<T>(_ token: Token, operation: () throws -> T) throws -> T {
        try Self.writes.withLock { _ in
            guard isCurrent(token) else { throw POSAuthError.unknown }
            return try operation()
        }
    }

    static func logoutEpoch(scopeID: String) -> UUID {
        logout.withLock {
            let epoch = $0[scopeID] ?? UUID()
            $0[scopeID] = epoch
            return epoch
        }
    }

    static func withLogoutEpoch<T>(scopeID: String, epoch: UUID, operation: () throws -> T) throws -> T {
        try writes.withLock { _ in
            guard logout.withLock({ $0[scopeID] == epoch }) else { throw POSPINStoreError.storageFailure }
            return try operation()
        }
    }

    static func clearAll(scopeID: String, operation: () throws -> Void) throws {
        logout.withLock { $0[scopeID] = UUID() }
        try writes.withLock { _ in try operation() }
    }
}

@MainActor
final class POSPINChangeRegistration {
    private var onFinish: (() -> Void)?

    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }

    func finish() {
        let completion = onFinish
        onFinish = nil
        completion?()
    }
}
