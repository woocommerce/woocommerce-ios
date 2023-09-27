import TestKit
import XCTest

@testable import WooCommerce

final class AIToneVoiceViewModelTests: XCTestCase {
    private let siteID: Int64 = 123

    func test_casual_is_the_default_tone() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))

        // When
        let viewModel = AIToneVoiceViewModel(siteID: siteID, userDefaults: defaults)

        // Then
        XCTAssertEqual(viewModel.selectedTone, .casual)
    }

    func test_tone_is_restored_from_user_defaults() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        defaults.setAITone(.flowery, for: siteID)

        // When
        let viewModel = AIToneVoiceViewModel(siteID: siteID, userDefaults: defaults)

        // Then
        XCTAssertEqual(viewModel.selectedTone, .flowery)
    }

    func test_tone_gets_stored_on_selection() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        let viewModel = AIToneVoiceViewModel(siteID: siteID, userDefaults: defaults)

        // When
        viewModel.onSelectTone(.flowery)

        // Then
        XCTAssertEqual(try XCTUnwrap(defaults.aiTone(for: siteID)), .flowery)
    }

    // MARK: - AI tone helpers
    func test_nil_is_returned_when_no_tone_stored() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))

        // Then
        XCTAssertNil(defaults.aiTone(for: siteID))
    }

    func test_stored_tone_is_restored_as_expected() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        defaults[.aiPromptTone] = ["\(siteID)": AIToneVoice.convincing.rawValue]

        // Then
        XCTAssertEqual(try XCTUnwrap(defaults.aiTone(for: siteID)), .convincing)
    }

    func test_tone_gets_stored_as_expected() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        defaults[.aiPromptTone] = ["\(siteID)": AIToneVoice.convincing.rawValue]
        XCTAssertEqual(try XCTUnwrap(defaults.aiTone(for: siteID)), .convincing)

        // When
        defaults.setAITone(.convincing, for: siteID)

        // Then
        let dictionary = try XCTUnwrap(defaults[.aiPromptTone] as? [String: String])
        XCTAssertEqual(dictionary["\(siteID)"], AIToneVoice.convincing.rawValue)
    }
}
