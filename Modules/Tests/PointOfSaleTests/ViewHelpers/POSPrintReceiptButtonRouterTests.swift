import Testing

@testable import PointOfSale

struct POSPrintReceiptButtonRouterTests {
    private let sut = POSPrintReceiptButtonRouter()

    @Test func test_action_when_printer_disconnected_then_presents_setup() {
        // Given
        let isPrinterConnected = false

        // When
        let action = sut.action(isPrinterConnected: isPrinterConnected)

        // Then
        #expect(action == .presentSetup)
    }

    @Test func test_action_when_printer_connected_then_no_action() {
        // Given
        let isPrinterConnected = true

        // When
        let action = sut.action(isPrinterConnected: isPrinterConnected)

        // Then
        #expect(action == .none)
    }
}
