import Foundation
import struct Yosemite.PrinterDevice
import enum Yosemite.PrinterConnectionStatus
import protocol Yosemite.ReceiptPrinterServiceProtocol
import struct Yosemite.ReceiptContent
import struct Yosemite.ReceiptStoreInformation
import struct Yosemite.CardPresentTransactionDetails
@testable import PointOfSale

final class MockReceiptPrinterService: ReceiptPrinterServiceProtocol {
    // MARK: - Stubs

    private(set) var connectionStatus: PrinterConnectionStatus = .idle
    private var statusObservers: [AsyncStream<PrinterConnectionStatus>.Continuation] = []

    /// Devices emitted by `discover()`.
    var discoveredDevices: [PrinterDevice] = []

    /// Error thrown by the `discover()` stream after emitting `discoveredDevices`, if any.
    var discoverError: Error?

    /// Error thrown by `connect(to:)`, if any.
    var connectError: Error?

    /// Error thrown by `printReceipt(...)`, if any.
    var printError: Error?

    /// Fired when a `connectionStatusUpdates()` stream subscribes, so tests can deterministically
    /// wait for the controller to start observing before emitting statuses.
    var onConnectionStatusSubscribed: (() -> Void)?

    // MARK: - Spies

    private(set) var discoverCallCount = 0
    private(set) var stopDiscoveryCallCount = 0
    private(set) var connectedDevices: [PrinterDevice] = []
    private(set) var disconnectCallCount = 0
    private(set) var printedContent: ReceiptContent?
    private(set) var printedStoreInformation: ReceiptStoreInformation?
    private(set) var printedCardDetails: CardPresentTransactionDetails?

    // MARK: - ReceiptPrinterServiceProtocol

    func connectionStatusUpdates() -> AsyncStream<PrinterConnectionStatus> {
        AsyncStream { continuation in
            continuation.yield(connectionStatus)
            statusObservers.append(continuation)
            onConnectionStatusSubscribed?()
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
        let error = discoverError
        return AsyncThrowingStream { continuation in
            for device in devices {
                continuation.yield(device)
            }
            continuation.finish(throwing: error)
        }
    }

    func stopDiscovery() async {
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

    func printReceipt(content: ReceiptContent,
                      storeInformation: ReceiptStoreInformation,
                      cardDetails: CardPresentTransactionDetails?) async throws {
        printedContent = content
        printedStoreInformation = storeInformation
        printedCardDetails = cardDetails
        if let printError {
            throw printError
        }
    }
}
