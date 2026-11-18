import CocoaLumberjackSwift
import Foundation

actor POSLocalRateLimiter {
    nonisolated let sessionTokens: POSPINSessionTokens
    nonisolated let pendingPINChanges = POSPendingPINChanges()
    private let key: String
    private let storage: POSSecureStorage
    private let clock: POSPINClock
    private var record: AttemptRecord?
    private var lastTick: TimeInterval?
    private var isAuthenticating = false

    init(siteID: Int64,
         storage: POSSecureStorage = KeychainPOSSecureStorage(),
         clock: POSPINClock = SystemPOSPINClock()) {
        self.key = "attempts.\(siteID)"
        self.storage = storage
        self.clock = clock
        self.sessionTokens = POSPINSessionTokens(storage: storage)
    }

    nonisolated var isRetired: Bool {
        storage.isStale
    }

    func checkAllowed(token: POSPINSessionTokens.Token) throws(POSAuthError) {
        guard !isAuthenticating else { throw .unknown }
        try requireCurrent(token)
        try throwIfWaiting(try advancedRecord())
    }

    func saveElapsedTime(token: POSPINSessionTokens.Token) {
        guard !isAuthenticating, sessionTokens.isCurrent(token) else { return }
        do {
            let record = try advancedRecord()
            if record.hasProgress {
                try save(record)
            }
        } catch {
            DDLogError("POS PIN attempt elapsed time could not be saved (error: \(error))")
        }
    }

    func authenticate(pin: String,
                      using authenticator: POSPINAuthenticating,
                      capability requiredCapability: POSCapability? = nil,
                      token: POSPINSessionTokens.Token) async throws(POSAuthError) -> POSStaff {
        guard !isAuthenticating, !Task.isCancelled else { throw .unknown }
        isAuthenticating = true
        defer { isAuthenticating = false }

        try requireCurrent(token)
        let previous = try advancedRecord()
        try throwIfWaiting(previous)
        try recordFailureBeforeComparing(previous)

        let staff: POSStaff
        do {
            staff = try await authenticator.authenticate(withPIN: pin)
        } catch {
            try requireCurrentAndNotCancelled(token)
            switch error {
            case .unknown:
                try replace(with: previous)
                throw error
            case .invalidPIN:
                throw waitError(fallback: .invalidPIN)
            default:
                throw error
            }
        }

        try requireCurrentAndNotCancelled(token)
        if let requiredCapability, !staff.hasCapability(requiredCapability) {
            throw waitError(fallback: .invalidPIN)
        }
        try replace(with: staff.hasCapability(.manageStoreSettings) ? AttemptRecord() : previous)
        return staff
    }
}

private extension POSLocalRateLimiter {
    struct AttemptRecord: Codable, Sendable {
        static let longestWait: TimeInterval = 3600
        static let quietResetPeriod: TimeInterval = 86400

        var failures = 0
        var wait: TimeInterval = 0
        var quiet: TimeInterval = 0

        var isValid: Bool {
            failures >= 0 && (0...Self.longestWait).contains(wait) && (0...Self.quietResetPeriod).contains(quiet)
        }

        var hasProgress: Bool {
            failures > 0 || wait > 0
        }

        func addingFailure() -> AttemptRecord {
            let failures = failures < .max ? failures + 1 : failures
            return AttemptRecord(failures: failures, wait: Self.wait(afterFailures: failures))
        }

        func advanced(by elapsed: TimeInterval) -> AttemptRecord {
            var next = self
            next.wait = max(0, wait - elapsed)
            guard failures > 0 else {
                return next
            }
            next.quiet = min(Self.quietResetPeriod, quiet + elapsed)
            return next.quiet < Self.quietResetPeriod ? next : AttemptRecord()
        }

        private static func wait(afterFailures failures: Int) -> TimeInterval {
            switch failures {
            case 5: 30
            case 10: 300
            case 15: 1800
            case let failures where failures.isMultiple(of: 5): longestWait
            default: 0
            }
        }
    }

    func requireCurrent(_ token: POSPINSessionTokens.Token) throws(POSAuthError) {
        guard sessionTokens.isCurrent(token) else { throw .unknown }
    }

    func requireCurrentAndNotCancelled(_ token: POSPINSessionTokens.Token) throws(POSAuthError) {
        guard sessionTokens.isCurrent(token), !Task.isCancelled else { throw .unknown }
    }

    func throwIfWaiting(_ record: AttemptRecord) throws(POSAuthError) {
        if record.wait > 0 {
            throw .rateLimited(remainingSeconds: Int(record.wait.rounded(.up)))
        }
    }

    func waitError(fallback: POSAuthError) -> POSAuthError {
        guard let wait = record?.wait, wait > 0 else { return fallback }
        return .rateLimited(remainingSeconds: Int(wait.rounded(.up)))
    }

    func recordFailureBeforeComparing(_ record: AttemptRecord) throws(POSAuthError) {
        try replace(with: record.addingFailure())
    }

    func advancedRecord() throws(POSAuthError) -> AttemptRecord {
        let now = try time()
        guard let record, let lastTick else {
            let loaded = try load()
            self.record = loaded
            self.lastTick = now
            return loaded
        }
        let advanced = record.advanced(by: now - lastTick)
        let waitEnded = record.wait > 0 && advanced.wait == 0
        let quietPeriodEnded = record.failures > 0 && advanced.failures == 0
        if waitEnded || quietPeriodEnded {
            try save(advanced)
        }
        self.record = advanced
        self.lastTick = now
        return advanced
    }

    func replace(with record: AttemptRecord) throws(POSAuthError) {
        let now = try time()
        try save(record)
        self.record = record
        self.lastTick = now
    }

    func time() throws(POSAuthError) -> TimeInterval {
        let now: TimeInterval
        do {
            now = try clock.now()
        } catch {
            throw .unknown
        }
        guard now.isFinite, now >= 0, now >= (lastTick ?? 0) else {
            throw .unknown
        }
        return now
    }

    func save(_ record: AttemptRecord) throws(POSAuthError) {
        do {
            try storage.setData(JSONEncoder().encode(record), forKey: key)
        } catch {
            self.record = nil
            self.lastTick = nil
            DDLogError("POS PIN attempt state could not be saved (error type: \(type(of: error)))")
            throw .unknown
        }
    }

    func load() throws(POSAuthError) -> AttemptRecord {
        let data: Data?
        do {
            data = try storage.data(forKey: key)
        } catch {
            DDLogError("POS PIN attempt state could not be read (error type: \(type(of: error)))")
            throw .unknown
        }
        guard let data else {
            return AttemptRecord()
        }
        let record: AttemptRecord
        do {
            record = try JSONDecoder().decode(AttemptRecord.self, from: data)
        } catch {
            DDLogError("POS PIN attempt state could not be decoded (error type: \(type(of: error)))")
            throw .unknown
        }
        guard record.isValid else {
            DDLogError("POS PIN attempt state is out of range")
            throw .unknown
        }
        return record
    }
}
