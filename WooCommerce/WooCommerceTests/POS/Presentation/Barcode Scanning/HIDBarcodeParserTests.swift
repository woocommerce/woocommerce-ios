import Testing
import UIKit
@testable import WooCommerce

/// Tests for the HIDBarcodeParser class, which handles parsing of HID input events into barcode scans.
struct HIDBarcodeParserTests {
    @Test("Default configuration uses standard terminating strings")
    func testDefaultConfiguration() {
        let configuration = HIDBarcodeParserConfiguration.default
        #expect(configuration.terminatingStrings == ["\r", "\n"])
    }

    @Test("Custom configuration uses specified terminating strings")
    func testCustomConfiguration() {
        let customTerminators: Set<String> = ["\t", " "]
        let configuration = HIDBarcodeParserConfiguration(terminatingStrings: customTerminators)
        #expect(configuration.terminatingStrings == customTerminators)
    }

    @Test("Parser processes complete barcode scan")
    func testCompleteScan() {
        var scannedCodes: [String] = []
        let parser = HIDBarcodeParser(
            configuration: .default,
            onScan: { code in
                scannedCodes.append(code)
            }
        )

        // Simulate a complete scan
        parser.processKeyPress("1")
        parser.processKeyPress("2")
        parser.processKeyPress("3")
        parser.processKeyPress("\r")

        #expect(scannedCodes.count == 1)
        #expect(scannedCodes[0] == "123")
    }

    @Test("Parser processes multiple scans")
    func testMultipleScans() {
        var scannedCodes: [String] = []
        let parser = HIDBarcodeParser(
            configuration: .default,
            onScan: { code in
                scannedCodes.append(code)
            }
        )

        // First scan
        parser.processKeyPress("1")
        parser.processKeyPress("2")
        parser.processKeyPress("3")
        parser.processKeyPress("\r")

        // Second scan
        parser.processKeyPress("4")
        parser.processKeyPress("5")
        parser.processKeyPress("6")
        parser.processKeyPress("\r")

        #expect(scannedCodes.count == 2)
        #expect(scannedCodes[0] == "123")
        #expect(scannedCodes[1] == "456")
    }

    @Test("Parser handles cancelled scan")
    func testCancelledScan() {
        var scannedCodes: [String] = []
        let parser = HIDBarcodeParser(
            configuration: .default,
            onScan: { code in
                scannedCodes.append(code)
            }
        )

        // Start a scan
        parser.processKeyPress("1")
        parser.processKeyPress("2")
        parser.processKeyPress("3")

        // Cancel the scan
        parser.cancel()

        // Start a new scan
        parser.processKeyPress("4")
        parser.processKeyPress("5")
        parser.processKeyPress("6")
        parser.processKeyPress("\r")

        #expect(scannedCodes.count == 1)
        #expect(scannedCodes[0] == "456")
    }
}

// MARK: - Test Helpers

private class MockUIPress: UIPress {
    private let mockCharacter: String

    init(character: String) {
        self.mockCharacter = character
        super.init()
    }

    override var key: UIKey? {
        MockUIKey(character: mockCharacter)
    }
}

private class MockUIKey: UIKey {
    private let mockCharacter: String

    init(character: String) {
        self.mockCharacter = character
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var charactersIgnoringModifiers: String {
        mockCharacter
    }
}
