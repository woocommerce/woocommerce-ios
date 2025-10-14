import Testing
import GameController
import UIKit
@testable import PointOfSale
import WooFoundation

@MainActor
struct UIKitBarcodeObserverTests {

    // MARK: - UIPress Processing Tests

    @Test("UIKit observer successfully scans barcode with shift modifier")
    func uikit_observer_with_shift_when_scanned_processes_correctly() {
        // Given
        var results: [Result<String, HIDBarcodeParserError>] = []
        let mockTimeProvider = MockTimeProvider()
        let observer = UIKitBarcodeObserver(
            configuration: Self.testConfiguration,
            analytics: MockPOSAnalytics(),
            onScan: { results.append($0) },
            timeProvider: mockTimeProvider
        )

        // When - Simulate UIPress events with shift modifier
        let shiftedKey = MockUIKey(keyCode: .keyboardA, modifierFlags: [.shift])
        let normalKey = MockUIKey(keyCode: .keyboardB, modifierFlags: [])
        let enterKey = MockUIKey(keyCode: .keyboardReturnOrEnter, modifierFlags: [])

        let shiftedPress = MockUIPress(key: shiftedKey)
        let normalPress = MockUIPress(key: normalKey)
        let enterPress = MockUIPress(key: enterKey)

        let keys = [shiftedPress, normalPress, enterPress]
        processKeysInSequence(keys, observer: observer)

        // Then
        #expect(results.count == 1)
        if case .success(let barcode) = results.first {
            #expect(barcode == "Ab")
        } else {
            Issue.record("Expected successful scan with correct shift handling")
        }
    }

    @Test("UIKit observer ignores UIPress without valid key")
    func uikit_observer_without_key_when_processed_is_ignored() {
        // Given
        var results: [Result<String, HIDBarcodeParserError>] = []
        let mockTimeProvider = MockTimeProvider()
        let observer = UIKitBarcodeObserver(
            configuration: Self.testConfiguration,
            analytics: MockPOSAnalytics(),
            onScan: { results.append($0) },
            timeProvider: mockTimeProvider
        )

        // When - Process UIPress without key
        let pressWithoutKey = MockUIPress(key: nil)
        observer.processUIPress([pressWithoutKey])

        // Then
        #expect(results.isEmpty)
    }

    @Test("UIKit observer ignores untranslatable keys")
    func uikit_observer_with_untranslatable_key_when_processed_is_ignored() {
        // Given
        var results: [Result<String, HIDBarcodeParserError>] = []
        let mockTimeProvider = MockTimeProvider()
        let observer = UIKitBarcodeObserver(
            configuration: Self.testConfiguration,
            analytics: MockPOSAnalytics(),
            onScan: { results.append($0) },
            timeProvider: mockTimeProvider
        )

        // When - Process UIPress with key that can't be translated
        let unsupportedKey = MockUIKey(keyCode: .keyboardF1, modifierFlags: [])
        let enterKey = MockUIKey(keyCode: .keyboardReturnOrEnter, modifierFlags: [])

        let unsupportedPress = MockUIPress(key: unsupportedKey)
        let enterPress = MockUIPress(key: enterKey)

        observer.processUIPress([unsupportedPress, enterPress])

        // Then - Should have no results because no valid characters were processed
        #expect(results.isEmpty)
    }

    @Test("UIKit observer translates number keys correctly")
    func uikit_observer_with_numbers_when_scanned_produces_correct_barcode() {
        // Given
        var results: [Result<String, HIDBarcodeParserError>] = []
        let mockTimeProvider = MockTimeProvider()
        let observer = UIKitBarcodeObserver(
            configuration: Self.testConfiguration,
            analytics: MockPOSAnalytics(),
            onScan: { results.append($0) },
            timeProvider: mockTimeProvider
        )

        // When - Scan number sequence
        let keys = [
            MockUIPress(key: MockUIKey(keyCode: .keyboard1, modifierFlags: [])),
            MockUIPress(key: MockUIKey(keyCode: .keyboard2, modifierFlags: [])),
            MockUIPress(key: MockUIKey(keyCode: .keyboard3, modifierFlags: [])),
            MockUIPress(key: MockUIKey(keyCode: .keyboardReturnOrEnter, modifierFlags: []))
        ]
        processKeysInSequence(keys, observer: observer)

        // Then
        #expect(results.count == 1)
        if case .success(let barcode) = results.first {
            #expect(barcode == "123")
        } else {
            Issue.record("Expected successful number scan")
        }
    }

