import CocoaLumberjackSwift
import Foundation

/// The session factory retains one actor per store for both unlock and approval.
actor POSLocalRateLimiter {
    private let key: String
    private let storage: POSSecureStorage
    private let clock: POSPINClock
    nonisolated let context: POSPINAttemptContext
    private var isAuthenticating = false
    private var cached: State?
    private var sample: TimeInterval?
    private var checkpoint: TimeInterval?
    private var logout: UUID?

    init(siteID: Int64,
         storage: POSSecureStorage = KeychainPOSSecureStorage(),
         clock: POSPINClock = SystemPOSPINClock()) {
        self.key = "attempts.\(siteID)"
        self.storage = storage
        self.context = POSPINAttemptContext(scopeID: storage.scopeID)
        self.clock = clock
    }

    func checkAllowed(token: POSPINAttemptContext.Token, checkpoint: Bool = false) throws(POSAuthError) {
        guard !isAuthenticating else { throw .unknown }
        do {
            try context.withCurrent(token) {
                let state = try current(logout: token.logout, forceCheckpoint: checkpoint)
                if state.wait > 0 { throw POSAuthError.rateLimited(remainingSeconds: Int(state.wait.rounded(.up))) }
            }
        } catch let error as POSAuthError {
            throw error
        } catch {
            throw .unknown
        }
    }

    func authenticate(pin: String,
                      using authenticator: POSPINAuthenticating,
                      capability: POSCapability? = nil,
                      token: POSPINAttemptContext.Token) async throws(POSAuthError) -> POSStaff {
        guard !isAuthenticating, !Task.isCancelled else { throw .unknown }
        isAuthenticating = true
        defer { isAuthenticating = false }
        do {
            let previous = try context.withCurrent(token) {
                let state = try current(logout: token.logout)
                if state.wait > 0 { throw POSAuthError.rateLimited(remainingSeconds: Int(state.wait.rounded(.up))) }
                // Persist before comparing: a process kill must not create an uncounted PIN oracle.
                try replace(state.failed(), at: try time())
                return state
            }
            let staff: POSStaff
            do {
                staff = try await authenticator.authenticate(withPIN: pin)
            } catch {
                guard context.isCurrent(token), !Task.isCancelled else { throw POSAuthError.unknown }
                if error == .unknown {
                    // The credential provider failed before comparing a PIN. It produced no guess result.
                    try context.withCurrent(token) { try replace(previous, at: try time()) }
                }
                if error == .invalidPIN {
                    throw cachedWaitError(fallback: .invalidPIN)
                }
                throw error
            }
            guard !Task.isCancelled else { throw POSAuthError.unknown }
            return try context.withCurrent(token) {
                if let capability, !staff.hasCapability(capability) { throw cachedWaitError(fallback: .invalidPIN) }
                // Authority comes from the verified credential's capabilities, never its display name.
                try replace(staff.hasCapability(.manageStoreSettings) ? State() : previous, at: try time())
                return staff
            }
        } catch let error as POSAuthError {
            throw error
        } catch {
            throw .unknown
        }
    }

    func recover(using recovery: POSPINRecoveryAuthenticating, token: POSPINAttemptContext.Token) async throws(POSAuthError) -> POSStaff {
        guard !isAuthenticating, !Task.isCancelled else { throw .unknown }
        isAuthenticating = true
        defer { isAuthenticating = false }
        do {
            let staff = try await recovery.authenticate()
            guard !Task.isCancelled, staff.hasCapability(.manageStoreSettings) else { throw POSAuthError.unknown }
            return try context.withCurrent(token) {
                try save(State())
                cached = nil
                sample = nil
                checkpoint = nil
                return staff
            }
        } catch let error as POSAuthError {
            throw error
        } catch {
            throw .unknown
        }
    }
}

private extension POSLocalRateLimiter {
    struct State: Codable, Sendable {
        var version = 1
        var failures = 0
        var wait: TimeInterval = 0
        var quiet: TimeInterval = 0

        func failed() -> State {
            let count = failures == Int.max ? 20 : failures + 1
            let duration: TimeInterval = switch count {
            case 5: 30
            case 10: 300
            case 15: 1800
            case let count where count.isMultiple(of: 5): 3600
            default: 0
            }
            return State(failures: count, wait: duration)
        }
    }

    func current(logout: UUID, forceCheckpoint: Bool = false) throws -> State {
        if self.logout != logout {
            cached = nil
            sample = nil
            checkpoint = nil
            self.logout = logout
        }
        if cached == nil {
            let state = try load()
            // A new service has no trusted interval. Preserve saved credit and grant zero for the unknown gap.
            let now = try time()
            cached = state
            sample = now
            checkpoint = now
        }
        guard var state = cached, let sample, let checkpoint else { throw POSAuthError.unknown }
        let now = try time()
        guard now >= sample else { throw POSAuthError.unknown }
        let elapsed = min(86400, now - sample)
        let previousWait = state.wait
        state.wait = max(0, state.wait - elapsed)
        if state.failures > 0 { state.quiet = min(86400, state.quiet + elapsed) }
        let quietExpired = state.failures > 0 && state.quiet >= 86400
        if quietExpired { state = State() }
        let shouldCheckpoint = forceCheckpoint || quietExpired || (previousWait > 0 && (state.wait == 0 || now - checkpoint >= 5))
        if shouldCheckpoint {
            try save(state)
            self.checkpoint = now
        }
        cached = state
        self.sample = now
        return state
    }

    func time() throws -> TimeInterval {
        let now = try clock.now()
        guard now.isFinite, now >= 0, sample.map({ now >= $0 }) ?? true else { throw POSAuthError.unknown }
        return now
    }

    func replace(_ state: State, at time: TimeInterval) throws {
        try save(state)
        cached = state
        sample = time
        checkpoint = time
    }

    func save(_ state: State) throws {
        do {
            let data = try JSONEncoder().encode(state)
            try storage.setData(data, forKey: key)
            guard try storage.data(forKey: key) == data else { throw POSAuthError.unknown }
        } catch {
            // A write may have succeeded before verification failed. Never overwrite it from an older cache.
            cached = nil
            sample = nil
            checkpoint = nil
            DDLogError("POS PIN attempt state could not be saved or verified (error type: \(type(of: error)))")
            throw error
        }
    }

    func load() throws -> State {
        do {
            let state = try storage.data(forKey: key).map { try JSONDecoder().decode(State.self, from: $0) } ?? State()
            guard state.version == 1, state.failures >= 0, state.wait.isFinite, (0...3600).contains(state.wait),
                  state.quiet.isFinite, (0...86400).contains(state.quiet) else { throw POSAuthError.unknown }
            return state
        } catch {
            DDLogError("POS PIN attempt state could not be read or decoded (error type: \(type(of: error)))")
            throw error
        }
    }

    func cachedWaitError(fallback: POSAuthError) -> POSAuthError {
        guard let wait = cached?.wait, wait > 0 else { return fallback }
        return .rateLimited(remainingSeconds: Int(wait.rounded(.up)))
    }
}
