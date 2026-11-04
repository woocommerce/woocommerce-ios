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

    @Test func test_startDiscovery_when_discover_fails_then_state_is_error() async {
        // Given
        let service = MockReceiptPrinterService()
        service.discoverError = PrinterTestError()
        let sut = await makeSubscribedController(service: service)

        // When
        sut.startDiscovery()
        await wait(on: sut, until: { sut.discoveryState == .error })

        // Then
        #expect(sut.discoveryState == .error)
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
        sut.startSetup(sessionID: UUID())

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
        sut.startSetup(sessionID: UUID())
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
        sut.startSetup(sessionID: UUID())
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
        sut.startSetup(sessionID: UUID())

        // Then
        #expect(sut.discoveryState == .idle)
        #expect(!sut.isDiscovering)
        #expect(service.discoverCallCount == 0)
    }

    @Test func test_startSetup_when_called_again_for_same_session_then_does_not_restart_discovery() async {
        // Given
        let device = PrinterDevice(id: "1", name: "Star SM-L200")
        let service = MockReceiptPrinterService()
        service.discoveredDevices = [device]
        let sut = await makeSubscribedController(service: service)
        let sessionID = UUID()
        sut.startSetup(sessionID: sessionID)
        await wait(on: sut, until: { sut.discoveryState == .foundOne(device) && !sut.isDiscovering })

        // When
        sut.startSetup(sessionID: sessionID)

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
        sut.startSetup(sessionID: sessionID)
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
        sut.startSetup(sessionID: firstSessionID)
        await wait(on: sut, until: { sut.discoveryState == .noPrintersFound })
        sut.cancelSetup(sessionID: firstSessionID)

        // When
        sut.startSetup(sessionID: UUID())
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
        sut.startSetup(sessionID: closedSessionID)
        await wait(on: sut, until: { sut.discoveryState == .foundOne(device) })
        sut.startSetup(sessionID: UUID())
        await wait(on: sut, until: { sut.discoveryState == .foundOne(device) })

        // When
        sut.cancelSetup(sessionID: closedSessionID)

        // Then
        #expect(sut.discoveryState == .foundOne(device))
        #expect(sut.isDiscovering)
        #expect(service.discoverCallCount == 2)
        #expect(service.stopDiscoveryCallCount == 0)
    }

    @Test func test_startSetup_when_bluetooth_is_powered_off_then_state_is_bluetoothOff() async {
        // Given
        let service = MockReceiptPrinterService()
        service.keepsDiscoveryOpen = true
        service.emitBluetoothRadioState(.poweredOff)
        let sut = await makeSubscribedController(service: service)

        // When
        sut.startSetup(sessionID: UUID())
        await wait(on: sut, until: { sut.discoveryState == .bluetoothOff })

        // Then
        #expect(sut.discoveryState == .bluetoothOff)
        #expect(!sut.isDiscovering)
    }

    @Test func test_bluetoothRadio_when_turned_off_while_connecting_then_state_is_bluetoothOff() async {
        // Given
        let device = PrinterDevice(id: "1", name: "Star SM-L200")
        let service = MockReceiptPrinterService()
        service.discoveredDevices = [device]
        service.parkConnect = true
        let sut = await makeSubscribedController(service: service)
        await startSetupObservingRadio(sut, service: service)
        await wait(on: sut, until: { sut.discoveryState == .foundOne(device) })
        await withCheckedContinuation { continuation in
            service.onConnectSubscribed = {
                continuation.resume()
            }
            sut.connect(to: device)
        }

        // When
        service.emitBluetoothRadioState(.poweredOff)
        await wait(on: sut, until: { sut.discoveryState == .bluetoothOff })

        // Then
        #expect(sut.discoveryState == .bluetoothOff)
        #expect(service.connectedDevices == [device])
        #expect(!sut.isConnected)
    }

    @Test func test_bluetoothRadio_when_turned_back_on_then_search_resumes() async {
        // Given
        let device = PrinterDevice(id: "1", name: "Star SM-L200")
        let service = MockReceiptPrinterService()
        service.emitBluetoothRadioState(.poweredOff)
        let sut = await makeSubscribedController(service: service)
        sut.startSetup(sessionID: UUID())
        await wait(on: sut, until: { sut.discoveryState == .bluetoothOff })
        service.discoveredDevices = [device]

        // When
        service.emitBluetoothRadioState(.poweredOn)
        await wait(on: sut, until: { sut.discoveryState == .foundOne(device) })

        // Then
        #expect(sut.discoveryState == .foundOne(device))
        #expect(service.discoverCallCount == 2)
    }

    @Test func test_startDiscovery_when_bluetooth_is_still_powered_off_then_stays_bluetoothOff_without_discovering() async {
        // Given
        let service = MockReceiptPrinterService()
        service.emitBluetoothRadioState(.poweredOff)
        let sut = await makeSubscribedController(service: service)
        sut.startSetup(sessionID: UUID())
        await wait(on: sut, until: { sut.discoveryState == .bluetoothOff })
        let discoverCallCount = service.discoverCallCount

        // When
        sut.startDiscovery()

        // Then
        #expect(sut.discoveryState == .bluetoothOff)
        #expect(service.discoverCallCount == discoverCallCount)
    }

    @Test func test_startSetup_when_bluetooth_denied_and_powered_off_then_stays_idle() async {
        // Given
        let service = MockReceiptPrinterService()
        service.emitBluetoothRadioState(.poweredOff)
        let provider = MockBluetoothAuthorizationProvider(authorization: .denied)
        let sut = await makeSubscribedController(service: service, bluetoothAuthorizationProvider: provider)

        // When
        sut.startSetup(sessionID: UUID())

        // Then
        #expect(sut.discoveryState == .idle)
        #expect(service.discoverCallCount == 0)
    }

    @Test func test_startDiscovery_when_permission_granted_after_denied_setup_then_observes_bluetooth_radio() async {
        // Given
        let device = PrinterDevice(id: "1", name: "Star SM-L200")
        let service = MockReceiptPrinterService()
        let provider = MockBluetoothAuthorizationProvider(authorization: .denied)
        let sut = await makeSubscribedController(service: service, bluetoothAuthorizationProvider: provider)
        sut.startSetup(sessionID: UUID())
        provider.stubbedAuthorization = .allowed
        await waitForRadioSubscription(on: service) {
            sut.startDiscovery()
        }

        // When
        service.emitBluetoothRadioState(.poweredOff)
        await wait(on: sut, until: { sut.discoveryState == .bluetoothOff })
        service.discoveredDevices = [device]
        service.emitBluetoothRadioState(.poweredOn)
        await wait(on: sut, until: { sut.discoveryState == .foundOne(device) })

        // Then
        #expect(sut.discoveryState == .foundOne(device))
    }

    @Test func test_bluetoothRadio_when_permission_denied_after_bluetoothOff_then_returns_to_idle() async {
        // Given
        let service = MockReceiptPrinterService()
        let provider = MockBluetoothAuthorizationProvider(authorization: .allowed)
        let sut = await makeSubscribedController(service: service, bluetoothAuthorizationProvider: provider)
        await startSetupObservingRadio(sut, service: service)
        service.emitBluetoothRadioState(.poweredOff)
        await wait(on: sut, until: { sut.discoveryState == .bluetoothOff })

        // When
        provider.stubbedAuthorization = .denied
        service.emitBluetoothRadioState(.unknown)
        await wait(on: sut, until: { sut.discoveryState == .idle })

        // Then
        #expect(sut.discoveryState == .idle)
        #expect(sut.bluetoothAuthorization == .denied)
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
        bluetoothAuthorizationProvider: MockBluetoothAuthorizationProvider = MockBluetoothAuthorizationProvider()
    ) async -> POSPrinterConnectionController {
        let controller = POSPrinterConnectionController(service: service,
                                                        bluetoothAuthorizationProvider: bluetoothAuthorizationProvider)
        await withCheckedContinuation { continuation in
            service.onConnectionStatusSubscribed = {
                continuation.resume()
            }
        }
        return controller
    }

    /// Starts setup and waits until the controller observes the radio, so radio states emitted afterwards reach it.
    func startSetupObservingRadio(_ controller: POSPrinterConnectionController, service: MockReceiptPrinterService) async {
        await waitForRadioSubscription(on: service) {
            controller.startSetup(sessionID: UUID())
        }
    }

    /// Runs `action` and waits until it makes the controller observe the radio.
    func waitForRadioSubscription(on service: MockReceiptPrinterService, after action: () -> Void) async {
        await withCheckedContinuation { continuation in
            service.onBluetoothRadioStateSubscribed = {
                continuation.resume()
            }
            action()
        }
        service.onBluetoothRadioStateSubscribed = nil
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
