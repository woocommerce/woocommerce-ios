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
        let configuration = HIDBarcodeParserConfiguration(terminatingStrings: customTerminators,
                                                          minimumBarcodeLength: 1,
                                                          maximumScanTime: 1,
                                                          maximumInterCharacterTime: 1)
        #expect(configuration.terminatingStrings == customTerminators)
    }

    @Test("Parser processes complete barcode scan")
    func testCompleteScan() {
        var scannedCodes: [String] = []
        let parser = HIDBarcodeParser(
            configuration: testConfiguration,
            onScan: { code in
                scannedCodes.append(code)
            }
        )

        // Simulate a complete scan
        parser.processKeyPress("1")
        parser.processKeyPress("2")
        parser.processKeyPress("3")
        parser.processKeyPress("\r")

        #expect(scannedCodes == ["123"])
    }

    @Test("Parser processes multiple scans")
    func testMultipleScans() {
        var scannedCodes: [String] = []
        let parser = HIDBarcodeParser(
            configuration: testConfiguration,
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

        #expect(scannedCodes == ["123", "456"])
    }

    @Test("Parser handles cancelled scan")
    func testCancelledScan() {
        var scannedCodes: [String] = []
        let parser = HIDBarcodeParser(
            configuration: testConfiguration,
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

        #expect(scannedCodes == ["456"])
    }

    @Test("Parser ignores scans below minimum length")
    func testMinimumLength() {
        var scannedCodes: [String] = []
        let configuration = HIDBarcodeParserConfiguration(
            terminatingStrings: ["\r"],
            minimumBarcodeLength: 4,
            maximumScanTime: 1.5,
            maximumInterCharacterTime: 0.1
        )
        let parser = HIDBarcodeParser(
            configuration: configuration,
            onScan: { code in
                scannedCodes.append(code)
            }
        )

        // Try to scan a short barcode
        parser.processKeyPress("1")
        parser.processKeyPress("2")
        parser.processKeyPress("3")
        parser.processKeyPress("\r")

        #expect(scannedCodes.isEmpty)
    }

    @Test("Parser processes scan after maximum scan time")
    func testMaximumScanTime() {
        var scannedCodes: [String] = []
        var timerBlock: (() -> Void)?

        let mockTimerFactory = MockTimerFactory { interval, repeats, block in
            timerBlock = block
            return Timer()
        }

        let configuration = HIDBarcodeParserConfiguration(
            terminatingStrings: ["\r"],
            minimumBarcodeLength: 4,
            maximumScanTime: 0.01,
            maximumInterCharacterTime: 0.05
        )
        let parser = HIDBarcodeParser(
            configuration: configuration,
            onScan: { code in
                scannedCodes.append(code)
            },
            timerFactory: mockTimerFactory
        )

        // Start a scan
        parser.processKeyPress("1")
        parser.processKeyPress("2")
        parser.processKeyPress("3")
        parser.processKeyPress("4")

        // Simulate timer firing
        timerBlock?()

        #expect(scannedCodes == ["1234"])
    }

    @Test("Parser ignores slow typing")
    func testSlowTyping() {
        var scannedCodes: [String] = []
        let configuration = HIDBarcodeParserConfiguration(
            terminatingStrings: ["\r"],
            minimumBarcodeLength: 4,
            maximumScanTime: 0.3,
            maximumInterCharacterTime: 0.05
        )
        let parser = HIDBarcodeParser(
            configuration: configuration,
            onScan: { code in
                scannedCodes.append(code)
            }
        )

        // Simulate slow typing
        parser.processKeyPress("1")
        parser.processKeyPress("2")
        parser.processKeyPress("3")
        Thread.sleep(forTimeInterval: 0.06)
        parser.processKeyPress("4")
        parser.processKeyPress("\r")

        #expect(scannedCodes.isEmpty)
    }

    @Test("Parser accepts slowish scans")
    func testSlowScans() {
        var scannedCodes: [String] = []
        let configuration = HIDBarcodeParserConfiguration(
            terminatingStrings: ["\r"],
            minimumBarcodeLength: 4,
            maximumScanTime: 0.3,
            maximumInterCharacterTime: 0.05
        )
        let parser = HIDBarcodeParser(
            configuration: configuration,
            onScan: { code in
                scannedCodes.append(code)
            }
        )

        // Simulate slow typing
        parser.processKeyPress("1")
        Thread.sleep(forTimeInterval: 0.03)
        parser.processKeyPress("2")
        Thread.sleep(forTimeInterval: 0.03)
        parser.processKeyPress("3")
        Thread.sleep(forTimeInterval: 0.03)
        parser.processKeyPress("4")
        Thread.sleep(forTimeInterval: 0.03)
        parser.processKeyPress("\r")

        #expect(scannedCodes == ["1234"])
    }

    @Test("Parser handles multiple terminating strings")
    func testMultipleTerminatingStrings() {
        var scannedCodes: [String] = []
        let configuration = HIDBarcodeParserConfiguration(
            terminatingStrings: ["\r", "\n", "\t"],
            minimumBarcodeLength: 4,
            maximumScanTime: 1.5,
            maximumInterCharacterTime: 0.1
        )
        let parser = HIDBarcodeParser(
            configuration: configuration,
            onScan: { code in
                scannedCodes.append(code)
            }
        )

        // Test with different terminating strings
        parser.processKeyPress("1")
        parser.processKeyPress("2")
        parser.processKeyPress("3")
        parser.processKeyPress("4")
        parser.processKeyPress("\n")

        parser.processKeyPress("5")
        parser.processKeyPress("6")
        parser.processKeyPress("7")
        parser.processKeyPress("8")
        parser.processKeyPress("\t")

        #expect(scannedCodes == ["1234", "5678"])
    }
}

// MARK: - Test Helpers

private extension HIDBarcodeParserTests {
    var testConfiguration: HIDBarcodeParserConfiguration {
        HIDBarcodeParserConfiguration(terminatingStrings: ["\r"],
                                      minimumBarcodeLength: 3,
                                      maximumScanTime: 0.3,
                                      maximumInterCharacterTime: 0.05)
    }
}

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

private class MockTimerFactory: TimerFactory {
    private let createTimerBlock: (TimeInterval, Bool, @escaping () -> Void) -> Timer

    init(createTimerBlock: @escaping (TimeInterval, Bool, @escaping () -> Void) -> Timer) {
        self.createTimerBlock = createTimerBlock
    }

    func createTimer(interval: TimeInterval, repeats: Bool, block: @escaping () -> Void) -> Timer {
        createTimerBlock(interval, repeats, block)
    }
}
