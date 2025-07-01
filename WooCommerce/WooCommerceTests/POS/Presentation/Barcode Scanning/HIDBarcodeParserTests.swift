import Testing
import UIKit
@testable import WooCommerce

/// Tests for the HIDBarcodeParser class, which handles parsing of HID input events into barcode scans.
struct HIDBarcodeParserTests {
    @Test("Default configuration uses standard terminating strings")
    func testDefaultConfiguration() {
        let configuration = HIDBarcodeParserConfiguration.default
        #expect(configuration.terminatingStrings == ["\r", "\n"])
        #expect(configuration.minimumBarcodeLength == 6)
    }

    @Test("Custom configuration uses specified terminating strings")
    func testCustomConfiguration() {
        let customTerminators: Set<String> = ["\t", " "]
        let configuration = HIDBarcodeParserConfiguration(terminatingStrings: customTerminators,
                                                          minimumBarcodeLength: 1,
                                                          maximumInterCharacterTime: 1)
        #expect(configuration.terminatingStrings == customTerminators)
    }

    @Test("Parser processes complete barcode scan")
    func testCompleteScan() {
        var results: [Result<String, Error>] = []
        let parser = HIDBarcodeParser(
            configuration: testConfiguration,
            onScan: { result in
                results.append(result)
            }
        )

        // Simulate a complete scan
        parser.processKeyPress(MockUIKey(character: "1"))
        parser.processKeyPress(MockUIKey(character: "2"))
        parser.processKeyPress(MockUIKey(character: "3"))
        parser.processKeyPress(MockUIKey(character: "\r"))

        #expect(results.count == 1)
        if case .success(let barcode) = results.first {
            #expect(barcode == "123")
        } else {
            Issue.record("Expected success result")
        }
    }

