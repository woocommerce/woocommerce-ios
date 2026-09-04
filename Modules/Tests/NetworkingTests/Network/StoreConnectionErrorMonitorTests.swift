import Combine
import Foundation
import Testing
@testable import NetworkingCore

struct StoreConnectionErrorMonitorTests {

    @Test func test_affectedSiteID_when_no_error_was_recorded_then_it_is_nil() {
        // Given
        let monitor = StoreConnectionErrorMonitor()

        // Then
        #expect(monitor.affectedSiteID == nil)
    }

    @Test func test_recordInvalidSignature_then_the_store_becomes_the_affected_one() {
        // Given
        let monitor = StoreConnectionErrorMonitor()

        // When
        monitor.recordInvalidSignature(siteID: 123)

        // Then
        #expect(monitor.affectedSiteID == 123)
    }

    @Test func test_recordSuccessfulConnection_when_the_store_is_affected_then_it_clears_the_error() {
        // Given
        let monitor = StoreConnectionErrorMonitor()
        monitor.recordInvalidSignature(siteID: 123)

        // When
        monitor.recordSuccessfulConnection(siteID: 123)

        // Then
        #expect(monitor.affectedSiteID == nil)
    }

    @Test func test_recordSuccessfulConnection_when_another_store_is_affected_then_the_error_is_kept() {
        // Given
        let monitor = StoreConnectionErrorMonitor()
        monitor.recordInvalidSignature(siteID: 123)

        // When
        monitor.recordSuccessfulConnection(siteID: 456)

        // Then
        #expect(monitor.affectedSiteID == 123)
    }

    @Test func test_recordInvalidSignature_when_another_store_was_affected_then_it_replaces_it() {
        // Given
        let monitor = StoreConnectionErrorMonitor()
        monitor.recordInvalidSignature(siteID: 123)

        // When
        monitor.recordInvalidSignature(siteID: 456)

        // Then
        #expect(monitor.affectedSiteID == 456)
    }

    @MainActor
    @Test func test_affectedSiteIDPublisher_then_it_emits_the_current_value_and_every_change() async {
        // Given
        let monitor = StoreConnectionErrorMonitor()
        var emitted: [Int64?] = []
        let subscription = monitor.affectedSiteIDPublisher.sink { emitted.append($0) }

        // When
        monitor.recordInvalidSignature(siteID: 123)
        monitor.recordSuccessfulConnection(siteID: 123)
        await settle()

        // Then
        #expect(emitted == [nil, 123, nil])
        subscription.cancel()
    }

    /// Delivery is handed to the main queue, so a sink never runs on the thread that wrote the value and
    /// is free to read it back. The time limit is what makes this a failure rather than a hung suite if
    /// that stops being true.
    ///
    @MainActor
    @Test(.timeLimit(.minutes(1)))
    func test_affectedSiteIDPublisher_when_the_sink_reads_the_value_then_it_does_not_deadlock() async {
        // Given
        let monitor = StoreConnectionErrorMonitor()
        var readFromSink: [Int64?] = []
        let subscription = monitor.affectedSiteIDPublisher.sink { _ in
            readFromSink.append(monitor.affectedSiteID)
        }

        // When
        monitor.recordInvalidSignature(siteID: 123)
        await settle()

        // Then
        // Both the initial value and the change are delivered on the main queue, so both sinks run after
        // the write has finished and read the same settled value. What is being pinned is that each read
        // returned at all: against an implementation that announces while holding the write, these would
        // deadlock and the time limit above would fail the test.
        #expect(readFromSink.count == 2)
        #expect(readFromSink.allSatisfy { $0 == 123 })
        subscription.cancel()
    }

    /// Competing outcomes for the same store arrive in parallel all the time. Whichever wins, what the
    /// publisher last announced has to agree with what the read API reports, or the warning can be shown
    /// for a store that is no longer affected.
    ///
    @MainActor
    @Test func test_concurrent_writes_then_the_last_published_value_matches_the_stored_one() async {
        // Given
        let monitor = StoreConnectionErrorMonitor()
        var emitted: [Int64?] = []
        let subscription = monitor.affectedSiteIDPublisher.sink { emitted.append($0) }

        // When
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<50 {
                group.addTask { monitor.recordInvalidSignature(siteID: 123) }
                group.addTask { monitor.recordSuccessfulConnection(siteID: 123) }
            }
        }
        await settle()

        // Then
        #expect(emitted.last == monitor.affectedSiteID)
        subscription.cancel()
    }
}

private extension StoreConnectionErrorMonitorTests {
    /// The publisher delivers on the main queue, so the emission has to run before the assertion does.
    ///
    @MainActor
    func settle() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                continuation.resume()
            }
        }
    }
}
