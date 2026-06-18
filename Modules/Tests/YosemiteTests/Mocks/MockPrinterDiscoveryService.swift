import Combine
@testable import Hardware

/// Supports tests for ReceiptPrinterStore.
final class MockPrinterDiscoveryService: PrinterDiscoveryService {
    // Configuration
    var devicesToDiscover: [PrinterDevice] = []
    var discoveryError: Error?
    var connectError: Error?
    var printResult: PrintingResult = .success

    // Spy properties
    private(set) var discoverWasCalled = false
    private(set) var stopDiscoveryWasCalled = false
    private(set) var connectedDevice: PrinterDevice?
    private(set) var disconnectWasCalled = false
    private(set) var printedContent: ReceiptContent?
    private(set) var printedStoreInformation: ReceiptStoreInformation?
    private(set) var printedCardDetails: CardPresentTransactionDetails?

    let connectionStatusSubject = CurrentValueSubject<PrinterConnectionStatus, Never>(.idle)
    var connectionStatusPublisher: AnyPublisher<PrinterConnectionStatus, Never> {
        connectionStatusSubject.eraseToAnyPublisher()
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

    func stopDiscovery() {
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

    func printReceipt(content: ReceiptContent,
                      storeInformation: ReceiptStoreInformation,
                      cardDetails: CardPresentTransactionDetails?,
                      completion: @escaping (PrintingResult) -> Void) {
        printedContent = content
        printedStoreInformation = storeInformation
        printedCardDetails = cardDetails
        completion(printResult)
    }
}
