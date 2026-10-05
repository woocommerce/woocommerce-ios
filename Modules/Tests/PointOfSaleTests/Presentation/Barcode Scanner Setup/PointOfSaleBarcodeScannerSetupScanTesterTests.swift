import Testing
@testable import PointOfSale

@Suite(.timeLimit(.minutes(5)))
@MainActor
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

    @Test func test_startTimer_when_timeout_elapses_then_calls_onTestTimeout() async {
        // Given
        var sut: PointOfSaleBarcodeScannerSetupScanTester?

        // When
        await withCheckedContinuation { continuation in
            sut = makeTimedSUT(onTestTimeout: { continuation.resume() })
            sut?.startTimer()
        }

        // Then the continuation resumed, so the timeout fired
        #expect(sut != nil)
    }

    @Test func test_stopTimer_when_called_before_timeout_then_does_not_call_onTestTimeout() async throws {
        // Given
        var timeoutCount = 0
        let sut = makeTimedSUT(onTestTimeout: { timeoutCount += 1 })
        sut.startTimer()

        // When
        sut.stopTimer()
        try await Task.sleep(for: Constants.waitPastTimeout)

        // Then
        #expect(timeoutCount == 0)
    }

    @Test func test_startTimer_when_called_twice_then_calls_onTestTimeout_once() async throws {
        // Given
        var timeoutCount = 0
        let sut = makeTimedSUT(onTestTimeout: { timeoutCount += 1 })

        // When
        sut.startTimer()
        sut.startTimer()
        try await Task.sleep(for: Constants.waitPastTimeout)

        // Then
        #expect(timeoutCount == 1)
    }
}

private extension PointOfSaleBarcodeScannerSetupScanTesterTests {
    enum Constants {
        static let timeout: Duration = .milliseconds(10)
        static let waitPastTimeout: Duration = .milliseconds(300)
    }

    func makeTimedSUT(onTestTimeout: @escaping () -> Void) -> PointOfSaleBarcodeScannerSetupScanTester {
        PointOfSaleBarcodeScannerSetupScanTester(
            onTestPass: {},
            onTestFailure: { _ in },
            onTestTimeout: onTestTimeout,
            barcodeDefinition: .ean13,
            timeout: Constants.timeout)
    }
}
