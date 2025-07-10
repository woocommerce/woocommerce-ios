import Testing
@testable import WooCommerce

struct PointOfSaleBarcodeScannerSetupScanTesterTests {

    @Test func test_scanTester_calls_onTestPass_when_scan_received_for_expected_barcode() {
        // Given a test EAN13 barcode
        let expectedBarcode = PointOfSaleBarcodeScannerTestBarcode.ean13
        var onTestPassCalled = false
        var onTestFailureCalled = false

        let sut = PointOfSaleBarcodeScannerSetupScanTester(
            onTestPass: { onTestPassCalled = true },
            onTestFailure: { onTestFailureCalled = true },
            barcodeDefinition: expectedBarcode)

        // When the barcode is scanned
        sut.handleScan(.success(expectedBarcode.expectedValue))

        // Then it calls the pass closure
        #expect(onTestPassCalled == true)
        #expect(onTestFailureCalled == false)
    }

    @Test func test_scanTester_calls_onTestFailure_when_scan_received_for_unexpected_barcode() {
        // Given a test EAN13 barcode
        let expectedBarcode = PointOfSaleBarcodeScannerTestBarcode.ean13
        var onTestPassCalled = false
        var onTestFailureCalled = false

        let sut = PointOfSaleBarcodeScannerSetupScanTester(
            onTestPass: { onTestPassCalled = true },
            onTestFailure: { onTestFailureCalled = true },
            barcodeDefinition: expectedBarcode)

        // When an unexpected barcode is scanned
        sut.handleScan(.success("9999999999999"))

        // Then it calls the failure closure
        #expect(onTestPassCalled == false)
        #expect(onTestFailureCalled == true)
    }

        @Test func test_scanTester_calls_onTestFailure_when_scan_fails() {
        // Given a test EAN13 barcode
        let expectedBarcode = PointOfSaleBarcodeScannerTestBarcode.ean13
        var onTestPassCalled = false
        var onTestFailureCalled = false

        let sut = PointOfSaleBarcodeScannerSetupScanTester(
            onTestPass: { onTestPassCalled = true },
            onTestFailure: { onTestFailureCalled = true },
            barcodeDefinition: expectedBarcode)

        // When the scan fails
        sut.handleScan(.failure(TestError.scanFailed))

        // Then it calls the failure closure
        #expect(onTestPassCalled == false)
        #expect(onTestFailureCalled == true)
    }

    private enum TestError: Error {
        case scanFailed
    }

    @Test func test_scanTester_provides_correct_barcode_asset() {
        // Given a test EAN13 barcode
        let expectedBarcode = PointOfSaleBarcodeScannerTestBarcode.ean13

        let sut = PointOfSaleBarcodeScannerSetupScanTester(
            onTestPass: {},
            onTestFailure: {},
            barcodeDefinition: expectedBarcode)

        // Then it provides the correct barcode asset
        #expect(sut.barcode == .testEan13Barcode)
    }

}
