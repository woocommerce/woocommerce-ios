import Testing
import Foundation
import Observation
import struct Yosemite.PrinterDevice
import enum WooFoundation.BluetoothAuthorization
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct POSPrinterConnectionControllerTests {
    @Test func test_startDiscovery_when_multiple_devices_found_then_state_is_foundMultiple() async {
        // Given
        let device1 = PrinterDevice(id: "1", name: "Star TSP100")
        let device2 = PrinterDevice(id: "2", name: "Star mC-Print3")
        let service = MockReceiptPrinterService()
        service.discoveredDevices = [device1, device2]
        let sut = await makeSubscribedController(service: service)

        // When
        sut.startDiscovery()
        await wait(on: sut, until: { sut.discoveryState == .foundMultiple([device1, device2]) })

        // Then
        #expect(sut.discoveryState == .foundMultiple([device1, device2]))
    }

    @Test func test_startDiscovery_when_one_device_found_then_state_is_foundOne() async {
        // Given
        let device = PrinterDevice(id: "1", name: "Star TSP100")
        let service = MockReceiptPrinterService()
        service.discoveredDevices = [device]
        let sut = await makeSubscribedController(service: service)

        // When
        sut.startDiscovery()
        await wait(on: sut, until: { sut.discoveryState == .foundOne(device) })

        // Then
        #expect(sut.discoveryState == .foundOne(device))
    }

    @Test func test_startDiscovery_when_same_id_emitted_with_different_name_then_stays_foundOne() async {
        // Given
        // The same physical printer can be re-emitted with a display-normalized name; it must be
        // de-duped by id so the flow does not flip to the multiple-printers list.
        let device = PrinterDevice(id: "1", name: "Star TSP100")
        let renamed = PrinterDevice(id: "1", name: "Star TSP100 (2)")
        let service = MockReceiptPrinterService()
        service.discoveredDevices = [device, renamed]
        let sut = await makeSubscribedController(service: service)

        // When
        sut.startDiscovery()
        await wait(on: sut, until: { !sut.isDiscovering })

        // Then
        #expect(sut.discoveryState == .foundOne(device))
    }

    @Test func test_startDiscovery_when_no_devices_found_then_state_is_noPrintersFound() async {
        // Given
        let service = MockReceiptPrinterService()
        let sut = await makeSubscribedController(service: service)

        // When
        sut.startDiscovery()
        await wait(on: sut, until: { sut.discoveryState == .noPrintersFound })

        // Then
        #expect(sut.discoveryState == .noPrintersFound)
    }

    @Test func test_keepSearching_when_skipping_a_device_then_it_is_excluded_from_the_next_scan() async {
        // Given
        let device1 = PrinterDevice(id: "1", name: "Star TSP100")
        let device2 = PrinterDevice(id: "2", name: "Star mC-Print3")
        let service = MockReceiptPrinterService()
        service.discoveredDevices = [device1, device2]
        let sut = await makeSubscribedController(service: service)
        sut.startDiscovery()
        await wait(on: sut, until: { sut.discoveryState == .foundMultiple([device1, device2]) })

        // When
        sut.keepSearching(skipping: device1)
        await wait(on: sut, until: { sut.discoveryState == .foundOne(device2) })

        // Then
        #expect(sut.discoveryState == .foundOne(device2))
    }

    @Test func test_startDiscovery_when_discover_fails_then_state_is_discoveryFailed() async {
        // Given
        let service = MockReceiptPrinterService()
        service.discoverError = PrinterTestError()
        let sut = await makeSubscribedController(service: service)

        // When
        sut.startDiscovery()
        await wait(on: sut, until: { sut.discoveryState == .discoveryFailed })

        // Then
        #expect(sut.discoveryState == .discoveryFailed)
    }

    @Test func test_connect_when_succeeds_then_isConnected_and_name_are_set() async {
        // Given
        let device = PrinterDevice(id: "1", name: "Star TSP100")
        let service = MockReceiptPrinterService()
        let sut = await makeSubscribedController(service: service)

        // When
        sut.connect(to: device)
        await wait(on: sut, until: { sut.isConnected && sut.connectedPrinterName == device.name })

        // Then
        #expect(sut.isConnected)
        #expect(sut.connectedPrinterName == device.name)
        #expect(service.connectedDevices == [device])
    }

    @Test func test_connect_when_fails_then_state_is_error_and_not_connected() async {
        // Given
        let device = PrinterDevice(id: "1", name: "Star TSP100")
        let service = MockReceiptPrinterService()
        service.connectError = PrinterTestError()
        let sut = await makeSubscribedController(service: service)

        // When
        sut.connect(to: device)
        await wait(on: sut, until: { sut.discoveryState == .error })

        // Then
        #expect(sut.discoveryState == .error)
        #expect(!sut.isConnected)
        #expect(sut.connectedPrinterName == nil)
    }

    @Test func test_controller_when_released_then_deallocates_without_leaking_via_status_observation() async {
        // Given
        let service = MockReceiptPrinterService()
        weak var weakController: POSPrinterConnectionController?

        // When
        do {
            let controller = await makeSubscribedController(service: service)
            weakController = controller
        }

        // Then
        // The connection-status observation must not retain the controller, otherwise its
        // deinit (and the task cancellation within) never runs.
        #expect(weakController == nil)
    }

    @Test func test_controller_when_released_during_connect_then_deallocates_without_leaking() async {
        // Given
        let device = PrinterDevice(id: "1", name: "Star TSP100")
        let service = MockReceiptPrinterService()
        service.parkConnect = true
        weak var weakController: POSPrinterConnectionController?

        // When
        do {
            let controller = await makeSubscribedController(service: service)
            weakController = controller
            // Suspend until the connect call is genuinely in flight, then let `controller` drop.
            await withCheckedContinuation { continuation in
                service.onConnectSubscribed = {
                    continuation.resume()
                }
                controller.connect(to: device)
            }
        }

        // Then
        // An in-flight connect must not retain the controller, otherwise its deinit (and the task
        // cancellation within) never runs while the SDK call is outstanding.
        #expect(weakController == nil)
    }

    @Test func test_disconnect_when_connected_then_clears_connection() async {
        // Given
        let device = PrinterDevice(id: "1", name: "Star TSP100")
        let service = MockReceiptPrinterService()
        let sut = await makeSubscribedController(service: service)
        sut.connect(to: device)
        await wait(on: sut, until: { sut.isConnected })

        // When
        await sut.disconnect()
        await wait(on: sut, until: { !sut.isConnected })

        // Then
        #expect(!sut.isConnected)
        #expect(sut.connectedPrinterName == nil)
        #expect(service.disconnectCallCount == 1)
    }

    @Test func test_bluetoothAuthorization_when_permission_denied_then_state_is_denied() async {
        // Given
        let service = MockReceiptPrinterService()
        let provider = MockBluetoothAuthorizationProvider(authorization: .denied)

        // When
        let sut = await makeSubscribedController(service: service, bluetoothAuthorizationProvider: provider)

        // Then
        #expect(sut.bluetoothAuthorization == .denied)
    }

    @Test func test_bluetoothAuthorization_when_permission_changes_then_reads_live_value() async {
        // Given
        let service = MockReceiptPrinterService()
        let provider = MockBluetoothAuthorizationProvider(authorization: .denied)
        let sut = await makeSubscribedController(service: service, bluetoothAuthorizationProvider: provider)
        #expect(sut.bluetoothAuthorization == .denied)

        // When
        provider.stubbedAuthorization = .allowed

        // Then
        #expect(sut.bluetoothAuthorization == .allowed)
    }

    @Test(arguments: [BluetoothAuthorization.allowed, .notDetermined])
    func test_startSetup_when_bluetooth_not_denied_then_starts_discovery(authorization: BluetoothAuthorization) async {
        // Given
        let service = MockReceiptPrinterService()
        let provider = MockBluetoothAuthorizationProvider(authorization: authorization)
        let sut = await makeSubscribedController(service: service, bluetoothAuthorizationProvider: provider)

        // When
        sut.startSetup(sessionID: UUID(), source: .settings)

        // Then
        #expect(sut.discoveryState == .searching)
        #expect(sut.isDiscovering)
        await wait(on: sut, until: { !sut.isDiscovering })
        #expect(service.discoverCallCount == 1)
    }

    @Test func test_startSetup_when_printer_found_then_connects_to_it() async {
        // Given
        let device = PrinterDevice(id: "1", name: "Star SM-L200")
        let service = MockReceiptPrinterService()
        service.discoveredDevices = [device]
        let sut = await makeSubscribedController(service: service)

        // When
        sut.startSetup(sessionID: UUID(), source: .settings)
        await wait(on: sut, until: { sut.discoveryState == .foundOne(device) })
        sut.connect(to: device)
        await wait(on: sut, until: { sut.isConnected })

        // Then
        #expect(service.connectedDevices == [device])
        #expect(sut.connectedPrinterName == device.name)
    }

    @Test func test_startSetup_when_no_printers_found_then_state_is_noPrintersFound() async {
        // Given
        let service = MockReceiptPrinterService()
        let sut = await makeSubscribedController(service: service)

        // When
        sut.startSetup(sessionID: UUID(), source: .settings)
        await wait(on: sut, until: { sut.discoveryState == .noPrintersFound })

        // Then
        #expect(sut.discoveryState == .noPrintersFound)
        #expect(!sut.isDiscovering)
    }

    @Test func test_startSetup_when_bluetooth_denied_then_stays_idle_without_discovering() async {
        // Given
        let service = MockReceiptPrinterService()
        let provider = MockBluetoothAuthorizationProvider(authorization: .denied)
        let sut = await makeSubscribedController(service: service, bluetoothAuthorizationProvider: provider)

        // When
        sut.startSetup(sessionID: UUID(), source: .settings)

        // Then
        #expect(sut.discoveryState == .idle)
        #expect(!sut.isDiscovering)
        #expect(service.discoverCallCount == 0)
    }

    @Test func test_startSetup_when_permission_denied_at_prompt_and_nothing_found_then_returns_to_idle() async {
        // Given
        let service = MockReceiptPrinterService()
        let provider = MockBluetoothAuthorizationProvider(authorization: .notDetermined)
        let sut = await makeSubscribedController(service: service, bluetoothAuthorizationProvider: provider)

        // When
        sut.startSetup(sessionID: UUID(), source: .settings)
        provider.stubbedAuthorization = .denied
        await wait(on: sut, until: { !sut.isDiscovering })

        // Then
        #expect(sut.discoveryState == .idle)
    }

    @Test func test_startSetup_when_permission_denied_at_prompt_and_discovery_fails_then_returns_to_idle() async {
        // Given
        let service = MockReceiptPrinterService()
        service.discoverError = PrinterTestError()
        let provider = MockBluetoothAuthorizationProvider(authorization: .notDetermined)
        let sut = await makeSubscribedController(service: service, bluetoothAuthorizationProvider: provider)

        // When
        sut.startSetup(sessionID: UUID(), source: .settings)
        provider.stubbedAuthorization = .denied
        await wait(on: sut, until: { !sut.isDiscovering })

        // Then
        #expect(sut.discoveryState == .idle)
    }

    @Test func test_startSetup_when_called_again_for_same_session_then_does_not_restart_discovery() async {
        // Given
        let device = PrinterDevice(id: "1", name: "Star SM-L200")
        let service = MockReceiptPrinterService()
        service.discoveredDevices = [device]
        let sut = await makeSubscribedController(service: service)
        let sessionID = UUID()
        sut.startSetup(sessionID: sessionID, source: .settings)
        await wait(on: sut, until: { sut.discoveryState == .foundOne(device) && !sut.isDiscovering })

        // When
        sut.startSetup(sessionID: sessionID, source: .settings)

        // Then
        #expect(sut.discoveryState == .foundOne(device))
        #expect(service.discoverCallCount == 1)
    }

    @Test func test_cancelSetup_when_session_is_current_then_cancels_the_scan_and_resets_to_idle() async {
        // Given
        let device = PrinterDevice(id: "1", name: "Star SM-L200")
        let service = MockReceiptPrinterService()
        service.discoveredDevices = [device]
        service.keepsDiscoveryOpen = true
        let sut = await makeSubscribedController(service: service)
        let sessionID = UUID()
        sut.startSetup(sessionID: sessionID, source: .settings)
        await wait(on: sut, until: { sut.discoveryState == .foundOne(device) })

        // When
        await withCheckedContinuation { continuation in
            service.onDiscoveryTerminated = {
                continuation.resume()
            }
            sut.cancelSetup(sessionID: sessionID)
        }

        // Then
        #expect(sut.discoveryState == .idle)
        #expect(!sut.isDiscovering)
        #expect(service.stopDiscoveryCallCount == 0)
    }

    @Test func test_startSetup_when_called_after_cancelSetup_then_searches_again() async {
        // Given
        let service = MockReceiptPrinterService()
        let sut = await makeSubscribedController(service: service)
        let firstSessionID = UUID()
        sut.startSetup(sessionID: firstSessionID, source: .settings)
        await wait(on: sut, until: { sut.discoveryState == .noPrintersFound })
        sut.cancelSetup(sessionID: firstSessionID)

        // When
        sut.startSetup(sessionID: UUID(), source: .settings)
        await wait(on: sut, until: { sut.discoveryState == .noPrintersFound })

        // Then
        #expect(service.discoverCallCount == 2)
    }

    @Test func test_cancelSetup_when_modal_reopened_before_previous_teardown_then_new_scan_keeps_running() async {
        // Given
        let device = PrinterDevice(id: "1", name: "Star SM-L200")
        let service = MockReceiptPrinterService()
        service.discoveredDevices = [device]
        service.keepsDiscoveryOpen = true
        let sut = await makeSubscribedController(service: service)
        let closedSessionID = UUID()
        sut.startSetup(sessionID: closedSessionID, source: .settings)
        await wait(on: sut, until: { sut.discoveryState == .foundOne(device) })
        sut.startSetup(sessionID: UUID(), source: .settings)
        await wait(on: sut, until: { sut.discoveryState == .foundOne(device) })

        // When
        sut.cancelSetup(sessionID: closedSessionID)

        // Then
        #expect(sut.discoveryState == .foundOne(device))
        #expect(sut.isDiscovering)
        #expect(service.discoverCallCount == 2)
        #expect(service.stopDiscoveryCallCount == 0)
    }

    // MARK: - Analytics

    @Test(arguments: [POSPrinterSetupSource.settings, .printReceipt])
    func test_startSetup_then_tracks_setup_started_with_source(source: POSPrinterSetupSource) async {
        // Given
        let analytics = MockPOSAnalytics()
        let sut = await makeSubscribedController(service: MockReceiptPrinterService(), analytics: analytics)

        // When
        sut.startSetup(sessionID: UUID(), source: source)

        // Then
        #expect(analytics.events.map(\.eventName) == ["receipt_printer_setup_started"])
        #expect(analytics.events.first?.properties["source"] as? String == source.rawValue)
    }

    @Test func test_startSetup_when_called_again_for_same_session_then_tracks_setup_started_once() async {
        // Given
        let analytics = MockPOSAnalytics()
        let sut = await makeSubscribedController(service: MockReceiptPrinterService(), analytics: analytics)
        let sessionID = UUID()

        // When
        sut.startSetup(sessionID: sessionID, source: .settings)
        sut.startSetup(sessionID: sessionID, source: .settings)

        // Then
        #expect(analytics.events.map(\.eventName) == ["receipt_printer_setup_started"])
    }

    @Test func test_connect_when_setup_is_open_then_tracks_connected_and_setup_completed_with_source() async {
        // Given
        let device = PrinterDevice(id: "1", name: "Star TSP100")
        let analytics = MockPOSAnalytics()
        let sut = await makeSubscribedController(service: MockReceiptPrinterService(), analytics: analytics)
        sut.startSetup(sessionID: UUID(), source: .printReceipt)

        // When
        sut.connect(to: device)
        await wait(on: sut, until: { sut.isConnected })

        // Then
        #expect(analytics.events.map(\.eventName) == ["receipt_printer_setup_started",
                                                      "receipt_printer_connected",
                                                      "receipt_printer_setup_completed"])
        #expect(analytics.events.last?.properties["source"] as? String == "print_receipt")
    }

    @Test func test_connect_when_setup_was_cancelled_then_tracks_connected_without_setup_completed() async {
        // Given
        let device = PrinterDevice(id: "1", name: "Star TSP100")
        let analytics = MockPOSAnalytics()
        let service = MockReceiptPrinterService()
        let sut = await makeSubscribedController(service: service, analytics: analytics)
        let sessionID = UUID()
        sut.startSetup(sessionID: sessionID, source: .settings)
        sut.cancelSetup(sessionID: sessionID)

        // When
        service.emitConnectionStatus(.connected(device))
        await wait(on: sut, until: { sut.isConnected })

        // Then
        #expect(analytics.events.map(\.eventName) == ["receipt_printer_setup_started", "receipt_printer_connected"])
    }

    @Test func test_connect_when_it_completes_after_setup_reopened_then_does_not_complete_the_new_session() async {
        // Given
        let device = PrinterDevice(id: "1", name: "Star TSP100")
        let analytics = MockPOSAnalytics()
        let service = MockReceiptPrinterService()
        service.parkConnect = true
        let sut = await makeSubscribedController(service: service, analytics: analytics)
        let settingsSessionID = UUID()
        sut.startSetup(sessionID: settingsSessionID, source: .settings)
        await withCheckedContinuation { continuation in
            service.onConnectSubscribed = {
                continuation.resume()
            }
            sut.connect(to: device)
        }
        sut.cancelSetup(sessionID: settingsSessionID)
        sut.startSetup(sessionID: UUID(), source: .printReceipt)

        // When — the connect started from Settings finishes inside the Print receipt session.
        service.emitConnectionStatus(.connected(device))
        await wait(on: sut, until: { sut.isConnected })

        // Then
        #expect(analytics.events.map(\.eventName) == ["receipt_printer_setup_started",
                                                      "receipt_printer_setup_started",
                                                      "receipt_printer_connected"])
    }

    @Test func test_connect_when_fails_then_does_not_track_connected() async {
        // Given
        let device = PrinterDevice(id: "1", name: "Star TSP100")
        let analytics = MockPOSAnalytics()
        let service = MockReceiptPrinterService()
        service.connectError = PrinterTestError()
        let sut = await makeSubscribedController(service: service, analytics: analytics)

        // When
        sut.connect(to: device)
        await wait(on: sut, until: { sut.discoveryState == .error })

        // Then
        #expect(analytics.events.isEmpty)
    }

    @Test func test_disconnect_when_connected_then_tracks_disconnected() async {
        // Given
        let device = PrinterDevice(id: "1", name: "Star TSP100")
        let analytics = MockPOSAnalytics()
        let sut = await makeSubscribedController(service: MockReceiptPrinterService(), analytics: analytics)
        sut.connect(to: device)
        await wait(on: sut, until: { sut.isConnected })

        // When
        await sut.disconnect()
        await wait(on: sut, until: { !sut.isConnected })

        // Then
        #expect(analytics.events.map(\.eventName) == ["receipt_printer_connected", "receipt_printer_disconnected"])
    }

    @Test func test_connection_status_when_replayed_on_subscribe_then_does_not_track_connected() async {
        // Given
        let device = PrinterDevice(id: "1", name: "Star TSP100")
        let analytics = MockPOSAnalytics()
        let service = MockReceiptPrinterService()
        service.emitConnectionStatus(.connected(device))

        // When
        let sut = await makeSubscribedController(service: service, analytics: analytics)
        await wait(on: sut, until: { sut.isConnected })

        // Then
        #expect(analytics.events.isEmpty)
    }
}

