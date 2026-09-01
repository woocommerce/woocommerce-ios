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

    /// The publisher announces changes outside the monitor's lock, so a sink is free to read the value
    /// that woke it. This pins that: holding the lock while sending would deadlock here instead.
    ///
    @MainActor
    @Test func test_affectedSiteIDPublisher_when_the_sink_reads_the_value_then_it_does_not_deadlock() async {
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
        #expect(readFromSink == [nil, 123])
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
