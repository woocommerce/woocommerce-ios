import Testing
@testable import PointOfSale

struct POSPrintReceiptFlowHelperTests {

    // MARK: - printButtonTapped

    @Test func test_printButtonTapped_when_printer_connected_then_prints() {
        // When
        let effect = POSPrintReceiptFlowHelper.printButtonTapped(isPrinterConnected: true)

        // Then
        #expect(effect == .print)
    }

    @Test func test_printButtonTapped_when_printer_disconnected_then_presents_setup() {
        // When
        let effect = POSPrintReceiptFlowHelper.printButtonTapped(isPrinterConnected: false)

        // Then
        #expect(effect == .presentSetup)
    }

    // MARK: - printerConnectionChanged

    @Test func test_printerConnectionChanged_when_connected_and_print_pending_then_prints() {
        // When — merchant connected through the setup flow they opened by tapping Print.
        let effect = POSPrintReceiptFlowHelper.printerConnectionChanged(isConnected: true, pendingPrintAfterSetup: true)

        // Then
        #expect(effect == .print)
    }

    @Test func test_printerConnectionChanged_when_connected_but_no_print_pending_then_does_nothing() {
        // When — a connection unrelated to a Print tap (e.g. connected via Settings).
        let effect = POSPrintReceiptFlowHelper.printerConnectionChanged(isConnected: true, pendingPrintAfterSetup: false)

        // Then
        #expect(effect == .none)
    }

    @Test func test_printerConnectionChanged_when_disconnected_and_print_pending_then_does_nothing() {
        // When
        let effect = POSPrintReceiptFlowHelper.printerConnectionChanged(isConnected: false, pendingPrintAfterSetup: true)

        // Then
        #expect(effect == .none)
    }

    // MARK: - shouldClearPendingPrint

    @Test func test_shouldClearPendingPrint_when_setup_dismissed_without_connecting_then_clears() {
        // When — merchant backed out of setup without connecting.
        let shouldClear = POSPrintReceiptFlowHelper.shouldClearPendingPrint(isSetupPresented: false, isPrinterConnected: false)

        // Then
        #expect(shouldClear == true)
    }

    @Test func test_shouldClearPendingPrint_when_setup_dismissed_after_connecting_then_keeps_pending() {
        // When — the modal dismissed because a printer connected; the pending print must survive so
        // the connection handler prints exactly once.
        let shouldClear = POSPrintReceiptFlowHelper.shouldClearPendingPrint(isSetupPresented: false, isPrinterConnected: true)

        // Then
        #expect(shouldClear == false)
    }

    @Test func test_shouldClearPendingPrint_when_setup_still_presented_then_keeps_pending() {
        // When
        let shouldClear = POSPrintReceiptFlowHelper.shouldClearPendingPrint(isSetupPresented: true, isPrinterConnected: false)

        // Then
        #expect(shouldClear == false)
    }
}
