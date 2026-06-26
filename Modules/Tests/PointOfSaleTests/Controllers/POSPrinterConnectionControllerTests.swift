import Testing
import Foundation
import Observation
import struct Yosemite.PrinterDevice
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

    @Test func test_refreshBluetoothAuthorization_when_permission_changes_then_state_updates() async {
        // Given
        let service = MockReceiptPrinterService()
        let provider = MockBluetoothAuthorizationProvider(authorization: .denied)
        let sut = await makeSubscribedController(service: service, bluetoothAuthorizationProvider: provider)
        #expect(sut.bluetoothAuthorization == .denied)

        // When
        provider.stubbedAuthorization = .allowed
        sut.refreshBluetoothAuthorization()

        // Then
        #expect(sut.bluetoothAuthorization == .allowed)
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