    @Test("Parser processes multiple scans")
    func testMultipleScans() {
        var results: [Result<String, Error>] = []
        let parser = HIDBarcodeParser(
            configuration: testConfiguration,
            onScan: { result in
                results.append(result)
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

        #expect(results.count == 2)
        if case .success(let barcode1) = results[0] {
            #expect(barcode1 == "123")
        } else {
            Issue.record("Expected success result for first scan")
        }
        if case .success(let barcode2) = results[1] {
            #expect(barcode2 == "456")
        } else {
            Issue.record("Expected success result for second scan")
        }
    }

    @Test("Parser handles cancelled scan")
    func testCancelledScan() {
        var results: [Result<String, Error>] = []
        let parser = HIDBarcodeParser(
            configuration: testConfiguration,
            onScan: { result in
                results.append(result)
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

        #expect(results.count == 1)
        if case .success(let barcode) = results.first {
            #expect(barcode == "456")
        } else {
            Issue.record("Expected success result")
        }
    }

    @Test("Parser notifies of scans below minimum length")
    func testMinimumLength() {
        var results: [Result<String, Error>] = []
        let configuration = HIDBarcodeParserConfiguration(
            terminatingStrings: ["\r"],
            minimumBarcodeLength: 4,
            maximumInterCharacterTime: 0.1
        )
        let parser = HIDBarcodeParser(
            configuration: configuration,
            onScan: { result in
                results.append(result)
            }
        )

        // Try to scan a short barcode
        parser.processKeyPress(MockUIKey(character: "1"))
        parser.processKeyPress(MockUIKey(character: "2"))
        parser.processKeyPress(MockUIKey(character: "3"))
        parser.processKeyPress(MockUIKey(character: "\r"))

        #expect(results.count == 1)
        if case .failure(let error) = results.first {
            if case HIDBarcodeParserError.scanTooShort(let barcode) = error {
                #expect(barcode == "123")
            } else {
                Issue.record("Expected scanTooShort error")
            }
        } else {
            Issue.record("Expected failure result")
        }
    }

    @Test("Parser notifies of slow typing timeout")
    func testSlowTyping() {
        var results: [Result<String, Error>] = []
        let configuration = HIDBarcodeParserConfiguration.default
        let mockTimeProvider = MockTimeProvider()
        let parser = HIDBarcodeParser(
            configuration: configuration,
            onScan: { result in
                results.append(result)
            },
            timeProvider: mockTimeProvider
        )

        // Simulate slow typing
        parser.processKeyPress(MockUIKey(character: "1"))
        parser.processKeyPress(MockUIKey(character: "2"))
        parser.processKeyPress(MockUIKey(character: "3"))
        mockTimeProvider.advance(by: 0.201) // Just over maximumInterCharacterTime
        parser.processKeyPress(MockUIKey(character: "4"))
        parser.processKeyPress(MockUIKey(character: "\r"))

        #expect(results.count == 2)
        if case .failure(let error) = results.first {
            if case HIDBarcodeParserError.timedOut(let barcode) = error {
                #expect(barcode == "123")
            } else {
                Issue.record("Expected timedOut error")
            }
        } else {
            Issue.record("Expected failure result")
        }
    }

    @Test("Parser accepts slowish scans")
    func testSlowScans() {
        var results: [Result<String, Error>] = []
        let configuration = HIDBarcodeParserConfiguration.default
        let mockTimeProvider = MockTimeProvider()
        let parser = HIDBarcodeParser(
            configuration: configuration,
            onScan: { result in
                results.append(result)
            },
            timeProvider: mockTimeProvider
        )

        // Simulate slow typing
        parser.processKeyPress(MockUIKey(character: "1"))
        mockTimeProvider.advance(by: 0.199) // Just under maximumInterCharacterTime
        parser.processKeyPress(MockUIKey(character: "2"))
        mockTimeProvider.advance(by: 0.199)
        parser.processKeyPress(MockUIKey(character: "3"))
        mockTimeProvider.advance(by: 0.199)
        parser.processKeyPress(MockUIKey(character: "4"))
        mockTimeProvider.advance(by: 0.199)
        parser.processKeyPress(MockUIKey(character: "5"))
        mockTimeProvider.advance(by: 0.199)
        parser.processKeyPress(MockUIKey(character: "6"))
        mockTimeProvider.advance(by: 0.199)
        parser.processKeyPress(MockUIKey(character: "\r"))

        #expect(results.count == 1)
        if case .success(let barcode) = results.first {
            #expect(barcode == "123456")
        } else {
            Issue.record("Expected success result")
        }
    }

    @Test("Parser handles multiple terminating strings")
    func testMultipleTerminatingStrings() {
        var results: [Result<String, Error>] = []
        let configuration = HIDBarcodeParserConfiguration(
            terminatingStrings: ["\r", "\n", "\t"],
            minimumBarcodeLength: 4,
            maximumInterCharacterTime: 0.05
        )
        let parser = HIDBarcodeParser(
            configuration: configuration,
            onScan: { result in
                results.append(result)
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

        #expect(results.count == 2)
        if case .success(let barcode1) = results[0] {
            #expect(barcode1 == "1234")
        } else {
            Issue.record("Expected success result for first scan")
        }
        if case .success(let barcode2) = results[1] {
            #expect(barcode2 == "5678")
        } else {
            Issue.record("Expected success result for second scan")
        }
    }

    @Test("Parser ignores excluded keys as input")
    func testExcludedKeysInput() {
        var results: [Result<String, Error>] = []
        let parser = HIDBarcodeParser(
            configuration: testConfiguration,
            onScan: { result in
                results.append(result)
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

        #expect(results.count == 1)
        if case .success(let barcode) = results.first {
            #expect(barcode == "123")
        } else {
            Issue.record("Expected success result")
        }
    }

    @Test("Parser allows excluded keys as terminators")
    func testExcludedKeysTerminators() {
        var results: [Result<String, Error>] = []
        let parser = HIDBarcodeParser(
            configuration: testConfiguration,
            onScan: { result in
                results.append(result)
            }
        )

        // Try to scan with some excluded keys mixed in
        parser.processKeyPress(MockUIKey(character: "1"))
        parser.processKeyPress(MockUIKey(character: "2"))
        parser.processKeyPress(MockUIKey(character: "3"))
        parser.processKeyPress(MockUIKey(character: "\n", keyCode: .keyboardDownArrow))

        #expect(results.count == 1)
        if case .success(let barcode) = results.first {
            #expect(barcode == "123")
        } else {
            Issue.record("Expected success result")
        }
    }

    @Test("Parser handles scan too short error with default configuration")
    func testScanTooShortWithDefaultConfiguration() {
        var results: [Result<String, Error>] = []
        let parser = HIDBarcodeParser(
            configuration: .default,
            onScan: { result in
                results.append(result)
            }
        )

        // Try to scan a barcode that's too short for default config (min length 6)
        parser.processKeyPress(MockUIKey(character: "1"))
        parser.processKeyPress(MockUIKey(character: "2"))
        parser.processKeyPress(MockUIKey(character: "3"))
        parser.processKeyPress(MockUIKey(character: "4"))
        parser.processKeyPress(MockUIKey(character: "5"))
        parser.processKeyPress(MockUIKey(character: "\r"))

        #expect(results.count == 1)
        if case .failure(let error) = results.first {
            if case HIDBarcodeParserError.scanTooShort(let barcode) = error {
                #expect(barcode == "12345")
            } else {
                Issue.record("Expected scanTooShort error")
            }
        } else {
            Issue.record("Expected failure result")
        }
    }

    @Test("Parser does not show an error row for empty scan")
    func testEmptyScanDoesntError() {
        var results: [Result<String, Error>] = []
        let parser = HIDBarcodeParser(
            configuration: testConfiguration,
            onScan: { result in
                results.append(result)
            }
        )

        // Just send the terminator, no scan input
        parser.processKeyPress(MockUIKey(character: "\r"))

        #expect(results.isEmpty)
    }

    @Test("Parser does not start a timeout for an ignored character")
    func testEmptyScanDoesntStartTimeoutForIgnoredCharacter() {
        var results: [Result<String, Error>] = []
        let mockTimeProvider = MockTimeProvider()
        let parser = HIDBarcodeParser(
            configuration: testConfiguration,
            onScan: { result in
                results.append(result)
            },
            timeProvider: mockTimeProvider
        )

        // Scan a barcode with two terminators, then scan another barcode – only the two codes should be parsed
        parser.processKeyPress(MockUIKey(character: "1"))
        parser.processKeyPress(MockUIKey(character: "2"))
        parser.processKeyPress(MockUIKey(character: "3"))
        parser.processKeyPress(MockUIKey(character: "\r")) // Scan is recognised here
        parser.processKeyPress(MockUIKey(character: "\n", keyCode: .keyboardDownArrow)) // This is ignored

        // Time between scans
        mockTimeProvider.advance(by: 1.5)

        // Scan the second barcode
        parser.processKeyPress(MockUIKey(character: "4")) // Risk of an error row here if `\n` isn't ignored
        parser.processKeyPress(MockUIKey(character: "5"))
        parser.processKeyPress(MockUIKey(character: "6"))
        parser.processKeyPress(MockUIKey(character: "\r"))
        parser.processKeyPress(MockUIKey(character: "\n", keyCode: .keyboardDownArrow))


        #expect(results.count == 2)
        if case .success(let barcode1) = results[0] {
            #expect(barcode1 == "123")
        } else {
            Issue.record("Expected success result for first scan")
        }
        if case .success(let barcode2) = results[1] {
            #expect(barcode2 == "456")
        } else {
            Issue.record("Expected success result for second scan")
        }
    }
}

// MARK: - Test Helpers

private extension HIDBarcodeParserTests {
    var testConfiguration: HIDBarcodeParserConfiguration {
        HIDBarcodeParserConfiguration(terminatingStrings: ["\r", "\n"],
                                      minimumBarcodeLength: 3,
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