// MARK: - Helpers
private extension POSPrinterConnectionControllerTests {
    struct PrinterTestError: Error {}

    /// Builds a controller and waits until its connection-status observation has subscribed, so
    /// statuses emitted afterwards are guaranteed to reach it. The subscription runs in a `Task`
    /// spawned during `init`, which only executes once this method suspends — so setting the hook
    /// right after construction reliably catches it.
    func makeSubscribedController(
        service: MockReceiptPrinterService,
        analytics: MockPOSAnalytics = MockPOSAnalytics(),
        bluetoothAuthorizationProvider: MockBluetoothAuthorizationProvider = MockBluetoothAuthorizationProvider()
    ) async -> POSPrinterConnectionController {
        let controller = POSPrinterConnectionController(service: service,
                                                        analytics: analytics,
                                                        bluetoothAuthorizationProvider: bluetoothAuthorizationProvider)
        await withCheckedContinuation { continuation in
            service.onConnectionStatusSubscribed = {
                continuation.resume()
            }
        }
        return controller
    }

    /// Suspends until `condition` holds, re-arming observation after each change to the controller's
    /// observable state. Deterministic on `@MainActor`: mutations only run while this is suspended.
    func wait(on controller: POSPrinterConnectionController,
              until condition: @escaping @MainActor () -> Bool) async {
        while !condition() {
            await withCheckedContinuation { continuation in
                withObservationTracking {
                    _ = controller.discoveryState
                    _ = controller.isConnected
                    _ = controller.connectedPrinter
                    _ = controller.isDiscovering
                } onChange: {
                    Task { @MainActor in
                        continuation.resume()
                    }
                }
            }
        }
    }
}
