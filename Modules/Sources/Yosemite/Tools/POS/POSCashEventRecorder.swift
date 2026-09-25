import Foundation
import Observation

/// Keeps cash events until Core acknowledges them. Retrying never changes their session or request ID.
@MainActor
@Observable
public final class POSCashEventRecorder {
    private struct Scope: Hashable {
        let siteID: Int64
        let deviceID: String
    }

    private struct WeakRecorder {
        weak var value: POSCashEventRecorder?
    }

    private static var sharedRecorders: [Scope: WeakRecorder] = [:]

    public private(set) var pendingEvents: [POSCashEvent] = []
    public private(set) var isRetrying = false
    public private(set) var lastError: Error?
    public private(set) var journalError: Error?

    public var hasPendingEvents: Bool { !pendingEvents.isEmpty || journalError != nil }

    @ObservationIgnored private let journal: POSCashEventJournal
    @ObservationIgnored private var record: @MainActor (POSCashEvent) async throws -> Void
    @ObservationIgnored private var hasLoadedJournal = false

    public init(journal: POSCashEventJournal, record: @escaping @MainActor (POSCashEvent) async throws -> Void) {
        self.journal = journal
        self.record = record
        do {
            try loadJournalIfNeeded()
        } catch {
            journalError = error
        }
    }

    /// POS can be reopened while a previous replay is in flight. Keep one queue owner per file.
    public static func shared(siteID: Int64, deviceID: String, journal: POSCashEventJournal? = nil,
                              record: @escaping @MainActor (POSCashEvent) async throws -> Void) -> POSCashEventRecorder {
        let scope = Scope(siteID: siteID, deviceID: deviceID)
        if let recorder = sharedRecorders[scope]?.value {
            recorder.record = record
            return recorder
        }
        let recorder = POSCashEventRecorder(journal: journal ?? POSCashEventFileJournal(siteID: siteID, deviceID: deviceID), record: record)
        sharedRecorders = sharedRecorders.filter { $0.value.value != nil }
        sharedRecorders[scope] = WeakRecorder(value: recorder)
        return recorder
    }

    /// Checks persistence before committing a payment or refund.
    public func prepare() throws {
        do {
            try loadJournalIfNeeded()
            try journal.save(pendingEvents)
            journalError = nil
        } catch {
            journalError = error
            throw error
        }
    }

    /// Runs synchronously after the cash transaction succeeds and before the success UI is shown.
    @discardableResult
    public func enqueue(siteID: Int64, sessionID: Int64, source: POSCashEvent.Source) throws -> POSCashEvent {
        try loadJournalIfNeeded()
        if let existing = pendingEvents.first(where: { $0.siteID == siteID && $0.source == source }) {
            try prepare()
            return existing
        }
        let event = POSCashEvent(requestID: UUID(), siteID: siteID, sessionID: sessionID, source: source)
        // Keep the event in memory too if disk persistence fails, so close stays blocked and retry can save it.
        pendingEvents.append(event)
        try prepare()
        return event
    }

    /// Attempts each pending event once. Network and persistence failures remain visible for a later retry.
    public func retry() async {
        guard !isRetrying else { return }
        isRetrying = true
        defer { isRetrying = false }
        lastError = nil
        do {
            try prepare()
        } catch {
            lastError = error
            return
        }

        var attempted: Set<UUID> = []
        while !Task.isCancelled, let event = pendingEvents.first(where: { !attempted.contains($0.requestID) }) {
            attempted.insert(event.requestID)
            do {
                do {
                    try await record(event)
                } catch let error as POSCashSessionAPIError where
                    error.code == "woocommerce_rest_cash_source_already_recorded" && error.recordedSessionID == event.sessionID {
                    // A previous request recorded this source in the same session.
                }
                let remaining = pendingEvents.filter { $0.requestID != event.requestID }
                try journal.save(remaining)
                pendingEvents = remaining
                journalError = nil
            } catch {
                lastError = error
            }
        }
    }

    private func loadJournalIfNeeded() throws {
        guard !hasLoadedJournal else { return }
        pendingEvents = try journal.load()
        hasLoadedJournal = true
    }
}
