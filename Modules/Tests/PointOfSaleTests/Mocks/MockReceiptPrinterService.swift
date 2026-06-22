import Foundation
import struct Yosemite.PrinterDevice
import enum Yosemite.PrinterConnectionStatus
import protocol Yosemite.ReceiptPrinterServiceProtocol
@testable import PointOfSale

final class MockReceiptPrinterService: ReceiptPrinterServiceProtocol {
    // MARK: - Stubs

    private(set) var connectionStatus: PrinterConnectionStatus = .idle
    private var statusObservers: [AsyncStream<PrinterConnectionStatus>.Continuation] = []

    /// Devices emitted by `discover()`.
    var discoveredDevices: [PrinterDevice] = []

    /// Error thrown by `connect(to:)`, if any.
    var connectError: Error?

    // MARK: - Spies

    private(set) var discoverCallCount = 0
    private(set) var stopDiscoveryCallCount = 0
    private(set) var connectedDevices: [PrinterDevice] = []
    private(set) var disconnectCallCount = 0

    // MARK: - ReceiptPrinterServiceProtocol

    func connectionStatusUpdates() -> AsyncStream<PrinterConnectionStatus> {
        AsyncStream { continuation in
            continuation.yield(connectionStatus)
            statusObservers.append(continuation)
        }
    }

    /// Updates the current status and forwards it to every active `connectionStatusUpdates()` stream.
    func emitConnectionStatus(_ status: PrinterConnectionStatus) {
        connectionStatus = status
        for continuation in statusObservers {
            continuation.yield(status)
        }
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
        emitConnectionStatus(.connected)
    }

    func disconnect() async {
        disconnectCallCount += 1
        emitConnectionStatus(.disconnected)
    }
}
