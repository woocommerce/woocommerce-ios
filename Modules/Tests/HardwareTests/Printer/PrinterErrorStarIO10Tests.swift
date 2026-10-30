import Foundation
import Testing
import StarIO10
@testable import Hardware

struct PrinterErrorStarIO10Tests {
    @Test(arguments: [
        StarIO10Error.communication(message: "Communication failed."),
        StarIO10Error.illegalDeviceState(message: "Bluetooth unavailable.", errorCode: .bluetoothUnavailable),
        StarIO10Error.notFound(message: "Printer not found."),
        StarIO10Error.invalidOperation(message: "Not opened.")
    ])
    func test_init_when_connection_level_error_then_returns_connectionLost(error: StarIO10Error) {
        // When
        let printerError = PrinterError(printFailure: error)

        // Then
        #expect(printerError == .connectionLost(detail: String(describing: error)))
    }

    @Test func test_init_when_unprintable_without_status_then_returns_printFailed() {
        // Given
        let error = StarIO10Error.unprintable(message: "Device has error.", errorCode: .deviceHasError)

        // When
        let printerError = PrinterError(printFailure: error)

        // Then
        #expect(printerError == .printFailed(detail: String(describing: error)))
    }

    @Test func test_init_when_other_SDK_error_then_returns_printFailed() {
        // Given
        let error = StarIO10Error.badResponse(message: "Bad response.")

        // When
        let printerError = PrinterError(printFailure: error)

        // Then
        #expect(printerError == .printFailed(detail: String(describing: error)))
    }

    @Test func test_init_when_error_is_not_from_the_SDK_then_returns_printFailed() {
        // Given
        let error = NSError(domain: "print", code: 1)

        // When
        let printerError = PrinterError(printFailure: error)

        // Then
        #expect(printerError == .printFailed(detail: String(describing: error)))
    }

    @Test func test_unprintable_when_cover_open_and_paper_empty_then_returns_coverOpen() {
        // When
        let printerError = PrinterError.unprintable(coverOpen: true, paperEmpty: true, detail: "")

        // Then
        #expect(printerError == .coverOpen)
    }

    @Test func test_unprintable_when_only_paper_empty_then_returns_paperEmpty() {
        // When
        let printerError = PrinterError.unprintable(coverOpen: false, paperEmpty: true, detail: "")

        // Then
        #expect(printerError == .paperEmpty)
    }

    @Test func test_unprintable_when_neither_cover_nor_paper_then_returns_printFailed() {
        // When
        let printerError = PrinterError.unprintable(coverOpen: false, paperEmpty: false, detail: "Holding paper")

        // Then
        #expect(printerError == .printFailed(detail: "Holding paper"))
    }

    @Test func test_localizedDescription_when_connectionLost_then_keeps_SDK_detail() {
        // Given
        let printerError: Error = PrinterError.connectionLost(detail: "Not opened.")

        // Then
        #expect(printerError.localizedDescription == "Not opened.")
    }
}
