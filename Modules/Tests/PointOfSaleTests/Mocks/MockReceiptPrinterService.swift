import Combine
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

    @Published var connectionStatus: PrinterConnectionStatus = .idle

    /// Devices emitted by `discover()`.
    var discoveredDevices: [PrinterDevice] = []

    /// Error thrown by `connect(to:)`, if any.
    var connectError: Error?

    /// Error thrown by `printReceipt(...)`, if any.
    var printError: Error?

    // MARK: - Spies

    private(set) var discoverCallCount = 0
    private(set) var stopDiscoveryCallCount = 0
    private(set) var connectedDevices: [PrinterDevice] = []
    private(set) var disconnectCallCount = 0
    private(set) var printedContent: ReceiptContent?
    private(set) var printedStoreInformation: ReceiptStoreInformation?
    private(set) var printedCardDetails: CardPresentTransactionDetails?

    // MARK: - ReceiptPrinterServiceProtocol

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
