import Testing
import Foundation
import StarIO10
@testable import Hardware

@Suite(.timeLimit(.minutes(5)))
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

    @Test func test_connect_when_cancelled_during_open_then_closes_the_late_connection_without_reporting_it() async throws {
        try await assertCancelledConnectClosesLateConnection(on: StarPrinterCoordinator())
    }

    @Test func test_connect_when_retried_while_a_cancelled_open_is_in_flight_then_waits_and_connects_the_retried_printer() async throws {
        try await assertRetryWaitsForCancelledConnect(on: StarPrinterCoordinator())
    }

    @Test(arguments: [true, false], [true, false])
    func test_connect_when_the_waiting_retry_is_cancelled_then_reports_disconnected(cancelledOpenSucceeds: Bool,
                                                                                     disconnectsWhileWaiting: Bool) async throws {
        try await assertCancelledRetryReportsDisconnected(cancelledOpenSucceeds: cancelledOpenSucceeds,
                                                          disconnectsWhileWaiting: disconnectsWhileWaiting,
                                                          on: StarPrinterCoordinator())
    }
}

private extension StarPrinterServiceTests {
    static let device = PrinterDevice(id: "TSP100IV-1", name: "TSP100IV-1")
    static let retriedDevice = PrinterDevice(id: "TSP100IV-2", name: "TSP100IV-2")

    func makeDelegate() -> StarConnectionDelegate {
        StarConnectionDelegate { _, _ in }
    }

    // The lifecycle tests run on the coordinator, so the mocks and the connect tasks share its isolation. A connect task
    // calls into the coordinator synchronously, so it holds the actor until its first suspension inside `connect`.

    func assertCancelledConnectClosesLateConnection(on coordinator: isolated StarPrinterCoordinator) async throws {
        // Given
        let (statuses, statusContinuation) = observeStatuses(of: coordinator)
        let printer = MockStarPrinterConnection()
        let (opening, releaseOpen) = holdOpen(of: printer)
        let connect = Task {
            try await coordinator.connect(to: Self.device, using: printer)
        }
        await firstValue(of: opening)

        // When
        connect.cancel()
        releaseOpen.finish()

        // Then
        await #expect(throws: CancellationError.self) {
            try await connect.value
        }
        statusContinuation.finish()
        #expect(await collect(statuses) == [.idle, .connecting, .disconnected])
        #expect(printer.closeCallCount == 1)
        #expect(printer.printerDelegate == nil)
        await #expect(throws: PrinterError.printerNotConnected) {
            try await coordinator.printReceipt(text: "Receipt")
        }
    }

    func assertRetryWaitsForCancelledConnect(on coordinator: isolated StarPrinterCoordinator) async throws {
        // Given
        let (statuses, statusContinuation) = observeStatuses(of: coordinator)
        let cancelledPrinter = MockStarPrinterConnection()
        let retriedPrinter = MockStarPrinterConnection()
        let (opening, releaseOpen) = holdOpen(of: cancelledPrinter)
        let cancelledConnect = Task {
            try await coordinator.connect(to: Self.device, using: cancelledPrinter)
        }
        await firstValue(of: opening)

        // When
        cancelledConnect.cancel()
        let (retryStarted, retryStartedContinuation) = AsyncStream.makeStream(of: Void.self)
        let retry = Task {
            retryStartedContinuation.yield()
            try await coordinator.connect(to: Self.retriedDevice, using: retriedPrinter)
        }
        // Resumes only once the retry suspends, i.e. while it waits for the open that is still held.
        await firstValue(of: retryStarted)
        releaseOpen.finish()

        // Then
        await #expect(throws: CancellationError.self) {
            try await cancelledConnect.value
        }
        try await retry.value
        statusContinuation.finish()
        #expect(await collect(statuses) == [.idle, .connecting, .connecting, .connected(Self.retriedDevice)])
        #expect(cancelledPrinter.closeCallCount == 1)
        #expect(cancelledPrinter.printerDelegate == nil)
        #expect(retriedPrinter.closeCallCount == 0)
    }

    func assertCancelledRetryReportsDisconnected(cancelledOpenSucceeds: Bool,
                                                 disconnectsWhileWaiting: Bool,
                                                 on coordinator: isolated StarPrinterCoordinator) async throws {
        // Given
        let (statuses, statusContinuation) = observeStatuses(of: coordinator)
        let cancelledPrinter = MockStarPrinterConnection()
        if !cancelledOpenSucceeds {
            cancelledPrinter.openError = StarIO10Error.communication(message: "Communication failed.")
        }
        let retriedPrinter = MockStarPrinterConnection()
        let (opening, releaseOpen) = holdOpen(of: cancelledPrinter)
        let cancelledConnect = Task {
            try await coordinator.connect(to: Self.device, using: cancelledPrinter)
        }
        await firstValue(of: opening)
        cancelledConnect.cancel()
        let (retryStarted, retryStartedContinuation) = AsyncStream.makeStream(of: Void.self)
        let retry = Task {
            retryStartedContinuation.yield()
            try await coordinator.connect(to: Self.retriedDevice, using: retriedPrinter)
        }
        await firstValue(of: retryStarted)

        // When
        retry.cancel()
        if disconnectsWhileWaiting {
            await coordinator.disconnect()
        }
        releaseOpen.finish()

        // Then
        _ = await cancelledConnect.result
        await #expect(throws: CancellationError.self) {
            try await retry.value
        }
        statusContinuation.finish()
        let expectedStatuses: [PrinterConnectionStatus] = disconnectsWhileWaiting
            ? [.idle, .connecting, .disconnecting, .disconnected]
            : [.idle, .connecting, .disconnected]
        #expect(await collect(statuses) == expectedStatuses)
        #expect(cancelledPrinter.closeCallCount == (cancelledOpenSucceeds ? 1 : 0))
        #expect(cancelledPrinter.printerDelegate == nil)
        #expect(retriedPrinter.printerDelegate == nil)
    }

    func observeStatuses(of coordinator: isolated StarPrinterCoordinator)
        -> (AsyncStream<PrinterConnectionStatus>, AsyncStream<PrinterConnectionStatus>.Continuation) {
        let (statuses, continuation) = AsyncStream.makeStream(of: PrinterConnectionStatus.self)
        coordinator.addStatusObserver(id: UUID(), continuation: continuation)
        return (statuses, continuation)
    }

    /// Holds `printer`'s `open()` pending until the returned continuation finishes. The stream emits once it is pending.
    func holdOpen(of printer: MockStarPrinterConnection) -> (opening: AsyncStream<Void>, release: AsyncStream<Void>.Continuation) {
        let (opening, openingContinuation) = AsyncStream.makeStream(of: Void.self)
        let (released, release) = AsyncStream.makeStream(of: Void.self)
        // Iterating the stream in its own task keeps the hold when the test cancels the connect, which would otherwise
        // end the iteration early.
        let gate = Task {
            for await _ in released {}
        }
        printer.onOpen = {
            openingContinuation.yield()
            await gate.value
        }
        return (opening, release)
    }

    func firstValue(of stream: AsyncStream<Void>) async {
        for await _ in stream {
            return
        }
    }

    func collect(_ statuses: AsyncStream<PrinterConnectionStatus>) async -> [PrinterConnectionStatus] {
        var received: [PrinterConnectionStatus] = []
        for await status in statuses {
            received.append(status)
        }
        return received
    }
}
