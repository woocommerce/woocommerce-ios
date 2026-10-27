import Testing
@testable import WooCommerce

@MainActor
struct ScannerContainerViewControllerTests {
    private let barcode = ScannedBarcode(payloadStringValue: "ABC123", symbology: .code128)

    @Test
    func test_detection_when_three_frames_match_then_delivers_only_once() {
        // Given
        var scannedBarcodes: [ScannedBarcode] = []
        let sut = ScannerContainerViewController(navigationTitle: "", instructionText: "") { scannedBarcodes.append($0) }

        // When
        sut.handleBarcodeDetectionResult(.success([barcode]))
        sut.handleBarcodeDetectionResult(.success([barcode]))

        // Then
        #expect(scannedBarcodes.isEmpty)
        sut.handleBarcodeDetectionResult(.success([barcode]))
        #expect(scannedBarcodes == [barcode])
        sut.handleBarcodeDetectionResult(.success([barcode]))
        #expect(scannedBarcodes == [barcode])
    }

    @Test(arguments: [false, true])
    func test_detection_when_value_or_symbology_changes_then_restarts_confirmation(changeSymbology: Bool) {
        // Given
        var scannedBarcodes: [ScannedBarcode] = []
        let sut = ScannerContainerViewController(navigationTitle: "", instructionText: "") { scannedBarcodes.append($0) }
        let changedBarcode = ScannedBarcode(payloadStringValue: changeSymbology ? "ABC123" : "DEF456",
                                            symbology: changeSymbology ? .code39 : .code128)
        sut.handleBarcodeDetectionResult(.success([barcode]))
        sut.handleBarcodeDetectionResult(.success([barcode]))

        // When
        sut.handleBarcodeDetectionResult(.success([changedBarcode]))
        sut.handleBarcodeDetectionResult(.success([changedBarcode]))

        // Then
        #expect(scannedBarcodes.isEmpty)
        sut.handleBarcodeDetectionResult(.success([changedBarcode]))
        #expect(scannedBarcodes == [changedBarcode])
    }

    @Test(arguments: [false, true])
    func test_detection_when_frame_is_empty_or_fails_then_restarts_confirmation(fails: Bool) {
        // Given
        var scannedBarcodes: [ScannedBarcode] = []
        let sut = ScannerContainerViewController(navigationTitle: "", instructionText: "") { scannedBarcodes.append($0) }
        sut.handleBarcodeDetectionResult(.success([barcode]))
        sut.handleBarcodeDetectionResult(.success([barcode]))

        // When
        sut.handleBarcodeDetectionResult(fails ? .failure(DetectionError.failed) : .success([]))
        sut.handleBarcodeDetectionResult(.success([barcode]))
        sut.handleBarcodeDetectionResult(.success([barcode]))

        // Then
        #expect(scannedBarcodes.isEmpty)
        sut.handleBarcodeDetectionResult(.success([barcode]))
        #expect(scannedBarcodes == [barcode])
    }

    @Test
    func test_detection_when_same_barcode_repeats_within_one_frame_then_does_not_confirm() {
        // Given
        var scannedBarcodes: [ScannedBarcode] = []
        let sut = ScannerContainerViewController(navigationTitle: "", instructionText: "") { scannedBarcodes.append($0) }

        // When
        sut.handleBarcodeDetectionResult(.success([barcode, barcode, barcode]))

        // Then
        #expect(scannedBarcodes.isEmpty)
    }

    @Test
    func test_detection_when_reads_alternate_then_does_not_confirm() {
        // Given
        var scannedBarcodes: [ScannedBarcode] = []
        let sut = ScannerContainerViewController(navigationTitle: "", instructionText: "") { scannedBarcodes.append($0) }
        let otherBarcode = ScannedBarcode(payloadStringValue: "DEF456", symbology: .code128)

        // When
        for value in [barcode, otherBarcode, barcode, otherBarcode, barcode] {
            sut.handleBarcodeDetectionResult(.success([value]))
        }

        // Then
        #expect(scannedBarcodes.isEmpty)
    }

