import Testing
@testable import PointOfSale

struct PointOfSaleBarcodeScannerSetupScanTesterTests {

    @Test func test_scanTester_calls_onTestPass_when_scan_received_for_expected_barcode() {
        // Given a test EAN13 barcode
        let expectedBarcode = PointOfSaleBarcodeScannerTestBarcode.ean13
        var onTestPassCalled = false
        var onTestFailureCalled = false
        var onTestTimeoutCalled = false

        let sut = PointOfSaleBarcodeScannerSetupScanTester(
            onTestPass: { onTestPassCalled = true },
            onTestFailure: { _ in onTestFailureCalled = true },
            onTestTimeout: { onTestTimeoutCalled = true },
            barcodeDefinition: expectedBarcode)

        // When the barcode is scanned
        sut.handleScan(.success(expectedBarcode.expectedValue))

        // Then it calls the pass closure
        #expect(onTestPassCalled == true)
        #expect(onTestFailureCalled == false)
        #expect(onTestTimeoutCalled == false)
    }

    @Test func test_scanTester_calls_onTestFailure_when_scan_received_for_unexpected_barcode() {
        // Given a test EAN13 barcode
        let expectedBarcode = PointOfSaleBarcodeScannerTestBarcode.ean13
        var onTestPassCalled = false
        var onTestFailureCalled = false
        var onTestTimeoutCalled = false
        var receivedScanValue = ""

        let sut = PointOfSaleBarcodeScannerSetupScanTester(
            onTestPass: { onTestPassCalled = true },
            onTestFailure: { scanValue in
                onTestFailureCalled = true
                receivedScanValue = scanValue
            },
            onTestTimeout: { onTestTimeoutCalled = true },
            barcodeDefinition: expectedBarcode)

        // When an unexpected barcode is scanned
        let unexpectedBarcode = "9999999999999"
        sut.handleScan(.success(unexpectedBarcode))

        // Then it calls the failure closure with the scanned value
        #expect(onTestPassCalled == false)
        #expect(onTestFailureCalled == true)
        #expect(onTestTimeoutCalled == false)
        #expect(receivedScanValue == unexpectedBarcode)
    }

    @Test func test_scanTester_calls_onTestFailure_when_scan_fails() {
        // Given a test EAN13 barcode
        let expectedBarcode = PointOfSaleBarcodeScannerTestBarcode.ean13
        var onTestPassCalled = false
        var onTestFailureCalled = false
        var onTestTimeoutCalled = false
        var receivedScanValue = ""

        let sut = PointOfSaleBarcodeScannerSetupScanTester(
            onTestPass: { onTestPassCalled = true },
            onTestFailure: { scanValue in
                onTestFailureCalled = true
                receivedScanValue = scanValue
            },
            onTestTimeout: { onTestTimeoutCalled = true },
            barcodeDefinition: expectedBarcode)

        // When the scan fails with scanTooShort error
        sut.handleScan(.failure(HIDBarcodeParserError.scanTooShort(barcode: "short")))

        // Then it calls the failure closure
        #expect(onTestPassCalled == false)
        #expect(onTestFailureCalled == true)
        #expect(onTestTimeoutCalled == false)
        #expect(receivedScanValue == "short")
    }

    @Test func test_scanTester_provides_correct_barcode_asset() {
        // Given a test EAN13 barcode
        let expectedBarcode = PointOfSaleBarcodeScannerTestBarcode.ean13

        let sut = PointOfSaleBarcodeScannerSetupScanTester(
            onTestPass: {},
            onTestFailure: { _ in },
            onTestTimeout: {},
            barcodeDefinition: expectedBarcode)

        // Then it provides the correct barcode asset
        #expect(sut.barcode == .testEan13Barcode)
    }
}
