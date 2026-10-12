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

    @Test func test_startTimer_when_sleep_finishes_then_calls_onTestTimeout_after_ten_seconds() async {
        // Given
        let sleeper = MockTimeoutSleeper()
        var timeoutCount = 0
        let sut = makeTimedSUT(sleeper: sleeper, onTestTimeout: { timeoutCount += 1 })

        // When
        sut.startTimer()
        sleeper.finish()
        await sut.timeoutTask?.value

        // Then
        #expect(timeoutCount == 1)
        #expect(sleeper.requestedDurations == [.seconds(10)])
    }

    @Test func test_stopTimer_when_sleep_finishes_after_stop_then_does_not_call_onTestTimeout() async {
        // Given
        let sleeper = MockTimeoutSleeper()
        var timeoutCount = 0
        let sut = makeTimedSUT(sleeper: sleeper, onTestTimeout: { timeoutCount += 1 })
        sut.startTimer()
        let timeoutTask = sut.timeoutTask

        // When the sleep returns normally after the task was cancelled
        sut.stopTimer()
        sleeper.finish()
        await timeoutTask?.value

        // Then
        #expect(timeoutCount == 0)
    }

    @Test func test_startTimer_when_called_twice_then_calls_onTestTimeout_once() async {
        // Given
        let sleeper = MockTimeoutSleeper()
        var timeoutCount = 0
        let sut = makeTimedSUT(sleeper: sleeper, onTestTimeout: { timeoutCount += 1 })
        sut.startTimer()
        let firstTimeoutTask = sut.timeoutTask

        // When
        sut.startTimer()
        sleeper.finish()
        await firstTimeoutTask?.value
        await sut.timeoutTask?.value

        // Then
        #expect(timeoutCount == 1)
    }
}

private extension PointOfSaleBarcodeScannerSetupScanTesterTests {
    func makeTimedSUT(sleeper: MockTimeoutSleeper, onTestTimeout: @escaping () -> Void) -> PointOfSaleBarcodeScannerSetupScanTester {
        PointOfSaleBarcodeScannerSetupScanTester(
            onTestPass: {},
            onTestFailure: { _ in },
            onTestTimeout: onTestTimeout,
            barcodeDefinition: .ean13,
            sleep: { [sleeper] duration in await sleeper.sleep(for: duration) })
    }
}

/// Lets a test decide when the scan tester's timeout sleep returns. The sleep ignores cancellation, so a test can
/// reproduce a sleep that finishes after `stopTimer()` cancelled the task.
@MainActor
private final class MockTimeoutSleeper {
    private(set) var requestedDurations: [Duration] = []
    private var isFinished = false
    private var waitingSleeps: [CheckedContinuation<Void, Never>] = []

    func sleep(for duration: Duration) async {
        requestedDurations.append(duration)
        guard !isFinished else {
            return
        }
        await withCheckedContinuation { waitingSleeps.append($0) }
    }

    func finish() {
        isFinished = true
        waitingSleeps.forEach { $0.resume() }
        waitingSleeps.removeAll()
    }
}
