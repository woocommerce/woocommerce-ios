import Foundation
import Testing
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSPrintReceiptCoordinatorTests {
    private let analytics = MockPOSAnalytics()

    // MARK: - handlePrintButtonTap

    @Test func test_handlePrintButtonTap_when_printer_connected_then_prints_and_tracks_tapped_and_success() async {
        // Given
        var printCallCount = 0
        let sut = POSPrintReceiptCoordinator(analytics: analytics) {
            printCallCount += 1
        }

        // When
        let shouldPresentSetup = await sut.handlePrintButtonTap(isPrinterConnected: true)

        // Then
        #expect(shouldPresentSetup == false)
        #expect(printCallCount == 1)
        #expect(analytics.events.map(\.eventName) == ["receipt_print_tapped", "receipt_print_success"])
    }

    @Test func test_handlePrintButtonTap_when_printer_disconnected_then_presents_setup_and_tracks_tapped_only() async {
        // Given
        var printCallCount = 0
        let sut = POSPrintReceiptCoordinator(analytics: analytics) {
            printCallCount += 1
        }

        // When
        let shouldPresentSetup = await sut.handlePrintButtonTap(isPrinterConnected: false)

        // Then
        #expect(shouldPresentSetup == true)
        #expect(printCallCount == 0)
        #expect(analytics.events.map(\.eventName) == ["receipt_print_tapped"])
    }

    @Test func test_handlePrintButtonTap_when_print_throws_then_tracks_failed_with_error() async {
        // Given
        let printError = NSError(domain: "print", code: 1)
        let sut = POSPrintReceiptCoordinator(analytics: analytics) {
            throw printError
        }

        // When
        _ = await sut.handlePrintButtonTap(isPrinterConnected: true)

        // Then
        #expect(analytics.events.map(\.eventName) == ["receipt_print_tapped", "receipt_print_failed"])
        #expect(analytics.events.last?.error as? NSError == printError)
    }

    // MARK: - handleSetupModalVisibilityChange

    @Test func test_handleSetupModalVisibilityChange_when_dismissed_after_connecting_then_prints_and_tracks_success_without_tapped() async {
        // Given
        var printCallCount = 0
        let sut = POSPrintReceiptCoordinator(analytics: analytics) {
            printCallCount += 1
        }

        // When — the modal dismissed because a printer connected through the setup the merchant opened.
        await sut.handleSetupModalVisibilityChange(isPresented: false, isPrinterConnected: true)

        // Then
        #expect(printCallCount == 1)
        #expect(analytics.events.map(\.eventName) == ["receipt_print_success"])
    }

    @Test func test_handleSetupModalVisibilityChange_when_dismissed_without_connecting_then_does_not_print_or_track() async {
        // Given
        var printCallCount = 0
        let sut = POSPrintReceiptCoordinator(analytics: analytics) {
            printCallCount += 1
        }

        // When — merchant backed out of setup without connecting.
        await sut.handleSetupModalVisibilityChange(isPresented: false, isPrinterConnected: false)

        // Then
        #expect(printCallCount == 0)
        #expect(analytics.events.isEmpty)
    }
}
