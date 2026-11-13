import Testing
import Foundation
import StarIO10
@testable import Hardware

struct StarPrinterServiceTests {
    @Test func test_printReceipt_when_no_printer_connected_then_throws_printerNotConnected() async {
        // Given
        let service = StarPrinterService()

        // When / Then
        await #expect(throws: PrinterError.printerNotConnected) {
            try await service.printReceipt(text: "My Store\nOrder #42\nTotal $25.00")
        }
    }

    @Test func test_handleCommunicationError_when_no_printer_connected_then_does_not_report_a_disconnect() async {
        // Given
        let coordinator = StarPrinterCoordinator()
        let (statuses, continuation) = AsyncStream.makeStream(of: PrinterConnectionStatus.self)
        await coordinator.addStatusObserver(id: UUID(), continuation: continuation)

        // When
        await coordinator.handleCommunicationError(StarIO10Error.communication(message: "Communication failed."),
                                                   reportedBy: makeDelegate())
        continuation.finish()

        // Then
        var received: [PrinterConnectionStatus] = []
        for await status in statuses {
            received.append(status)
        }
        #expect(received == [.idle])
    }

    @Test(arguments: [
        StarIO10Error.communication(message: "Communication failed."),
        StarIO10Error.illegalDeviceState(message: "Bluetooth unavailable.", errorCode: .bluetoothUnavailable),
        StarIO10Error.notFound(message: "Printer not found.")
    ])
    func test_isConnectionLoss_when_active_connection_reports_link_error_then_returns_true(error: StarIO10Error) {
        // Given
        let delegate = makeDelegate()

        // When
        let isConnectionLoss = StarPrinterCoordinator.isConnectionLoss(error,
                                                                       reportedBy: delegate,
                                                                       activeDelegate: delegate,
                                                                       isConnecting: false)

        // Then
        #expect(isConnectionLoss)
    }

    @Test func test_isConnectionLoss_when_active_connection_reports_non_link_error_then_returns_false() {
        // Given
        let delegate = makeDelegate()

        // When
        let isConnectionLoss = StarPrinterCoordinator.isConnectionLoss(StarIO10Error.inUse(message: "Printer in use."),
                                                                       reportedBy: delegate,
                                                                       activeDelegate: delegate,
                                                                       isConnecting: false)

        // Then
        #expect(!isConnectionLoss)
    }

    @Test func test_isConnectionLoss_when_reported_by_a_replaced_connection_then_returns_false() {
        // Given
        let replacedDelegate = makeDelegate()
        let activeDelegate = makeDelegate()

        // When
        let isConnectionLoss = StarPrinterCoordinator.isConnectionLoss(StarIO10Error.communication(message: "Communication failed."),
                                                                       reportedBy: replacedDelegate,
                                                                       activeDelegate: activeDelegate,
                                                                       isConnecting: false)

        // Then
        #expect(!isConnectionLoss)
    }

    @Test func test_isConnectionLoss_when_connection_was_already_released_then_returns_false() {
        // When
        let isConnectionLoss = StarPrinterCoordinator.isConnectionLoss(StarIO10Error.communication(message: "Communication failed."),
                                                                       reportedBy: makeDelegate(),
                                                                       activeDelegate: nil,
                                                                       isConnecting: false)

        // Then
        #expect(!isConnectionLoss)
    }

    @Test func test_isConnectionLoss_when_connect_is_in_progress_then_returns_false() {
        // Given
        let delegate = makeDelegate()

        // When
        let isConnectionLoss = StarPrinterCoordinator.isConnectionLoss(StarIO10Error.communication(message: "Communication failed."),
                                                                       reportedBy: delegate,
                                                                       activeDelegate: delegate,
                                                                       isConnecting: true)

        // Then
        #expect(!isConnectionLoss)
    }
}

private extension StarPrinterServiceTests {
    func makeDelegate() -> StarConnectionDelegate {
        StarConnectionDelegate { _, _ in }
    }
}
