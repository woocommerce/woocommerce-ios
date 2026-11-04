import Foundation
import struct Yosemite.PrinterDevice
import enum Yosemite.PrinterConnectionStatus
import enum Yosemite.BluetoothRadioState
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

    private(set) var bluetoothRadioState: BluetoothRadioState = .poweredOn
    private var radioStateObservers: [AsyncStream<BluetoothRadioState>.Continuation] = []

    /// Fired when a `bluetoothRadioStateUpdates()` stream subscribes, so tests can wait for the controller
    /// to start observing the radio before changing its state.
    var onBluetoothRadioStateSubscribed: (() -> Void)?

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

    /// When `true`, `discover()` keeps its stream open after emitting `discoveredDevices`, like a
    /// scan still running, until the consumer cancels it.
    var keepsDiscoveryOpen = false

    /// Fired when a `discover()` stream terminates, whether it finished or its consumer cancelled it.
    var onDiscoveryTerminated: (() -> Void)?

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

    func bluetoothRadioStateUpdates() -> AsyncStream<BluetoothRadioState> {
        AsyncStream { continuation in
            continuation.yield(bluetoothRadioState)
            radioStateObservers.append(continuation)
            onBluetoothRadioStateSubscribed?()
        }
    }

    /// Updates the radio state and forwards it to every active `bluetoothRadioStateUpdates()` stream.
    func emitBluetoothRadioState(_ state: BluetoothRadioState) {
        bluetoothRadioState = state
        for continuation in radioStateObservers {
            continuation.yield(state)
        }
    }

    func discover() -> AsyncThrowingStream<PrinterDevice, Error> {
        discoverCallCount += 1
        let devices = discoveredDevices
        let error = discoverError
        let keepsOpen = keepsDiscoveryOpen
        return AsyncThrowingStream { continuation in
            continuation.onTermination = { [weak self] _ in
                self?.onDiscoveryTerminated?()
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
                      storeInformation: ReceiptStoreInformation) async throws {
        printedOrder = order
        printedStoreInformation = storeInformation
        if let printError {
            throw printError
        }
    }
}
