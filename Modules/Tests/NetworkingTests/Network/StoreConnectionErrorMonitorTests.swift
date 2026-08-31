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

    @Test func test_affectedSiteIDPublisher_then_it_emits_the_current_value_and_every_change() async throws {
        // Given
        let monitor = StoreConnectionErrorMonitor()
        var emitted: [Int64?] = []
        let subscription = monitor.affectedSiteIDPublisher.sink { emitted.append($0) }

        // When
        monitor.recordInvalidSignature(siteID: 123)
        monitor.recordSuccessfulConnection(siteID: 123)
        // Reading the value hops through the monitor's queue, so it lands after both writes.
        _ = monitor.affectedSiteID

        // Then
        #expect(emitted == [nil, 123, nil])
        subscription.cancel()
    }
}
