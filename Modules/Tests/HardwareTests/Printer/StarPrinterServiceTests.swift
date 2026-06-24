import Testing
import Foundation
@testable import Hardware

struct StarPrinterServiceTests {
    @Test func test_printReceipt_when_no_printer_connected_then_throws_printerNotConnected() async {
        // Given
        let service = StarPrinterService()

        // When / Then
        await #expect(throws: PrinterError.printerNotConnected) {
            try await service.printReceipt(text: "My Store\nOrder #42\nTotal $25.00")
        }
    }
}