    @Test
    func test_detection_when_isolated_misread_interrupts_matching_reads_then_requires_three_fresh_matches() {
        // Given
        var scannedBarcodes: [ScannedBarcode] = []
        let sut = ScannerContainerViewController(navigationTitle: "", instructionText: "") { scannedBarcodes.append($0) }
        let misread = ScannedBarcode(payloadStringValue: "12345678", symbology: .ean8)
        sut.handleBarcodeDetectionResult(.success([barcode]))
        sut.handleBarcodeDetectionResult(.success([barcode]))

        // When
        sut.handleBarcodeDetectionResult(.success([misread]))
        sut.handleBarcodeDetectionResult(.success([barcode]))
        sut.handleBarcodeDetectionResult(.success([barcode]))

        // Then
        #expect(scannedBarcodes.isEmpty)
        sut.handleBarcodeDetectionResult(.success([barcode]))
        #expect(scannedBarcodes == [barcode])
    }

    @Test
    func test_detection_when_frames_contain_multiple_barcodes_then_confirms_first_barcode_only() {
        // Given
        var scannedBarcodes: [ScannedBarcode] = []
        let sut = ScannerContainerViewController(navigationTitle: "", instructionText: "") { scannedBarcodes.append($0) }
        let otherBarcode = ScannedBarcode(payloadStringValue: "DEF456", symbology: .code128)
        let frame = [barcode, otherBarcode]

        // When
        sut.handleBarcodeDetectionResult(.success(frame))
        sut.handleBarcodeDetectionResult(.success(frame))

        // Then
        #expect(scannedBarcodes.isEmpty)
        sut.handleBarcodeDetectionResult(.success(frame))
        #expect(scannedBarcodes == [barcode])
    }

    @Test(arguments: [false, true])
    func test_detection_when_barcode_order_changes_then_confirms_original_candidate(candidateIsFirstInFinalFrame: Bool) {
        // Given
        var scannedBarcodes: [ScannedBarcode] = []
        let sut = ScannerContainerViewController(navigationTitle: "", instructionText: "") { scannedBarcodes.append($0) }
        let otherBarcode = ScannedBarcode(payloadStringValue: "DEF456", symbology: .code128)
        sut.handleBarcodeDetectionResult(.success([barcode, otherBarcode]))

        // When
        sut.handleBarcodeDetectionResult(.success([otherBarcode, barcode]))

        // Then
        #expect(scannedBarcodes.isEmpty)
        let finalFrame = candidateIsFirstInFinalFrame ? [barcode, otherBarcode] : [otherBarcode, barcode]
        sut.handleBarcodeDetectionResult(.success(finalFrame))
        #expect(scannedBarcodes == [barcode])
    }

    @Test
    func test_detection_when_candidate_disappears_then_requires_three_matches_for_replacement() {
        // Given
        var scannedBarcodes: [ScannedBarcode] = []
        let sut = ScannerContainerViewController(navigationTitle: "", instructionText: "") { scannedBarcodes.append($0) }
        let otherBarcode = ScannedBarcode(payloadStringValue: "DEF456", symbology: .code128)
        sut.handleBarcodeDetectionResult(.success([barcode, otherBarcode]))
        sut.handleBarcodeDetectionResult(.success([otherBarcode, barcode]))

        // When
        sut.handleBarcodeDetectionResult(.success([otherBarcode]))
        sut.handleBarcodeDetectionResult(.success([otherBarcode, barcode]))

        // Then
        #expect(scannedBarcodes.isEmpty)
        sut.handleBarcodeDetectionResult(.success([barcode, otherBarcode]))
        #expect(scannedBarcodes == [otherBarcode])
    }

    @Test
    func test_detection_when_confirmed_scan_is_followed_by_interruptions_and_new_barcode_then_does_not_deliver_again() {
        // Given
        var scannedBarcodes: [ScannedBarcode] = []
        let sut = ScannerContainerViewController(navigationTitle: "", instructionText: "") { scannedBarcodes.append($0) }
        for _ in 0..<3 {
            sut.handleBarcodeDetectionResult(.success([barcode]))
        }
        #expect(scannedBarcodes == [barcode])
        let otherBarcode = ScannedBarcode(payloadStringValue: "DEF456", symbology: .code128)

        // When
        sut.handleBarcodeDetectionResult(.success([]))
        sut.handleBarcodeDetectionResult(.failure(DetectionError.failed))
        for _ in 0..<3 {
            sut.handleBarcodeDetectionResult(.success([otherBarcode]))
        }

        // Then
        #expect(scannedBarcodes == [barcode])
    }

    private enum DetectionError: Error {
        case failed
    }
}
