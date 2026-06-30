import Testing

@testable import PointOfSale

struct POSPrintReceiptButtonRouterTests {
    private let sut = POSPrintReceiptButtonRouter()

    @Test func test_shouldPresentSetup_when_printer_disconnected_then_returns_true() {
        // Given
        let isPrinterConnected = false

        // When
        let shouldPresentSetup = sut.shouldPresentSetup(isPrinterConnected: isPrinterConnected)

        // Then
        #expect(shouldPresentSetup == true)
    }

    @Test func test_shouldPresentSetup_when_printer_connected_then_returns_false() {
        // Given
        let isPrinterConnected = true

        // When
        let shouldPresentSetup = sut.shouldPresentSetup(isPrinterConnected: isPrinterConnected)

        // Then
        #expect(shouldPresentSetup == false)
    }
}
