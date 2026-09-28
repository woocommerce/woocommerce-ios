import Foundation
import Testing
@testable import PointOfSale

@MainActor
struct POSCashDrawerEventRecorderTests {
    @Test func test_retry_after_restart_uses_original_request_id_and_session() async throws {
        // Given
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let requestID = UUID()
        let event = POSCashDrawerEventRecord(outcome: .opened, reason: .cashSale, orderID: 21,
                                             occurredAt: Date(timeIntervalSince1970: 1_000),
                                             correlationID: UUID(), requestID: requestID)
        let first = POSCashDrawerEventRecorder(journal: POSCashDrawerEventFileJournal(siteID: 7, directoryURL: directory)) { _, _ in
            throw URLError(.notConnectedToInternet)
        }

        // When
        first.enqueue(event, sessionID: 42)
        await first.retry()
        var replayed: [(POSCashDrawerEventRecord, Int64)] = []
        let restarted = POSCashDrawerEventRecorder(journal: POSCashDrawerEventFileJournal(siteID: 7, directoryURL: directory)) { event, sessionID in
            replayed.append((event, sessionID))
        }
        await restarted.retry()

        // Then
        #expect(first.pendingEvents.count == 1)
        #expect(replayed.count == 1)
        #expect(replayed.first?.0.requestID == requestID)
        #expect(replayed.first?.0.correlationID == event.correlationID)
        #expect(replayed.first?.0.outcome == .opened)
        #expect(replayed.first?.0.reason == .cashSale)
        #expect(replayed.first?.0.orderID == 21)
        #expect(replayed.first?.1 == 42)
        #expect(restarted.pendingEvents.isEmpty)
        #expect(try POSCashDrawerEventFileJournal(siteID: 7, directoryURL: directory).load().isEmpty)
    }

    @Test func test_retry_when_one_event_fails_then_sends_later_events_once() async throws {
        // Given
        let journal = POSCashDrawerEventMemoryJournal()
        let failedID = UUID()
        let savedID = UUID()
        var attempted: [UUID] = []
        let recorder = POSCashDrawerEventRecorder(journal: journal) { event, _ in
            attempted.append(event.requestID)
            if event.requestID == failedID { throw URLError(.cannotConnectToHost) }
        }
        recorder.enqueue(.init(outcome: .openRequested, reason: .noSale, orderID: nil,
                               occurredAt: Date(), requestID: failedID), sessionID: 12)
        recorder.enqueue(.init(outcome: .opened, reason: .unknown, orderID: nil,
                               occurredAt: Date(), requestID: savedID), sessionID: 12)

        // When
        await recorder.retry()

        // Then
        #expect(attempted == [failedID, savedID])
        #expect(recorder.pendingEvents.map(\.requestID) == [failedID])
        #expect(try journal.load().map(\.requestID) == [failedID])
    }

    @Test func test_retry_when_journal_cannot_save_then_does_not_send() async {
        // Given
        let journal = FailingDrawerEventJournal()
        var sends = 0
        let recorder = POSCashDrawerEventRecorder(journal: journal) { _, _ in sends += 1 }
        recorder.enqueue(.init(outcome: .openFailed, reason: .test, orderID: nil,
                               occurredAt: Date()), sessionID: 9)

        // When
        await recorder.retry()

        // Then
        #expect(sends == 0)
        #expect(recorder.pendingEvents.count == 1)
        #expect(recorder.lastError != nil)
    }
}

@MainActor
private final class FailingDrawerEventJournal: POSCashDrawerEventJournal {
    func load() throws -> [POSPendingCashDrawerEvent] { [] }
    func save(_ events: [POSPendingCashDrawerEvent]) throws { throw NSError(domain: "Journal", code: 1) }
}