    @Test("UIKit observer translates letter keys correctly")
    func uikit_observer_with_letters_when_scanned_produces_correct_barcode() {
        // Given
        var results: [Result<String, HIDBarcodeParserError>] = []
        let mockTimeProvider = MockTimeProvider()
        let observer = UIKitBarcodeObserver(
            configuration: Self.testConfiguration,
            analytics: MockPOSAnalytics(),
            onScan: { results.append($0) },
            timeProvider: mockTimeProvider
        )

        // When - Scan letter sequence
        let keys = [
            MockUIPress(key: MockUIKey(keyCode: .keyboardA, modifierFlags: [])),
            MockUIPress(key: MockUIKey(keyCode: .keyboardB, modifierFlags: [])),
            MockUIPress(key: MockUIKey(keyCode: .keyboardC, modifierFlags: [])),
            MockUIPress(key: MockUIKey(keyCode: .keyboardReturnOrEnter, modifierFlags: []))
        ]
        processKeysInSequence(keys, observer: observer)

        // Then
        #expect(results.count == 1)
        if case .success(let barcode) = results.first {
            #expect(barcode == "abc")
        } else {
            Issue.record("Expected successful letter scan")
        }
    }

    @Test("UIKit observer translates punctuation keys correctly")
    func uikit_observer_with_punctuation_when_scanned_produces_correct_barcode() {
        // Given
        var results: [Result<String, HIDBarcodeParserError>] = []
        let mockTimeProvider = MockTimeProvider()
        let observer = UIKitBarcodeObserver(
            configuration: Self.testConfiguration,
            analytics: MockPOSAnalytics(),
            onScan: { results.append($0) },
            timeProvider: mockTimeProvider
        )

        // When - Scan punctuation sequence
        let keys = [
            MockUIPress(key: MockUIKey(keyCode: .keyboardHyphen, modifierFlags: [])),
            MockUIPress(key: MockUIKey(keyCode: .keyboardPeriod, modifierFlags: [])),
            MockUIPress(key: MockUIKey(keyCode: .keyboardComma, modifierFlags: [])),
            MockUIPress(key: MockUIKey(keyCode: .keyboardReturnOrEnter, modifierFlags: []))
        ]
        processKeysInSequence(keys, observer: observer)

        // Then
        #expect(results.count == 1)
        if case .success(let barcode) = results.first {
            #expect(barcode == "-.,")
        } else {
            Issue.record("Expected successful punctuation scan")
        }
    }

    // MARK: - Key Translation Integration Tests
    // These tests verify that key translation works correctly through the full scan flow

    @Test("UIKit observer correctly scans mixed alphanumeric barcode")
    func uikit_observer_with_mixed_alphanumeric_when_scanned_produces_correct_barcode() {
        // Given
        var results: [Result<String, HIDBarcodeParserError>] = []
        let mockTimeProvider = MockTimeProvider()
        let observer = UIKitBarcodeObserver(
            configuration: Self.testConfiguration,
            analytics: MockPOSAnalytics(),
            onScan: { results.append($0) },
            timeProvider: mockTimeProvider
        )

        // When - Scan mixed alphanumeric barcode "A1B2C3"
        let keys = [
            MockUIPress(key: MockUIKey(keyCode: .keyboardA, modifierFlags: [])),
            MockUIPress(key: MockUIKey(keyCode: .keyboard1, modifierFlags: [])),
            MockUIPress(key: MockUIKey(keyCode: .keyboardB, modifierFlags: [])),
            MockUIPress(key: MockUIKey(keyCode: .keyboard2, modifierFlags: [])),
            MockUIPress(key: MockUIKey(keyCode: .keyboardC, modifierFlags: [])),
            MockUIPress(key: MockUIKey(keyCode: .keyboard3, modifierFlags: [])),
            MockUIPress(key: MockUIKey(keyCode: .keyboardReturnOrEnter, modifierFlags: []))
        ]
        processKeysInSequence(keys, observer: observer)

        // Then
        #expect(results.count == 1)
        if case .success(let barcode) = results.first {
            #expect(barcode == "a1b2c3")
        } else {
            Issue.record("Expected successful mixed alphanumeric scan")
        }
    }

