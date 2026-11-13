import Foundation
import struct Yosemite.PrinterDevice
import enum Yosemite.PrinterConnectionStatus
import protocol Yosemite.ReceiptPrinterServiceProtocol
import struct Yosemite.ReceiptContent
import struct Yosemite.ReceiptStoreInformation
import struct Yosemite.CardPresentTransactionDetails
import struct Yosemite.Order
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

    /// When `true`, `connect(to:)` parks (until cancelled) after firing `onConnectSubscribed`, so a
    /// test can release the controller while a connect is in flight.
    var parkConnect = false

    /// Fired when a parked `connect(to:)` call starts waiting, so tests release the controller only
    /// once the connect is genuinely in flight.
    var onConnectSubscribed: (() -> Void)?

    /// When `true`, `connect(to:)` waits, ignoring cancellation like the SDK's connect, until
    /// `finishHeldConnect()` lets it succeed. Fires `onConnectSubscribed` once it is waiting.
    var holdsConnect = false
    private var heldConnect: CheckedContinuation<Void, Never>?

    /// When `true`, `discover()` keeps its stream open after emitting `discoveredDevices`, like a
    /// scan still running, until the consumer cancels it.
    var keepsDiscoveryOpen = false

    /// Emits each time a `discover()` stream terminates, whether it finished or its consumer cancelled it.
    let discoveryTerminations: AsyncStream<Void>
    private let discoveryTerminationsContinuation: AsyncStream<Void>.Continuation

    init() {
        (discoveryTerminations, discoveryTerminationsContinuation) = AsyncStream.makeStream()
    }

    // MARK: - Spies

    private(set) var discoverCallCount = 0
    private(set) var stopDiscoveryCallCount = 0
    private(set) var connectedDevices: [PrinterDevice] = []
    private(set) var disconnectCallCount = 0
    private(set) var printedContent: ReceiptContent?
    private(set) var printedStoreInformation: ReceiptStoreInformation?
    private(set) var printedCardDetails: CardPresentTransactionDetails?
    private(set) var printedOrder: Order?

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
        let keepsOpen = keepsDiscoveryOpen
        let terminations = discoveryTerminationsContinuation
        return AsyncThrowingStream { continuation in
            continuation.onTermination = { _ in
                terminations.yield()
            }
            for device in devices {
                continuation.yield(device)
            }
            if !keepsOpen {
                continuation.finish(throwing: error)
            }
        }
    }

    func stopDiscovery() async {
        stopDiscoveryCallCount += 1
    }

    func connect(to printer: PrinterDevice) async throws {
        connectedDevices.append(printer)
        if connectError == nil {
            emitConnectionStatus(.connecting)
        }
        if holdsConnect {
            await withCheckedContinuation { continuation in
                heldConnect = continuation
                onConnectSubscribed?()
            }
            emitConnectionStatus(.connected(printer))
            return
        }
        if parkConnect {
            // Hold the call open so a test can release the controller mid-connect; cancellation
            // from the controller's deinit unwinds the sleep.
            onConnectSubscribed?()
            try await Task.sleep(nanoseconds: 30_000_000_000)
            return
        }
        if let connectError {
            throw connectError
        }
        emitConnectionStatus(.connected(printer))
    }

    func finishHeldConnect() {
        heldConnect?.resume()
        heldConnect = nil
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

    func printReceipt(order: Order,
                      storeInformation: ReceiptStoreInformation,
                      cardDetails: CardPresentTransactionDetails?) async throws {
        printedOrder = order
        printedStoreInformation = storeInformation
        printedCardDetails = cardDetails
        if let printError {
            throw printError
        }
    }
}
