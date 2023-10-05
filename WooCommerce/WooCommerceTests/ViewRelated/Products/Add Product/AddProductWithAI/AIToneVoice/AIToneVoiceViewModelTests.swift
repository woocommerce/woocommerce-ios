import TestKit
import XCTest

@testable import WooCommerce

final class AIToneVoiceViewModelTests: XCTestCase {
    private let siteID: Int64 = 123
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()

        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        analytics = nil
        analyticsProvider = nil
        super.tearDown()
    }

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
    func test_casual_is_returned_when_no_tone_stored() throws {
        // Given
        let uuid = UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: uuid))

        // Then
        XCTAssertEqual(try XCTUnwrap(defaults.aiTone(for: siteID)), .casual)
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

    // MARK: Analytics

    func test_onSelectTone_tracks_tone_selected_event() throws {
        //  Given
        let viewModel = AIToneVoiceViewModel(siteID: siteID, analytics: analytics)

        // When
        viewModel.onSelectTone(.flowery)

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("product_creation_ai_tone_selected"))

        let eventIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "product_creation_ai_tone_selected"}))
        let eventProperties = analyticsProvider.receivedProperties[eventIndex]
        XCTAssertEqual(eventProperties["value"] as? String, "flowery")
    }
}
