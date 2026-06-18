import Testing
import Combine
import YosemiteTestHelpers
@testable import Yosemite
@testable import Storage
@testable import Networking
@testable import Hardware

/// ReceiptPrinterStore Unit Tests
@Suite(.timeLimit(.minutes(5)))
struct ReceiptPrinterStoreTests {
    private let dispatcher: Dispatcher
    private let storageManager: MockStorageManager
    private let network: MockNetwork
    private let printerDiscoveryService: MockPrinterDiscoveryService

    init() {
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
        printerDiscoveryService = MockPrinterDiscoveryService()
    }

    @Test func test_connectionStatusPublisher_hands_back_service_publisher() {
        // Given
        let store = makeStore()
        printerDiscoveryService.connectionStatusSubject.send(.connected)

        // When
        var status: PrinterConnectionStatus?
        var cancellable: AnyCancellable?
        let action = ReceiptPrinterAction.connectionStatusPublisher { publisher in
            cancellable = publisher.sink { status = $0 }
        }
        store.onAction(action)

        // Then
        #expect(status == .connected)
        cancellable?.cancel()
    }

    @Test func test_discover_hands_back_service_stream_yielding_devices() async throws {
        // Given
        let store = makeStore()
        let devices = [PrinterDevice(id: "1", name: "Printer 1"),
                       PrinterDevice(id: "2", name: "Printer 2")]
        printerDiscoveryService.devicesToDiscover = devices

        // When
        var stream: AsyncThrowingStream<PrinterDevice, Error>?
        store.onAction(ReceiptPrinterAction.discover { stream = $0 })

        // Then
        let unwrappedStream = try #require(stream)
        var found: [PrinterDevice] = []
        for try await device in unwrappedStream {
            found.append(device)
        }
        #expect(found == devices)
        #expect(printerDiscoveryService.discoverWasCalled)
    }

    @Test func test_discover_when_service_stream_throws_then_propagates_error() async throws {
        // Given
        let store = makeStore()
        printerDiscoveryService.discoveryError = SampleError.connectionFailed

        // When
        var stream: AsyncThrowingStream<PrinterDevice, Error>?
        store.onAction(ReceiptPrinterAction.discover { stream = $0 })

        // Then
        let unwrappedStream = try #require(stream)
        await #expect(throws: SampleError.connectionFailed) {
            for try await _ in unwrappedStream {}
        }
    }

    @Test func test_stopDiscovery_calls_service() {
        // Given
        let store = makeStore()

        // When
        store.onAction(ReceiptPrinterAction.stopDiscovery)

        // Then
        #expect(printerDiscoveryService.stopDiscoveryWasCalled)
    }

    @Test func test_connect_when_service_succeeds_then_completes_with_success() async {
        // Given
        let store = makeStore()
        let device = PrinterDevice(id: "1", name: "Printer 1")

        // When
        let result: Result<Void, Error> = await withCheckedContinuation { continuation in
            store.onAction(ReceiptPrinterAction.connect(printer: device) { result in
                continuation.resume(returning: result)
            })
        }

        // Then
        #expect(printerDiscoveryService.connectedDevice == device)
        #expect((try? result.get()) != nil)
    }

    @Test func test_connect_when_service_throws_then_completes_with_failure() async {
        // Given
        let store = makeStore()
        printerDiscoveryService.connectError = SampleError.connectionFailed
        let device = PrinterDevice(id: "1", name: "Printer 1")

        // When
        let result: Result<Void, Error> = await withCheckedContinuation { continuation in
            store.onAction(ReceiptPrinterAction.connect(printer: device) { result in
                continuation.resume(returning: result)
            })
        }

        // Then
        #expect(throws: SampleError.connectionFailed) {
            try result.get()
        }
    }

    @Test func test_disconnect_calls_service_and_completes() async {
        // Given
        let store = makeStore()

        // When
        await withCheckedContinuation { continuation in
            store.onAction(ReceiptPrinterAction.disconnect {
                continuation.resume()
            })
        }

        // Then
        #expect(printerDiscoveryService.disconnectWasCalled)
    }

    @Test func test_printReceipt_forwards_arguments_to_service_and_completes_with_result() async {
        // Given
        let store = makeStore()
        let content = ReceiptContent(parameters: .fake(), lineItems: [], cartTotals: [], orderNote: nil)
        let storeInformation = ReceiptStoreInformation.empty

        // When
        let result: PrintingResult = await withCheckedContinuation { continuation in
            store.onAction(ReceiptPrinterAction.printReceipt(content: content,
                                                             storeInformation: storeInformation,
                                                             cardDetails: nil) { result in
                continuation.resume(returning: result)
            })
        }

        // Then
        #expect(printerDiscoveryService.printedContent != nil)
        #expect(printerDiscoveryService.printedStoreInformation == storeInformation)
        #expect(printerDiscoveryService.printedCardDetails == nil)
        if case .success = result {} else {
            Issue.record("Expected a successful print result")
        }
    }
}

private extension ReceiptPrinterStoreTests {
    func makeStore() -> ReceiptPrinterStore {
        ReceiptPrinterStore(dispatcher: dispatcher,
                            storageManager: storageManager,
                            network: network,
                            printerDiscoveryService: printerDiscoveryService)
    }

    enum SampleError: Error, Equatable {
        case connectionFailed
    }
}
