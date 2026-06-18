import Testing
import Combine
import Yosemite
@testable import WooCommerce

/// POSReceiptPrinterService Unit Tests
@Suite(.timeLimit(.minutes(5)))
struct POSReceiptPrinterServiceTests {
    private let stores: MockStoresManager
    private let sut: POSReceiptPrinterService

    init() {
        stores = MockStoresManager(sessionManager: .makeForTesting())
        sut = POSReceiptPrinterService(stores: stores)
    }

    @Test func test_connectionStatusPublisher_dispatches_action_and_returns_service_publisher() {
        // Given
        let subject = CurrentValueSubject<PrinterConnectionStatus, Never>(.connected)
        stores.whenReceivingAction(ofType: ReceiptPrinterAction.self) { action in
            if case let .connectionStatusPublisher(onPublisher) = action {
                onPublisher(subject.eraseToAnyPublisher())
            }
        }

        // When
        var status: PrinterConnectionStatus?
        let cancellable = sut.connectionStatusPublisher.sink { status = $0 }

        // Then
        #expect(status == .connected)
        cancellable.cancel()
    }

    @Test func test_discover_dispatches_action_and_returns_service_stream() async throws {
        // Given
        let devices = [PrinterDevice(id: "1", name: "Printer 1"),
                       PrinterDevice(id: "2", name: "Printer 2")]
        stores.whenReceivingAction(ofType: ReceiptPrinterAction.self) { action in
            if case let .discover(onStream) = action {
                onStream(AsyncThrowingStream { continuation in
                    devices.forEach { continuation.yield($0) }
                    continuation.finish()
                })
            }
        }

        // When
        var found: [PrinterDevice] = []
        for try await device in sut.discover() {
            found.append(device)
        }

        // Then
        #expect(found == devices)
    }

    @Test func test_stopDiscovery_dispatches_stopDiscovery_action() {
        // When
        sut.stopDiscovery()

        // Then
        let dispatched = stores.receivedActions.compactMap { $0 as? ReceiptPrinterAction }
        #expect(dispatched.contains { if case .stopDiscovery = $0 { return true } else { return false } })
    }

    @Test func test_connect_when_action_succeeds_then_returns_without_throwing() async throws {
        // Given
        let device = PrinterDevice(id: "1", name: "Printer 1")
        var connectedDevice: PrinterDevice?
        stores.whenReceivingAction(ofType: ReceiptPrinterAction.self) { action in
            if case let .connect(printer, completion) = action {
                connectedDevice = printer
                completion(.success(()))
            }
        }

        // When
        try await sut.connect(to: device)

        // Then
        #expect(connectedDevice == device)
    }

    @Test func test_connect_when_action_fails_then_throws() async {
        // Given
        let device = PrinterDevice(id: "1", name: "Printer 1")
        stores.whenReceivingAction(ofType: ReceiptPrinterAction.self) { action in
            if case let .connect(_, completion) = action {
                completion(.failure(SampleError.connectionFailed))
            }
        }

        // When / Then
        await #expect(throws: SampleError.connectionFailed) {
            try await sut.connect(to: device)
        }
    }

    @Test func test_disconnect_dispatches_action_and_resumes() async {
        // Given
        var disconnectCompletionCalled = false
        stores.whenReceivingAction(ofType: ReceiptPrinterAction.self) { action in
            if case let .disconnect(completion) = action {
                disconnectCompletionCalled = true
                completion()
            }
        }

        // When
        await sut.disconnect()

        // Then
        #expect(disconnectCompletionCalled)
    }
}

private extension POSReceiptPrinterServiceTests {
    enum SampleError: Error, Equatable {
        case connectionFailed
    }
}
