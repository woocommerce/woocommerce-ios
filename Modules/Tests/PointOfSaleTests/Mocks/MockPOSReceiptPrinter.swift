import Combine
import Foundation
@testable import PointOfSale

final class MockPOSReceiptPrinter: POSReceiptPrinterProviding {
    // MARK: - Stubs

    @Published var connectionStatus: PrinterConnectionStatus = .disconnected

    /// Devices emitted by `discover()`.
    var discoveredDevices: [PrinterDevice] = []

    /// Error thrown by `connect(to:)`, if any.
    var connectError: Error?

    // MARK: - Spies

    private(set) var discoverCallCount = 0
    private(set) var stopDiscoveryCallCount = 0
    private(set) var connectedDevices: [PrinterDevice] = []
    private(set) var disconnectCallCount = 0

    // MARK: - POSReceiptPrinterProviding

    var connectionStatusPublisher: AnyPublisher<PrinterConnectionStatus, Never> {
        $connectionStatus.eraseToAnyPublisher()
    }

    func discover() -> AsyncThrowingStream<PrinterDevice, Error> {
        discoverCallCount += 1
        let devices = discoveredDevices
        return AsyncThrowingStream { continuation in
            for device in devices {
                continuation.yield(device)
            }
            continuation.finish()
        }
    }

    func stopDiscovery() {
        stopDiscoveryCallCount += 1
    }

    func connect(to printer: PrinterDevice) async throws {
        connectedDevices.append(printer)
        if let connectError {
            throw connectError
        }
        connectionStatus = .connected
    }

    func disconnect() async {
        disconnectCallCount += 1
        connectionStatus = .disconnected
    }
}
