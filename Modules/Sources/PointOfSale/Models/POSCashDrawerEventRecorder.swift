import Foundation

/// A drawer event waiting for Core to acknowledge it. The request ID stays fixed across retries.
struct POSPendingCashDrawerEvent: Codable, Equatable {
    let sessionID: Int64
    let requestID: UUID
    let outcome: String
    let reason: String
    let orderID: Int64?
    let occurredAt: Date
    let correlationID: UUID?

    init(event: POSCashDrawerEventRecord, sessionID: Int64) {
        self.sessionID = sessionID
        self.requestID = event.requestID
        self.outcome = switch event.outcome {
        case .openRequested: "open_requested"
        case .opened: "opened"
        case .openFailed: "open_failed"
        }
        self.reason = switch event.reason {
        case .cashSale: "cash_sale"
        case .cashRefund: "cash_refund"
        case .noSale: "no_sale"
        case .test: "test"
        case .count: "count"
        case .unknown: "unknown"
        }
        self.orderID = event.orderID
        self.occurredAt = event.occurredAt
        self.correlationID = event.correlationID
    }

    var event: POSCashDrawerEventRecord? {
        let resolvedOutcome: POSCashDrawerEventRecord.Outcome
        switch outcome {
        case "open_requested": resolvedOutcome = .openRequested
        case "opened": resolvedOutcome = .opened
        case "open_failed": resolvedOutcome = .openFailed
        default: return nil
        }
        let resolvedReason: POSCashDrawerEventRecord.Reason
        switch reason {
        case "cash_sale": resolvedReason = .cashSale
        case "cash_refund": resolvedReason = .cashRefund
        case "no_sale": resolvedReason = .noSale
        case "test": resolvedReason = .test
        case "count": resolvedReason = .count
        case "unknown": resolvedReason = .unknown
        default: return nil
        }
        return POSCashDrawerEventRecord(outcome: resolvedOutcome, reason: resolvedReason, orderID: orderID,
                                        occurredAt: occurredAt, correlationID: correlationID, requestID: requestID)
    }
}

@MainActor
protocol POSCashDrawerEventJournal {
    func load() throws -> [POSPendingCashDrawerEvent]
    func save(_ events: [POSPendingCashDrawerEvent]) throws
}

/// An atomic, store-scoped queue. A different store can have the same numeric session ID.
@MainActor
final class POSCashDrawerEventFileJournal: POSCashDrawerEventJournal {
    private let fileURL: URL

    init(siteID: Int64, directoryURL: URL = .applicationSupportDirectory) {
        fileURL = directoryURL.appendingPathComponent("POSCashDrawerEvents", isDirectory: true)
            .appendingPathComponent("\(siteID).json")
    }

    func load() throws -> [POSPendingCashDrawerEvent] {
        do {
            return try JSONDecoder().decode([POSPendingCashDrawerEvent].self, from: Data(contentsOf: fileURL))
        } catch CocoaError.fileReadNoSuchFile {
            return []
        }
    }

    func save(_ events: [POSPendingCashDrawerEvent]) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(events).write(to: fileURL, options: .atomic)
    }
}

@MainActor
final class POSCashDrawerEventMemoryJournal: POSCashDrawerEventJournal {
    private var events: [POSPendingCashDrawerEvent] = []

    func load() throws -> [POSPendingCashDrawerEvent] { events }
    func save(_ events: [POSPendingCashDrawerEvent]) throws { self.events = events }
}

/// Sends persisted drawer events without delaying the hardware action or a sale.
@MainActor
final class POSCashDrawerEventRecorder {
    private struct WeakRecorder {
        weak var value: POSCashDrawerEventRecorder?
    }

    private static var sharedRecorders: [Int64: WeakRecorder] = [:]

    private(set) var pendingEvents: [POSPendingCashDrawerEvent] = []
    private(set) var lastError: Error?
    private var isRetrying = false
    private var retryWaiters: [CheckedContinuation<Void, Never>] = []
    private var hasLoadedJournal = false
    private let journal: POSCashDrawerEventJournal
    private var record: @MainActor (POSCashDrawerEventRecord, Int64) async throws -> Void

    init(journal: POSCashDrawerEventJournal,
         record: @escaping @MainActor (POSCashDrawerEventRecord, Int64) async throws -> Void) {
        self.journal = journal
        self.record = record
        do {
            pendingEvents = try journal.load()
            hasLoadedJournal = true
        } catch {
            lastError = error
        }
    }

    static func shared(siteID: Int64,
                       record: @escaping @MainActor (POSCashDrawerEventRecord, Int64) async throws -> Void) -> POSCashDrawerEventRecorder {
        if let recorder = sharedRecorders[siteID]?.value {
            recorder.record = record
            return recorder
        }
        let recorder = POSCashDrawerEventRecorder(journal: POSCashDrawerEventFileJournal(siteID: siteID), record: record)
        sharedRecorders = sharedRecorders.filter { $0.value.value != nil }
        sharedRecorders[siteID] = WeakRecorder(value: recorder)
        return recorder
    }

    func enqueue(_ event: POSCashDrawerEventRecord, sessionID: Int64) {
        do {
            try loadJournalIfNeeded()
        } catch {
            // Keep the new observation in memory. Do not overwrite a queue we could not read.
            pendingEvents.append(POSPendingCashDrawerEvent(event: event, sessionID: sessionID))
            lastError = error
            return
        }
        pendingEvents.append(POSPendingCashDrawerEvent(event: event, sessionID: sessionID))
        do {
            try journal.save(pendingEvents)
        } catch {
            lastError = error
            return
        }
    }

    /// Each call attempts each event once. A later event or a new POS session triggers another pass.
    func retry() async {
        guard !isRetrying else { return }
        isRetrying = true
        defer {
            isRetrying = false
            let waiters = retryWaiters
            retryWaiters.removeAll()
            waiters.forEach { $0.resume() }
        }

        // Do not send an event until it is durable. A replay after a lost response must use its original request ID.
        do {
            try loadJournalIfNeeded()
            try journal.save(pendingEvents)
        } catch {
            lastError = error
            return
        }
        var attempted: Set<UUID> = []
        while !Task.isCancelled, let pending = pendingEvents.first(where: { !attempted.contains($0.requestID) }) {
            attempted.insert(pending.requestID)
            guard let event = pending.event else {
                lastError = POSCashDrawerEventRecorderError.invalidStoredEvent
                continue
            }
            do {
                try await record(event, pending.sessionID)
                let remaining = pendingEvents.filter { $0.requestID != pending.requestID }
                try journal.save(remaining)
                pendingEvents = remaining
                if remaining.isEmpty { lastError = nil }
            } catch {
                lastError = error
            }
        }
    }

    func retryAndWait() async {
        if isRetrying {
            await withCheckedContinuation { retryWaiters.append($0) }
        } else {
            await retry()
        }
    }

    private func loadJournalIfNeeded() throws {
        guard !hasLoadedJournal else { return }
        pendingEvents = try journal.load() + pendingEvents
        hasLoadedJournal = true
    }
}

private enum POSCashDrawerEventRecorderError: Error {
    case invalidStoredEvent
}
