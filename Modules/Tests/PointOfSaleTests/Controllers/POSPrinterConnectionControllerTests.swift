import Testing
import Foundation
import Observation
import struct Yosemite.PrinterDevice
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSPrinterConnectionControllerTests {
    @Test func test_startDiscovery_when_devices_found_then_state_is_found_with_devices() async {
        // Given
        let device1 = PrinterDevice(id: "1", name: "Star TSP100")
        let device2 = PrinterDevice(id: "2", name: "Star mC-Print3")
        let service = MockReceiptPrinterService()
        service.discoveredDevices = [device1, device2]
        let sut = await makeSubscribedController(service: service)

        // When
        sut.startDiscovery()
        await wait(on: sut, until: { sut.discoveryState == .found([device1, device2]) })

        // Then
        #expect(sut.discoveryState == .found([device1, device2]))
    }

    @Test func test_startDiscovery_when_no_devices_found_then_state_is_found_empty() async {
        // Given
        let service = MockReceiptPrinterService()
        let sut = await makeSubscribedController(service: service)

        // When
        sut.startDiscovery()
        await wait(on: sut, until: { sut.discoveryState == .found([]) })

        // Then
        #expect(sut.discoveryState == .found([]))
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
}

// MARK: - Helpers
private extension POSPrinterConnectionControllerTests {
    struct PrinterTestError: Error {}

    /// Builds a controller and waits until its connection-status observation has subscribed, so
    /// statuses emitted afterwards are guaranteed to reach it. The subscription runs in a `Task`
    /// spawned during `init`, which only executes once this method suspends — so setting the hook
    /// right after construction reliably catches it.
    func makeSubscribedController(service: MockReceiptPrinterService) async -> POSPrinterConnectionController {
        let controller = POSPrinterConnectionController(service: service)
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
                } onChange: {
                    Task { @MainActor in
                        continuation.resume()
                    }
                }
            }
        }
    }
}
