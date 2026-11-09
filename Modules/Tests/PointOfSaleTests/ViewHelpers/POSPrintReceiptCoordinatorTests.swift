import Foundation
import Testing
import enum Yosemite.PrinterError
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSPrintReceiptCoordinatorTests {
    private let analytics = MockPOSAnalytics()
    private let spy = EffectsSpy()

    // MARK: - printButtonTapped

    @Test func test_printButtonTapped_when_printer_connected_then_prints_and_tracks_tapped_and_success() async {
        // Given
        let sut = makeCoordinator()

        // When
        await sut.printButtonTapped(isPrinterConnected: true)

        // Then
        #expect(spy.presentSetupCallCount == 0)
        #expect(spy.printCallCount == 1)
        #expect(analytics.events.map(\.eventName) == ["receipt_print_tapped", "receipt_print_success"])
    }

    @Test func test_printButtonTapped_when_print_succeeds_then_button_goes_loading_then_success() async {
        // Given
        let sut = makeCoordinator()

        // When
        await sut.printButtonTapped(isPrinterConnected: true)

        // Then
        #expect(spy.buttonStates == [.loading, .success])
        #expect(spy.failures.isEmpty)
    }

    @Test func test_printButtonTapped_when_printing_then_button_is_loading_during_print() async {
        // Given
        var buttonStateDuringPrint: POSButtonState?
        let sut = makeCoordinator(printReceipt: { [spy] in buttonStateDuringPrint = spy.buttonStates.last })

        // When
        await sut.printButtonTapped(isPrinterConnected: true)

        // Then
        #expect(buttonStateDuringPrint == .loading)
    }

    @Test func test_printButtonTapped_when_printer_disconnected_then_presents_setup_and_tracks_tapped_only() async {
        // Given
        let sut = makeCoordinator()

        // When
        await sut.printButtonTapped(isPrinterConnected: false)

        // Then
        #expect(spy.presentSetupCallCount == 1)
        #expect(spy.printCallCount == 0)
        #expect(spy.buttonStates.isEmpty)
        #expect(analytics.events.map(\.eventName) == ["receipt_print_tapped"])
    }

    @Test func test_printButtonTapped_when_print_throws_then_tracks_failed_with_error() async {
        // Given
        let printError = NSError(domain: "print", code: 1)
        let sut = makeCoordinator(printReceipt: { throw printError })

        // When
        await sut.printButtonTapped(isPrinterConnected: true)

        // Then
        #expect(analytics.events.map(\.eventName) == ["receipt_print_tapped", "receipt_print_failed"])
        #expect(analytics.events.last?.error as? NSError == printError)
    }

    @Test func test_printButtonTapped_when_print_throws_then_resets_button_and_presents_failure() async {
        // Given
        let sut = makeCoordinator(printReceipt: { throw PrinterError.paperEmpty })

        // When
        await sut.printButtonTapped(isPrinterConnected: true)

        // Then
        #expect(spy.buttonStates == [.loading, .idle])
        #expect(spy.failures == [.paperEmpty])
    }

    @Test func test_printButtonTapped_when_merchant_leaves_screen_during_print_then_tracks_failed_without_presenting_failure() async {
        // Given
        let sut = makeCoordinator(printReceipt: { [spy] in
            spy.isOnSuccessScreen = false
            throw PrinterError.paperEmpty
        })

        // When
        await sut.printButtonTapped(isPrinterConnected: true)

        // Then
        #expect(spy.buttonStates == [.loading, .idle])
        #expect(spy.failures.isEmpty)
        #expect(analytics.events.map(\.eventName) == ["receipt_print_tapped", "receipt_print_failed"])
    }

    // MARK: - setupModalVisibilityChanged

    @Test func test_setupModalVisibilityChanged_when_dismissed_after_connecting_then_prints_and_tracks_success_without_tapped() async {
        // Given
        let sut = makeCoordinator()

        // When — the modal dismissed because a printer connected through the setup the merchant opened.
        await sut.setupModalVisibilityChanged(isPresented: false, isPrinterConnected: true)

        // Then
        #expect(spy.printCallCount == 1)
        #expect(spy.buttonStates == [.loading, .success])
        #expect(analytics.events.map(\.eventName) == ["receipt_print_success"])
    }

    @Test func test_setupModalVisibilityChanged_when_dismissed_without_connecting_then_does_not_print_or_track() async {
        // Given
        let sut = makeCoordinator()

        // When — merchant backed out of setup without connecting.
        await sut.setupModalVisibilityChanged(isPresented: false, isPrinterConnected: false)

        // Then
        #expect(spy.printCallCount == 0)
        #expect(analytics.events.isEmpty)
    }

    // MARK: - failureActionSelected

    @Test func test_failureActionSelected_when_retry_and_printer_connected_then_prints_again() async {
        // Given
        let sut = makeCoordinator()

        // When
        await sut.failureActionSelected(.retry, isPrinterConnected: true)

        // Then
        #expect(spy.printCallCount == 1)
        #expect(spy.presentSetupCallCount == 0)
        #expect(analytics.events.map(\.eventName) == ["receipt_print_tapped", "receipt_print_success"])
    }

    @Test func test_failureActionSelected_when_retry_fails_again_then_presents_failure_again() async {
        // Given
        let sut = makeCoordinator(printReceipt: { throw PrinterError.coverOpen })

        // When
        await sut.printButtonTapped(isPrinterConnected: true)
        await sut.failureActionSelected(.retry, isPrinterConnected: true)

        // Then
        #expect(spy.failures == [.coverOpen, .coverOpen])
    }

    @Test func test_failureActionSelected_when_retry_and_printer_disconnected_then_presents_setup() async {
        // Given
        let sut = makeCoordinator()

        // When — the failed print dropped the connection.
        await sut.failureActionSelected(.retry, isPrinterConnected: false)

        // Then
        #expect(spy.presentSetupCallCount == 1)
        #expect(spy.printCallCount == 0)
    }

    @Test func test_failureActionSelected_when_emailReceipt_then_presents_email_and_tracks_email_tapped() async {
        // Given
        let sut = makeCoordinator()

        // When
        await sut.failureActionSelected(.emailReceipt, isPrinterConnected: true)

        // Then
        #expect(spy.presentEmailCallCount == 1)
        #expect(spy.printCallCount == 0)
        #expect(analytics.events.map(\.eventName) == ["receipt_email_tapped"])
    }
}

private extension POSPrintReceiptCoordinatorTests {
    func makeCoordinator(printReceipt: (() async throws -> Void)? = nil) -> POSPrintReceiptCoordinator {
        POSPrintReceiptCoordinator(analytics: analytics,
                                   printReceipt: { [spy] in
                                       spy.printCallCount += 1
                                       try await printReceipt?()
                                   },
                                   presentPrinterSetup: { [spy] in spy.presentSetupCallCount += 1 },
                                   presentEmailReceipt: { [spy] in spy.presentEmailCallCount += 1 },
                                   isOnSuccessScreen: { [spy] in spy.isOnSuccessScreen },
                                   presentFailure: { [spy] in spy.failures.append($0) },
                                   updateButtonState: { [spy] in spy.buttonStates.append($0) })
    }
}

@MainActor
private final class EffectsSpy {
    var printCallCount = 0
    var presentSetupCallCount = 0
    var presentEmailCallCount = 0
    var isOnSuccessScreen = true
    var failures: [POSPrintReceiptFailure] = []
    var buttonStates: [POSButtonState] = []
}
