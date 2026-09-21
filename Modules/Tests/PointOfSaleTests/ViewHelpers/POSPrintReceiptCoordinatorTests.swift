import Foundation
import Testing
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSPrintReceiptCoordinatorTests {
    private let analytics = MockPOSAnalytics()

    // MARK: - printButtonTapped

    @Test func test_printButtonTapped_when_printer_connected_then_prints_and_tracks_tapped_and_success() async {
        // Given
        var printCallCount = 0
        var presentSetupCallCount = 0
        let sut = POSPrintReceiptCoordinator(analytics: analytics,
                                             printReceipt: { printCallCount += 1 },
                                             presentPrinterSetup: { presentSetupCallCount += 1 })

        // When
        await sut.printButtonTapped(isPrinterConnected: true)

        // Then
        #expect(presentSetupCallCount == 0)
        #expect(printCallCount == 1)
        #expect(analytics.events.map(\.eventName) == ["receipt_print_tapped", "receipt_print_success"])
    }

    @Test func test_printButtonTapped_when_printer_disconnected_then_presents_setup_and_tracks_tapped_only() async {
        // Given
        var printCallCount = 0
        var presentSetupCallCount = 0
        let sut = POSPrintReceiptCoordinator(analytics: analytics,
                                             printReceipt: { printCallCount += 1 },
                                             presentPrinterSetup: { presentSetupCallCount += 1 })

        // When
        await sut.printButtonTapped(isPrinterConnected: false)

        // Then
        #expect(presentSetupCallCount == 1)
        #expect(printCallCount == 0)
        #expect(analytics.events.map(\.eventName) == ["receipt_print_tapped"])
    }

    @Test func test_printButtonTapped_when_print_throws_then_tracks_failed_with_error() async {
        // Given
        let printError = NSError(domain: "print", code: 1)
        let sut = POSPrintReceiptCoordinator(analytics: analytics,
                                             printReceipt: { throw printError },
                                             presentPrinterSetup: {})

        // When
        await sut.printButtonTapped(isPrinterConnected: true)

        // Then
        #expect(analytics.events.map(\.eventName) == ["receipt_print_tapped", "receipt_print_failed"])
        #expect(analytics.events.last?.error as? NSError == printError)
    }

    // MARK: - setupModalVisibilityChanged

    @Test func test_setupModalVisibilityChanged_when_dismissed_after_connecting_then_prints_and_tracks_success_without_tapped() async {
        // Given
        var printCallCount = 0
        let sut = POSPrintReceiptCoordinator(analytics: analytics,
                                             printReceipt: { printCallCount += 1 },
                                             presentPrinterSetup: {})

        // When — the modal dismissed because a printer connected through the setup the merchant opened.
        await sut.setupModalVisibilityChanged(isPresented: false, isPrinterConnected: true)

        // Then
        #expect(printCallCount == 1)
        #expect(analytics.events.map(\.eventName) == ["receipt_print_success"])
    }

    @Test func test_setupModalVisibilityChanged_when_dismissed_without_connecting_then_does_not_print_or_track() async {
        // Given
        var printCallCount = 0
        let sut = POSPrintReceiptCoordinator(analytics: analytics,
                                             printReceipt: { printCallCount += 1 },
                                             presentPrinterSetup: {})

        // When — merchant backed out of setup without connecting.
        await sut.setupModalVisibilityChanged(isPresented: false, isPrinterConnected: false)

        // Then
        #expect(printCallCount == 0)
        #expect(analytics.events.isEmpty)
    }
}
