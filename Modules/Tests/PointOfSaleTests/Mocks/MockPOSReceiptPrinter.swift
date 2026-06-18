import Combine
import Foundation
import struct Yosemite.ReceiptPrinterDevice
import enum Yosemite.ReceiptPrinterConnectionStatus
@testable import PointOfSale

final class MockPOSReceiptPrinter: POSReceiptPrinterProviding {
    // MARK: - Stubs

    @Published var connectionStatus: ReceiptPrinterConnectionStatus = .idle

    /// Devices emitted by `discover()`.
    var discoveredDevices: [ReceiptPrinterDevice] = []

    /// Error thrown by `connect(to:)`, if any.
    var connectError: Error?

    // MARK: - Spies

    private(set) var discoverCallCount = 0
    private(set) var stopDiscoveryCallCount = 0
    private(set) var connectedDevices: [ReceiptPrinterDevice] = []
    private(set) var disconnectCallCount = 0

    // MARK: - POSReceiptPrinterProviding

    var connectionStatusPublisher: AnyPublisher<ReceiptPrinterConnectionStatus, Never> {
        $connectionStatus.eraseToAnyPublisher()
    }

    func discover() -> AsyncThrowingStream<ReceiptPrinterDevice, Error> {
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

    func connect(to printer: ReceiptPrinterDevice) async throws {
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
