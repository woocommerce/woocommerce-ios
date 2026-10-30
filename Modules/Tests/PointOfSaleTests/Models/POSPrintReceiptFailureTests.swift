import Foundation
import Testing
import enum Yosemite.PrinterError
@testable import PointOfSale

struct POSPrintReceiptFailureTests {
    @Test(arguments: [
        (PrinterError.paperEmpty, POSPrintReceiptFailure.paperEmpty),
        (PrinterError.coverOpen, POSPrintReceiptFailure.coverOpen),
        (PrinterError.connectionLost(detail: "Not opened."), POSPrintReceiptFailure.printerOffline),
        (PrinterError.printerNotConnected, POSPrintReceiptFailure.printerOffline),
        (PrinterError.printFailed(detail: "Unknown"), POSPrintReceiptFailure.generic)
    ])
    func test_init_when_printer_error_then_maps_to_failure(error: PrinterError, expected: POSPrintReceiptFailure) {
        // When
        let failure = POSPrintReceiptFailure(error: error)

        // Then
        #expect(failure == expected)
    }

    @Test func test_init_when_error_is_not_a_printer_error_then_failure_is_generic() {
        // When
        let failure = POSPrintReceiptFailure(error: NSError(domain: "print", code: 1))

        // Then
        #expect(failure == .generic)
    }
}
