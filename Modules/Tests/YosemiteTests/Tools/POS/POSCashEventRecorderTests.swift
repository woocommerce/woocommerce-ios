import Foundation
import Testing
@testable import Yosemite

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSCashEventRecorderTests {
    @Test func test_shared_when_pos_reopens_then_reuses_queue_with_current_transport() async throws {
        // Given
        let journal = MockJournal()
        let deviceID = UUID().uuidString
        let original = POSCashEventRecorder.shared(siteID: 12, deviceID: deviceID, journal: journal) { _ in
            Issue.record("The previous transport must not be used")
        }
        let event = try original.enqueue(siteID: 12, sessionID: 34, source: .sale(orderID: 56))
        var sentEvents: [POSCashEvent] = []

        // When
        let reopened = POSCashEventRecorder.shared(siteID: 12, deviceID: deviceID, journal: journal) { sentEvents.append($0) }
        await reopened.retry()

        // Then
        #expect(original === reopened)
        #expect(sentEvents == [event])
        #expect(!original.hasPendingEvents)
    }

    @Test func test_enqueue_when_recorder_reloads_then_restores_request_id_source_and_original_session() throws {
        // Given
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let journal = POSCashEventFileJournal(siteID: 12, deviceID: "device", directoryURL: directory)
        let recorder = POSCashEventRecorder(journal: journal, record: { _ in })

        // When
        let event = try recorder.enqueue(siteID: 12, sessionID: 34, source: .refund(orderID: 56, refundID: 78))
        let restored = POSCashEventRecorder(journal: journal, record: { _ in })

        // Then
        #expect(restored.pendingEvents == [event])
        #expect(restored.pendingEvents.first?.sessionID == 34)
        #expect(restored.pendingEvents.first?.source == .refund(orderID: 56, refundID: 78))
    }

    @Test func test_retry_when_first_request_fails_then_replays_persisted_uuid_and_session_after_restart() async throws {
        // Given
        let journal = MockJournal()
        var attempts: [POSCashEvent] = []
        let recorder = POSCashEventRecorder(journal: journal) { event in
            attempts.append(event)
            throw TestError.network
        }
        let queued = try recorder.enqueue(siteID: 12, sessionID: 34, source: .sale(orderID: 56))

        // When
        await recorder.retry()
        #expect(recorder.hasPendingEvents)
        let restored = POSCashEventRecorder(journal: journal) { attempts.append($0) }
        await restored.retry()

        // Then
        #expect(attempts == [queued, queued])
        #expect(!restored.hasPendingEvents)
        #expect(try journal.load().isEmpty)
    }

    @Test func test_enqueue_when_same_source_is_pending_then_keeps_original_session_and_request_id() throws {
        // Given
        let recorder = POSCashEventRecorder(journal: MockJournal(), record: { _ in })
        let original = try recorder.enqueue(siteID: 12, sessionID: 34, source: .sale(orderID: 56))

        // When
        let replay = try recorder.enqueue(siteID: 12, sessionID: 99, source: .sale(orderID: 56))

        // Then
        #expect(replay == original)
        #expect(recorder.pendingEvents == [original])
    }

    @Test(arguments: [Int64(34), Int64(99)])
    func test_retry_when_source_already_recorded_then_only_accepts_same_session(recordedSessionID: Int64) async throws {
        // Given
        let journal = MockJournal()
        let recorder = POSCashEventRecorder(journal: journal) { _ in
            throw POSCashSessionAPIError(statusCode: 409, code: "woocommerce_rest_cash_source_already_recorded",
                                          recordedSessionID: recordedSessionID)
        }
        try recorder.enqueue(siteID: 12, sessionID: 34, source: .sale(orderID: 56))

        // When
        await recorder.retry()

        // Then
        #expect(recorder.hasPendingEvents == (recordedSessionID != 34))
        #expect(journal.events.isEmpty == (recordedSessionID == 34))
    }

    @Test func test_prepare_when_journal_cannot_be_read_then_preserves_file_and_blocks_recording() async throws {
        // Given
        let journal = MockJournal()
        journal.loadError = TestError.disk
        var sentEvents = 0
        let recorder = POSCashEventRecorder(journal: journal) { _ in sentEvents += 1 }

        // When
        #expect(throws: TestError.disk) { try recorder.prepare() }
        await recorder.retry()

        // Then
        #expect(recorder.hasPendingEvents)
        #expect(journal.saveCount == 0)
        #expect(sentEvents == 0)
    }

    @Test func test_enqueue_when_journal_write_fails_then_keeps_event_and_retry_persists_it_before_sending() async throws {
        // Given
        let journal = MockJournal()
        let recorder = POSCashEventRecorder(journal: journal) { event in
            #expect(journal.events.contains(event))
        }
        try recorder.prepare()
        journal.saveError = TestError.disk

        // When
        #expect(throws: TestError.disk) {
            try recorder.enqueue(siteID: 12, sessionID: 34, source: .sale(orderID: 56))
        }
        #expect(recorder.hasPendingEvents)
        #expect(recorder.pendingEvents.count == 1)
        journal.saveError = nil
        await recorder.retry()

        // Then
        #expect(!recorder.hasPendingEvents)
        #expect(journal.events.isEmpty)
    }

    @Test func test_retry_when_acknowledgement_cannot_be_saved_then_keeps_original_request_for_safe_replay() async throws {
        // Given
        let journal = MockJournal()
        var attempts: [POSCashEvent] = []
        let recorder = POSCashEventRecorder(journal: journal) { event in
            attempts.append(event)
            journal.saveError = TestError.disk
        }
        let event = try recorder.enqueue(siteID: 12, sessionID: 34, source: .sale(orderID: 56))

        // When
        await recorder.retry()

        // Then
        #expect(attempts == [event])
        #expect(recorder.pendingEvents == [event])
        #expect(journal.events == [event])
    }

    @Test func test_retry_when_another_event_arrives_during_request_then_sends_both_without_overlapping_replay() async throws {
        // Given
        let journal = MockJournal()
        var attempts: [POSCashEvent.Source] = []
        var recorder: POSCashEventRecorder!
        recorder = POSCashEventRecorder(journal: journal) { event in
            attempts.append(event.source)
            if event.source == .sale(orderID: 56) {
                try recorder.enqueue(siteID: 12, sessionID: 34, source: .refund(orderID: 56, refundID: 78))
                await recorder.retry()
            }
        }
        try recorder.enqueue(siteID: 12, sessionID: 34, source: .sale(orderID: 56))

        // When
        await recorder.retry()

        // Then
        #expect(attempts == [.sale(orderID: 56), .refund(orderID: 56, refundID: 78)])
        #expect(!recorder.hasPendingEvents)
    }
}

private extension POSCashEventRecorderTests {
    enum TestError: Error, Equatable { case network, disk }

    final class MockJournal: POSCashEventJournal {
        var events: [POSCashEvent] = []
        var loadError: Error?
        var saveError: Error?
        var saveCount = 0

        func load() throws -> [POSCashEvent] {
            if let loadError { throw loadError }
            return events
        }

        func save(_ events: [POSCashEvent]) throws {
            saveCount += 1
            if let saveError { throw saveError }
            self.events = events
        }
    }
}
