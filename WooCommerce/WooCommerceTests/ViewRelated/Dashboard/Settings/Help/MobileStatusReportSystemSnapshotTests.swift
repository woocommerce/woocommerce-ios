import Testing
@testable import WooCommerce

/// Covers the injected halves of `MobileStatusReportSystemSnapshot.current()` — the connectivity and
/// notification-settings mappings. The remaining fields read live singletons at the boundary.
@MainActor
struct MobileStatusReportSystemSnapshotTests {

    @Test func test_current_when_path_flags_are_known_then_maps_them_to_bool_strings() async {
        // Given
        let connectivity = MockConnectivityObserver()
        connectivity.setStatus(.reachable(type: .cellular))
        connectivity.isConnectionMetered = true
        connectivity.isLowDataModeEnabled = false

        // When
        let snapshot = await MobileStatusReportSystemSnapshot.current(connectivityObserver: connectivity,
                                                                      notificationCenter: MockUserNotificationsCenterAdapter())

        // Then
        #expect(snapshot.networkType == "Cellular")
        #expect(snapshot.meteredConnection == "true")
        #expect(snapshot.lowDataMode == "false")
    }

    @Test func test_current_when_path_flags_never_arrived_then_reports_unknown() async {
        // Given
        let connectivity = MockConnectivityObserver()
        connectivity.isConnectionMetered = nil
        connectivity.isLowDataModeEnabled = nil

        // When
        let snapshot = await MobileStatusReportSystemSnapshot.current(connectivityObserver: connectivity,
                                                                      notificationCenter: MockUserNotificationsCenterAdapter())

        // Then
        #expect(snapshot.networkType == "Unknown")
        #expect(snapshot.meteredConnection == "unknown")
        #expect(snapshot.lowDataMode == "unknown")
    }

    @Test func test_current_when_notifications_authorized_then_maps_status_and_settings() async {
        // Given: the mock's default coder decodes an authorized status and enabled settings.
        let notificationCenter = MockUserNotificationsCenterAdapter()

        // When
        let snapshot = await MobileStatusReportSystemSnapshot.current(connectivityObserver: MockConnectivityObserver(),
                                                                      notificationCenter: notificationCenter)

        // Then
        #expect(snapshot.authorizationStatus == "authorized")
        #expect(snapshot.alerts == "enabled")
        #expect(snapshot.sounds == "enabled")
    }
}
