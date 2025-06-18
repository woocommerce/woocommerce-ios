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
        parser.processKeyPress(MockUIKey(character: "1"))
        parser.processKeyPress(MockUIKey(character: "2"))
        parser.processKeyPress(MockUIKey(character: "3"))
        parser.processKeyPress(MockUIKey(character: "\r"))

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
        parser.processKeyPress(MockUIKey(character: "1"))
        parser.processKeyPress(MockUIKey(character: "2"))
        parser.processKeyPress(MockUIKey(character: "3"))
        parser.processKeyPress(MockUIKey(character: "\r"))

        // Second scan
        parser.processKeyPress(MockUIKey(character: "4"))
        parser.processKeyPress(MockUIKey(character: "5"))
        parser.processKeyPress(MockUIKey(character: "6"))
        parser.processKeyPress(MockUIKey(character: "\r"))

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
        parser.processKeyPress(MockUIKey(character: "1"))
        parser.processKeyPress(MockUIKey(character: "2"))
        parser.processKeyPress(MockUIKey(character: "3"))

        // Cancel the scan
        parser.cancel()

        // Start a new scan
        parser.processKeyPress(MockUIKey(character: "4"))
        parser.processKeyPress(MockUIKey(character: "5"))
        parser.processKeyPress(MockUIKey(character: "6"))
        parser.processKeyPress(MockUIKey(character: "\r"))

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
        parser.processKeyPress(MockUIKey(character: "1"))
        parser.processKeyPress(MockUIKey(character: "2"))
        parser.processKeyPress(MockUIKey(character: "3"))
        parser.processKeyPress(MockUIKey(character: "\r"))

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

        let configuration = testConfiguration
        let parser = HIDBarcodeParser(
            configuration: configuration,
            onScan: { code in
                scannedCodes.append(code)
            },
            timerFactory: mockTimerFactory
        )

        // Start a scan
        parser.processKeyPress(MockUIKey(character: "1"))
        parser.processKeyPress(MockUIKey(character: "2"))
        parser.processKeyPress(MockUIKey(character: "3"))
        parser.processKeyPress(MockUIKey(character: "4"))

        // Simulate timer firing
        timerBlock?()

        #expect(scannedCodes == ["1234"])
    }

    @Test("Parser ignores slow typing")
    func testSlowTyping() {
        var scannedCodes: [String] = []
        let configuration = HIDBarcodeParserConfiguration.default
        let mockTimeProvider = MockTimeProvider()
        let parser = HIDBarcodeParser(
            configuration: configuration,
            onScan: { code in
                scannedCodes.append(code)
            },
            timeProvider: mockTimeProvider
        )

        // Simulate slow typing
        parser.processKeyPress(MockUIKey(character: "1"))
        parser.processKeyPress(MockUIKey(character: "2"))
        parser.processKeyPress(MockUIKey(character: "3"))
        mockTimeProvider.advance(by: 0.101) // Just over maximumInterCharacterTime
        parser.processKeyPress(MockUIKey(character: "4"))
        parser.processKeyPress(MockUIKey(character: "\r"))

        #expect(scannedCodes.isEmpty)
    }

    @Test("Parser accepts slowish scans")
    func testSlowScans() {
        var scannedCodes: [String] = []
        let configuration = HIDBarcodeParserConfiguration.default
        let mockTimeProvider = MockTimeProvider()
        let parser = HIDBarcodeParser(
            configuration: configuration,
            onScan: { code in
                scannedCodes.append(code)
            },
            timeProvider: mockTimeProvider
        )

        // Simulate slow typing
        parser.processKeyPress(MockUIKey(character: "1"))
        mockTimeProvider.advance(by: 0.099) // Just under maximumInterCharacterTime
        parser.processKeyPress(MockUIKey(character: "2"))
        mockTimeProvider.advance(by: 0.099)
        parser.processKeyPress(MockUIKey(character: "3"))
        mockTimeProvider.advance(by: 0.099)
        parser.processKeyPress(MockUIKey(character: "4"))
        mockTimeProvider.advance(by: 0.099)
        parser.processKeyPress(MockUIKey(character: "\r"))

        #expect(scannedCodes == ["1234"])
    }

    @Test("Parser handles multiple terminating strings")
    func testMultipleTerminatingStrings() {
        var scannedCodes: [String] = []
        let configuration = testConfiguration
        let parser = HIDBarcodeParser(
            configuration: configuration,
            onScan: { code in
                scannedCodes.append(code)
            }
        )

        // Test with different terminating strings
        parser.processKeyPress(MockUIKey(character: "1"))
        parser.processKeyPress(MockUIKey(character: "2"))
        parser.processKeyPress(MockUIKey(character: "3"))
        parser.processKeyPress(MockUIKey(character: "4"))
        parser.processKeyPress(MockUIKey(character: "\n"))

        parser.processKeyPress(MockUIKey(character: "5"))
        parser.processKeyPress(MockUIKey(character: "6"))
        parser.processKeyPress(MockUIKey(character: "7"))
        parser.processKeyPress(MockUIKey(character: "8"))
        parser.processKeyPress(MockUIKey(character: "\t"))

        #expect(scannedCodes == ["1234", "5678"])
    }

    @Test("Parser ignores excluded keys as input")
    func testExcludedKeysInput() {
        var scannedCodes: [String] = []
        let parser = HIDBarcodeParser(
            configuration: testConfiguration,
            onScan: { code in
                scannedCodes.append(code)
            }
        )

        // Try to scan with some excluded keys mixed in
        parser.processKeyPress(MockUIKey(character: "1"))
        parser.processKeyPress(MockUIKey(character: "2"))
        parser.processKeyPress(MockUIKey(character: "3"))
        parser.processKeyPress(MockUIKey(character: "4", keyCode: .keyboardLeftShift))
        parser.processKeyPress(MockUIKey(character: "5", keyCode: .keyboardCapsLock))
        parser.processKeyPress(MockUIKey(character: "6", keyCode: .keyboardDownArrow))
        parser.processKeyPress(MockUIKey(character: "\r"))

        #expect(scannedCodes == ["123"])
    }

    @Test("Parser allows excluded keys as terminators")
    func testExcludedKeysTerminators() {
        var scannedCodes: [String] = []
        let parser = HIDBarcodeParser(
            configuration: testConfiguration,
            onScan: { code in
                scannedCodes.append(code)
            }
        )

        // Try to scan with some excluded keys mixed in
        parser.processKeyPress(MockUIKey(character: "1"))
        parser.processKeyPress(MockUIKey(character: "2"))
        parser.processKeyPress(MockUIKey(character: "3"))
        parser.processKeyPress(MockUIKey(character: "\n", keyCode: .keyboardDownArrow))

        #expect(scannedCodes == ["123"])
    }
}

// MARK: - Test Helpers

private extension HIDBarcodeParserTests {
    var testConfiguration: HIDBarcodeParserConfiguration {
        HIDBarcodeParserConfiguration(terminatingStrings: ["\r", "\n"],
                                      minimumBarcodeLength: 3,
                                      maximumScanTime: 0.3,
                                      maximumInterCharacterTime: 0.05)
    }
}

private class MockUIKey: UIKey {
    private let mockCharacter: String

    // We use a default which won't be ignored when the key is evaluated. Control keys are ignored.
    private let mockKeyCode: UIKeyboardHIDUsage

    init(character: String, keyCode: UIKeyboardHIDUsage = .keypad0) {
        self.mockCharacter = character
        self.mockKeyCode = keyCode
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var characters: String {
        mockCharacter
    }

    override var keyCode: UIKeyboardHIDUsage {
        mockKeyCode
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
