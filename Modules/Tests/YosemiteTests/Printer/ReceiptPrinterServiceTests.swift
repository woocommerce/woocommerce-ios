import Testing
import Combine
import Fakes
@testable import Yosemite
@testable import Hardware

/// ReceiptPrinterService Unit Tests
@Suite(.timeLimit(.minutes(5)))
struct ReceiptPrinterServiceTests {
    private let printerDiscoveryService: MockPrinterDiscoveryService

    init() {
        printerDiscoveryService = MockPrinterDiscoveryService()
    }

    @Test func test_connectionStatusPublisher_forwards_service_publisher() {
        // Given
        let sut = makeService()
        printerDiscoveryService.connectionStatusSubject.send(.connected)

        // When
        var status: PrinterConnectionStatus?
        let cancellable = sut.connectionStatusPublisher.sink { status = $0 }

        // Then
        #expect(status == .connected)
        cancellable.cancel()
    }

    @Test func test_discover_forwards_service_stream_yielding_devices() async throws {
        // Given
        let sut = makeService()
        let devices = [PrinterDevice(id: "1", name: "Printer 1"),
                       PrinterDevice(id: "2", name: "Printer 2")]
        printerDiscoveryService.devicesToDiscover = devices

        // When
        var found: [PrinterDevice] = []
        for try await device in sut.discover() {
            found.append(device)
        }

        // Then
        #expect(found == devices)
        #expect(printerDiscoveryService.discoverWasCalled)
    }

    @Test func test_discover_when_service_stream_throws_then_propagates_error() async throws {
        // Given
        let sut = makeService()
        printerDiscoveryService.discoveryError = SampleError.connectionFailed

        // When / Then
        await #expect(throws: SampleError.connectionFailed) {
            for try await _ in sut.discover() {}
        }
    }

    @Test func test_stopDiscovery_forwards_to_service() {
        // Given
        let sut = makeService()

        // When
        sut.stopDiscovery()

        // Then
        #expect(printerDiscoveryService.stopDiscoveryWasCalled)
    }

    @Test func test_connect_forwards_device_to_service() async throws {
        // Given
        let sut = makeService()
        let device = PrinterDevice(id: "1", name: "Printer 1")

        // When
        try await sut.connect(to: device)

        // Then
        #expect(printerDiscoveryService.connectedDevice == device)
    }

    @Test func test_connect_when_service_throws_then_propagates_error() async {
        // Given
        let sut = makeService()
        printerDiscoveryService.connectError = SampleError.connectionFailed
        let device = PrinterDevice(id: "1", name: "Printer 1")

        // When / Then
        await #expect(throws: SampleError.connectionFailed) {
            try await sut.connect(to: device)
        }
    }

    @Test func test_disconnect_forwards_to_service() async {
        // Given
        let sut = makeService()

        // When
        await sut.disconnect()

        // Then
        #expect(printerDiscoveryService.disconnectWasCalled)
    }

    @Test func test_printReceipt_forwards_arguments_to_service() async throws {
        // Given
        let sut = makeService()
        let content = ReceiptContent(parameters: .fake(), lineItems: [], cartTotals: [], orderNote: nil)
        let storeInformation = ReceiptStoreInformation.empty

        // When
        try await sut.printReceipt(content: content, storeInformation: storeInformation, cardDetails: nil)

        // Then
        #expect(printerDiscoveryService.printedContent != nil)
        #expect(printerDiscoveryService.printedStoreInformation == storeInformation)
        #expect(printerDiscoveryService.printedCardDetails == nil)
    }

    @Test func test_printReceipt_when_service_throws_then_propagates_error() async {
        // Given
        let sut = makeService()
        printerDiscoveryService.printError = SampleError.connectionFailed
        let content = ReceiptContent(parameters: .fake(), lineItems: [], cartTotals: [], orderNote: nil)

        // When / Then
        await #expect(throws: SampleError.connectionFailed) {
            try await sut.printReceipt(content: content, storeInformation: .empty, cardDetails: nil)
        }
    }
}

private extension ReceiptPrinterServiceTests {
    func makeService() -> ReceiptPrinterService {
        ReceiptPrinterService(printerDiscoveryService: printerDiscoveryService)
    }

    enum SampleError: Error, Equatable {
        case connectionFailed
    }
}
