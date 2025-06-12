import Testing
import UIKit
@testable import WooCommerce

struct BarcodeScannerContainerTests {
    @Test("Default configuration uses standard terminating strings")
    func testDefaultConfiguration() {
        let configuration = BarcodeScannerConfiguration.default
        #expect(configuration.terminatingStrings == ["\r", "\n"])
    }

    @Test("Custom configuration uses specified terminating strings")
    func testCustomConfiguration() {
        let customTerminators: Set<String> = ["\t", " "]
        let configuration = BarcodeScannerConfiguration(terminatingStrings: customTerminators)
        #expect(configuration.terminatingStrings == customTerminators)
    }

    @Test("Scanner processes complete barcode scan")
    func testCompleteScan() {
        var scannedCodes: [String] = []
        let scanner = BarcodeScannerHostingController(
            configuration: .default,
            onScan: { code in
                scannedCodes.append(code)
            }
        )

        // Simulate a complete scan
        simulateKeyPress(scanner, "1")
        simulateKeyPress(scanner, "2")
        simulateKeyPress(scanner, "3")
        simulateKeyPress(scanner, "\r")

        #expect(scannedCodes.count == 1)
        #expect(scannedCodes[0] == "123")
    }

    @Test("Scanner processes multiple scans")
    func testMultipleScans() {
        var scannedCodes: [String] = []
        let scanner = BarcodeScannerHostingController(
            configuration: .default,
            onScan: { code in
                scannedCodes.append(code)
            }
        )

        // First scan
        simulateKeyPress(scanner, "1")
        simulateKeyPress(scanner, "2")
        simulateKeyPress(scanner, "3")
        simulateKeyPress(scanner, "\r")

        // Second scan
        simulateKeyPress(scanner, "4")
        simulateKeyPress(scanner, "5")
        simulateKeyPress(scanner, "6")
        simulateKeyPress(scanner, "\r")

        #expect(scannedCodes.count == 2)
        #expect(scannedCodes[0] == "123")
        #expect(scannedCodes[1] == "456")
    }

    @Test("Scanner handles cancelled scan")
    func testCancelledScan() {
        var scannedCodes: [String] = []
        let scanner = BarcodeScannerHostingController(
            configuration: .default,
            onScan: { code in
                scannedCodes.append(code)
            }
        )

        // Start a scan
        simulateKeyPress(scanner, "1")
        simulateKeyPress(scanner, "2")
        simulateKeyPress(scanner, "3")

        // Cancel the scan
        scanner.pressesCancelled(Set(), with: nil)

        // Start a new scan
        simulateKeyPress(scanner, "4")
        simulateKeyPress(scanner, "5")
        simulateKeyPress(scanner, "6")
        simulateKeyPress(scanner, "\r")

        #expect(scannedCodes.count == 1)
        #expect(scannedCodes[0] == "456")
    }

    // MARK: - Helpers

    private func simulateKeyPress(_ scanner: BarcodeScannerHostingController, _ character: String) {
        let press = MockUIPress(character: character)
        scanner.pressesEnded([press], with: nil)
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