    @Test("UIKit observer correctly scans barcode with special characters")
    func uikit_observer_with_special_characters_when_scanned_produces_correct_barcode() {
        // Given
        var results: [Result<String, HIDBarcodeParserError>] = []
        let observer = UIKitBarcodeObserver(
            configuration: Self.testConfiguration,
            analytics: MockPOSAnalytics(),
            onScan: {
                results.append($0)
            }
        )

        // When - Scan barcode with special characters "A-1.B"
        let keys = [
            MockUIPress(key: MockUIKey(keyCode: .keyboardA, modifierFlags: [])),
            MockUIPress(key: MockUIKey(keyCode: .keyboardHyphen, modifierFlags: [])),
            MockUIPress(key: MockUIKey(keyCode: .keyboard1, modifierFlags: [])),
            MockUIPress(key: MockUIKey(keyCode: .keyboardPeriod, modifierFlags: [])),
            MockUIPress(key: MockUIKey(keyCode: .keyboardB, modifierFlags: [])),
            MockUIPress(key: MockUIKey(keyCode: .keyboardReturnOrEnter, modifierFlags: []))
        ]
        processKeysInSequence(keys, observer: observer)

        // Then
        #expect(results.count == 1)
        if case .success(let barcode) = results.first {
            #expect(barcode == "a-1.b")
        } else {
            Issue.record("Expected successful special character scan")
        }
    }

    @Test("UIKit observer ignores unsupported keys and produces no scan")
    func uikit_observer_with_unsupported_keys_when_scanned_produces_no_results() {
        // Given
        var results: [Result<String, HIDBarcodeParserError>] = []
        let mockTimeProvider = MockTimeProvider()
        let observer = UIKitBarcodeObserver(
            configuration: Self.testConfiguration,
            analytics: MockPOSAnalytics(),
            onScan: { results.append($0) },
            timeProvider: mockTimeProvider
        )

        // When - Try to scan with unsupported keys (F1, F2) followed by terminator
        let keys = [
            MockUIPress(key: MockUIKey(keyCode: .keyboardF1, modifierFlags: [])),
            MockUIPress(key: MockUIKey(keyCode: .keyboardF2, modifierFlags: [])),
            MockUIPress(key: MockUIKey(keyCode: .keyboardReturnOrEnter, modifierFlags: []))
        ]
        processKeysInSequence(keys, observer: observer)

        // Then - Should have no results because unsupported keys are ignored
        #expect(results.isEmpty)
    }

    // MARK: - Helpers

    static let testConfiguration = HIDBarcodeParserConfiguration(
        terminatingStrings: ["\r", "\n"],
        minimumBarcodeLength: 2,
        maximumInterCharacterTime: 0.05
    )

    /// Helper method to process keys in sequence
    private func processKeysInSequence(_ keys: [MockUIPress], observer: UIKitBarcodeObserver) {
        for key in keys {
            observer.processUIPress([key])
        }
    }
}

// MARK: - Mock Classes for Testing

private class MockUIKey: UIKey {
    private let _keyCode: UIKeyboardHIDUsage
    private let _modifierFlags: UIKeyModifierFlags

    init(keyCode: UIKeyboardHIDUsage, modifierFlags: UIKeyModifierFlags) {
        self._keyCode = keyCode
        self._modifierFlags = modifierFlags
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var keyCode: UIKeyboardHIDUsage {
        return _keyCode
    }

    override var modifierFlags: UIKeyModifierFlags {
        return _modifierFlags
    }
}

private class MockUIPress: UIPress {
    private let _key: UIKey?

    init(key: UIKey?) {
        self._key = key
        super.init()
    }

    override var key: UIKey? {
        return _key
    }
}
