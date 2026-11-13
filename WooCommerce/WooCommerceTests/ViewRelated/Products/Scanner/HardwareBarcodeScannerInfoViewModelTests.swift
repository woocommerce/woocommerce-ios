import Foundation
import Testing
@testable import WooCommerce

@MainActor
struct HardwareBarcodeScannerInfoViewModelTests {
    private let analyticsProvider = MockAnalyticsProvider()

    private func makeViewModel(sleep: @escaping @Sendable (Duration) async throws -> Void = { _ in },
                               onDismiss: @escaping () -> Void = {}) -> HardwareBarcodeScannerInfoViewModel {
        HardwareBarcodeScannerInfoViewModel(source: .barcodeScanner,
                                            analytics: WooAnalytics(analyticsProvider: analyticsProvider),
                                            hardwareBarcodeScanner: HardwareBarcodeScanner(makeObserver: { _, _ in NSObject() }),
                                            sleep: sleep,
                                            onDismiss: onDismiss)
    }

    @Test
    func test_handleScan_when_test_barcode_is_scanned_then_shows_success_and_dismisses_after_delay() async throws {
        // Given
        var dismissCount = 0
        let sut = makeViewModel(sleep: { _ in }, onDismiss: { dismissCount += 1 })

        // When
        sut.handleScan(HardwareBarcodeScannerInfoViewModel.testBarcode)
        let dismissTask = try #require(sut.dismissTask)
        await dismissTask.value

        // Then
        #expect(sut.testScanState == .success)
        #expect(dismissCount == 1)
        #expect(analyticsProvider.receivedEvents == ["hardware_barcode_scanner_test_scan_success"])
        #expect(analyticsProvider.receivedProperties.first?["source"] as? String == "barcode_scanner")
    }

    @Test
    func test_handleScan_when_another_code_is_scanned_then_shows_wrong_value() {
        // Given
        let sut = makeViewModel()

        // When
        sut.handleScan("4006381333931")

        // Then
        #expect(sut.testScanState == .wrongValue)
        #expect(sut.dismissTask == nil)
        #expect(analyticsProvider.receivedEvents == ["hardware_barcode_scanner_test_scan_failed"])
        #expect(analyticsProvider.receivedProperties.first?["reason"] as? String == "wrong_value")
    }

    @Test
    func test_handleMissingEnterSuffix_when_waiting_then_shows_missing_Enter_hint() {
        // Given
        let sut = makeViewModel()

        // When
        sut.handleMissingEnterSuffix()

        // Then
        #expect(sut.testScanState == .missingEnterSuffix)
        #expect(analyticsProvider.receivedProperties.first?["reason"] as? String == "missing_enter_suffix")
    }

    @Test
    func test_handleScan_when_test_already_passed_then_keeps_success() {
        // Given
        let sut = makeViewModel(sleep: { _ in try await Task.sleep(for: .seconds(60)) })
        sut.handleScan(HardwareBarcodeScannerInfoViewModel.testBarcode)

        // When
        sut.handleScan("4006381333931")
        sut.handleMissingEnterSuffix()

        // Then
        #expect(sut.testScanState == .success)
        #expect(analyticsProvider.receivedEvents == ["hardware_barcode_scanner_test_scan_success"])
        sut.onDisappear()
    }

    @Test
    func test_onDisappear_when_success_delay_is_running_then_does_not_dismiss() async throws {
        // Given
        var dismissCount = 0
        let sut = makeViewModel(sleep: { _ in try await Task.sleep(for: .seconds(60)) }, onDismiss: { dismissCount += 1 })
        sut.handleScan(HardwareBarcodeScannerInfoViewModel.testBarcode)
        let dismissTask = try #require(sut.dismissTask)

        // When
        sut.onDisappear()
        await dismissTask.value

        // Then
        #expect(dismissCount == 0)
    }
}
