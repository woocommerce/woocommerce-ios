import Foundation
@testable import Hardware

/// Supports tests for ReceiptPrinterService.
final class MockPrinterDiscoveryService: PrinterDiscoveryService {
    // Configuration
    var devicesToDiscover: [PrinterDevice] = []
    var discoveryError: Error?
    var connectError: Error?

    // Spy properties
    private(set) var discoverWasCalled = false
    private(set) var stopDiscoveryWasCalled = false
    private(set) var connectedDevice: PrinterDevice?
    private(set) var disconnectWasCalled = false

    private(set) var connectionStatus: PrinterConnectionStatus = .idle
    private var statusObservers: [AsyncStream<PrinterConnectionStatus>.Continuation] = []

    /// Updates the current status and forwards it to every active `connectionStatusUpdates()` stream.
    func emitConnectionStatus(_ status: PrinterConnectionStatus) {
        connectionStatus = status
        for continuation in statusObservers {
            continuation.yield(status)
        }
    }

    func connectionStatusUpdates() -> AsyncStream<PrinterConnectionStatus> {
        AsyncStream { continuation in
            continuation.yield(connectionStatus)
            statusObservers.append(continuation)
        }
    }

    func discover() -> AsyncThrowingStream<PrinterDevice, Error> {
        discoverWasCalled = true
        return AsyncThrowingStream { continuation in
            if let discoveryError {
                continuation.finish(throwing: discoveryError)
                return
            }
            for device in devicesToDiscover {
                continuation.yield(device)
            }
            continuation.finish()
        }
    }

    func stopDiscovery() async {
        stopDiscoveryWasCalled = true
    }

    func connect(to device: PrinterDevice) async throws {
        connectedDevice = device
        if let connectError {
            throw connectError
        }
    }

    func disconnect() async {
        disconnectWasCalled = true
    }
}
