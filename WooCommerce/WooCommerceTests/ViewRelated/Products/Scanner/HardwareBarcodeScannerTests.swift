import Foundation
import Testing
import enum Hardware.HIDBarcodeParserError
import enum Hardware.HIDBarcodeParserResult
@testable import WooCommerce

@MainActor
struct HardwareBarcodeScannerTests {
    private let analyticsProvider = MockAnalyticsProvider()
    private let noticePresenter = MockNoticePresenter()
    private let observerFactory = MockObserverFactory()

    private func makeScanner(isTextInputActive: Bool = false) -> HardwareBarcodeScanner {
        HardwareBarcodeScanner(analytics: WooAnalytics(analyticsProvider: analyticsProvider),
                               noticePresenter: { [noticePresenter] in noticePresenter },
                               isTextInputActive: { isTextInputActive },
                               makeObserver: observerFactory.make)
    }

    @Test
    func test_scan_when_listening_then_delivers_barcode_and_tracks_source() {
        // Given
        let sut = makeScanner()
        var scannedBarcodes: [String] = []
        _ = sut.startListening(source: .orderList) { scannedBarcodes.append($0.payloadStringValue) }

        // When
        observerFactory.send(.success(barcode: "SKU-1", scanDurationMs: 50))

        // Then
        #expect(scannedBarcodes == ["SKU-1"])
        #expect(analyticsProvider.receivedEvents == ["hardware_barcode_scanning_success"])
        #expect(analyticsProvider.receivedProperties.first?["source"] as? String == "order_list")
    }

    @Test
    func test_scan_when_a_listener_starts_on_top_then_only_the_top_listener_gets_it_until_it_stops() {
        // Given
        let sut = makeScanner()
        var listScans: [String] = []
        var formScans: [String] = []
        _ = sut.startListening(source: .orderList) { listScans.append($0.payloadStringValue) }
        let formToken = sut.startListening(source: .orderCreation) { formScans.append($0.payloadStringValue) }

        // When
        observerFactory.send(.success(barcode: "FIRST", scanDurationMs: 50))
        sut.stopListening(formToken)
        observerFactory.send(.success(barcode: "SECOND", scanDurationMs: 50))

        // Then
        #expect(formScans == ["FIRST"])
        #expect(listScans == ["SECOND"])
        #expect(observerFactory.createdObserverCount == 1)
    }

    @Test
    func test_scan_when_top_listener_is_disabled_then_it_does_not_reach_any_listener() {
        // Given
        let sut = makeScanner()
        var listScans: [String] = []
        var formScans: [String] = []
        _ = sut.startListening(source: .orderList) { listScans.append($0.payloadStringValue) }
        _ = sut.startListening(source: .orderCreation, isEnabled: { false }) { formScans.append($0.payloadStringValue) }

        // When
        observerFactory.send(.success(barcode: "SKU-1", scanDurationMs: 50))

        // Then
        #expect(listScans.isEmpty)
        #expect(formScans.isEmpty)
        #expect(observerFactory.acceptsInput() == false)
    }

    @Test
    func test_acceptsInput_when_a_text_field_has_focus_then_is_false() {
        // Given
        let sut = makeScanner(isTextInputActive: true)

        // When
        _ = sut.startListening(source: .productList) { _ in }

        // Then
        #expect(observerFactory.acceptsInput() == false)
    }

    @Test
    func test_stopListening_when_last_listener_stops_then_releases_the_observer() {
        // Given
        let sut = makeScanner()
        let token = sut.startListening(source: .productList) { _ in }
        weak var observer = observerFactory.lastObserver
        #expect(observer != nil)

        // When
        sut.stopListening(token)
        observerFactory.lastObserver = nil

        // Then
        #expect(observer == nil)
        #expect(observerFactory.acceptsInput() == false)
    }

    @Test
    func test_scan_when_input_has_no_Enter_then_shows_notice() throws {
        // Given
        let sut = makeScanner()
        _ = sut.startListening(source: .productList) { _ in }

        // When
        observerFactory.send(.failure(error: .timedOut(barcode: "123"), scanDurationMs: 50))

        // Then
        let notice = try #require(noticePresenter.queuedNotices.first)
        #expect(notice.title == "Scan not finished. Set your scanner to send Enter after each barcode.")
    }

    @Test
    func test_scan_when_input_without_Enter_is_shorter_than_a_barcode_then_is_ignored() {
        // Given
        let sut = makeScanner()
        _ = sut.startListening(source: .productList) { _ in }

        // When
        observerFactory.send(.failure(error: .timedOut(barcode: "12"), scanDurationMs: 50))
        observerFactory.send(.failure(error: .scanTooShort(barcode: "12"), scanDurationMs: 50))

        // Then
        #expect(noticePresenter.queuedNotices.isEmpty)
    }

    @Test
    func test_scan_when_listener_handles_missing_Enter_then_calls_it_instead_of_showing_notice() {
        // Given
        let sut = makeScanner()
        var missingEnterCount = 0
        _ = sut.startListening(source: .orderList, onMissingEnterSuffix: { missingEnterCount += 1 }, onScan: { _ in })

        // When
        observerFactory.send(.failure(error: .timedOut(barcode: "1234567890128"), scanDurationMs: 50))

        // Then
        #expect(missingEnterCount == 1)
        #expect(noticePresenter.queuedNotices.isEmpty)
    }

    @Test(arguments: [
        ("1234567890128", ScannedBarcode.BarcodeSymbologyName.ean13),
        ("036000291452", .ean13),
        ("96385074", .ean8),
        ("1234567890123", .code128),
        ("SKU-123", .code128),
        ("12345", .code128)
    ])
    func test_hardwareScannerInput_when_barcode_has_given_digits_then_infers_symbology(barcode: String,
                                                                                      expected: ScannedBarcode.BarcodeSymbologyName) {
        // When
        let scannedBarcode = ScannedBarcode(hardwareScannerInput: barcode)

        // Then
        #expect(scannedBarcode.payloadStringValue == barcode)
        #expect(scannedBarcode.symbology == expected.symbology)
    }
}

extension ScannedBarcode {
    /// `BarcodeSymbology` isn't `Sendable`, so test arguments name it instead.
    enum BarcodeSymbologyName: Sendable {
        case ean13, ean8, code128

        var symbology: BarcodeSymbology {
            switch self {
            case .ean13: return .ean13
            case .ean8: return .ean8
            case .code128: return .code128
            }
        }
    }
}

@MainActor
private final class MockObserverFactory {
    private(set) var createdObserverCount = 0
    var lastObserver: AnyObject?
    private var acceptsInputHandler: () -> Bool = { false }
    private var onResult: (HIDBarcodeParserResult) -> Void = { _ in }

    func make(acceptsInput: @escaping () -> Bool, onResult: @escaping (HIDBarcodeParserResult) -> Void) -> AnyObject {
        createdObserverCount += 1
        acceptsInputHandler = acceptsInput
        self.onResult = onResult
        let observer = NSObject()
        lastObserver = observer
        return observer
    }

    func acceptsInput() -> Bool {
        acceptsInputHandler()
    }

    func send(_ result: HIDBarcodeParserResult) {
        onResult(result)
    }
}
