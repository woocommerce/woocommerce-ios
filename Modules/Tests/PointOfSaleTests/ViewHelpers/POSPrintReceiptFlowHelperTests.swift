import Testing
@testable import PointOfSale

struct POSPrintReceiptFlowHelperTests {

    // MARK: - actionAfterPrintButtonTapped

    @Test func test_actionAfterPrintButtonTapped_when_printer_connected_then_prints() {
        // When
        let action = POSPrintReceiptFlowHelper.actionAfterPrintButtonTapped(isPrinterConnected: true)

        // Then
        #expect(action == .print)
    }

    @Test func test_actionAfterPrintButtonTapped_when_printer_disconnected_then_presents_setup() {
        // When
        let action = POSPrintReceiptFlowHelper.actionAfterPrintButtonTapped(isPrinterConnected: false)

        // Then
        #expect(action == .presentSetup)
    }

    // MARK: - actionAfterSetupModalVisibilityChanged

    @Test func test_actionAfterSetupModalVisibilityChanged_when_dismissed_after_connecting_then_prints() {
        // When — the modal dismissed because a printer connected through the setup the merchant opened.
        let action = POSPrintReceiptFlowHelper.actionAfterSetupModalVisibilityChanged(isPresented: false, isPrinterConnected: true)

        // Then
        #expect(action == .print)
    }

    @Test func test_actionAfterSetupModalVisibilityChanged_when_dismissed_without_connecting_then_does_nothing() {
        // When — merchant backed out of setup without connecting.
        let action = POSPrintReceiptFlowHelper.actionAfterSetupModalVisibilityChanged(isPresented: false, isPrinterConnected: false)

        // Then
        #expect(action == .none)
    }

    @Test func test_actionAfterSetupModalVisibilityChanged_when_still_presented_then_does_nothing() {
        // When
        let action = POSPrintReceiptFlowHelper.actionAfterSetupModalVisibilityChanged(isPresented: true, isPrinterConnected: false)

        // Then
        #expect(action == .none)
    }
}
