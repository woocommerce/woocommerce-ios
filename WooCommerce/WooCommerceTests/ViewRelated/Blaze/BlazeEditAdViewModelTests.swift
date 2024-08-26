import Foundation
import XCTest
import Yosemite
import Photos
import struct Networking.BlazeAISuggestion
@testable import WooCommerce

final class BlazeEditAdViewModelTests: XCTestCase {
    private let sampleAdData = BlazeEditAdData(image: MediaPickerImage(image: UIImage.emailImage,
                                                                       source: .media(media: .fake())),
                                               tagline: "Sample Tagline",
                                               description: "Sample description")

    private let sampleAISuggestions = [BlazeAISuggestion(siteName: "First suggested tagline", textSnippet: "First suggested description"),
                                       BlazeAISuggestion(siteName: "Second suggested tagline", textSnippet: "Second suggested description"),
                                       BlazeAISuggestion(siteName: "Third suggested tagline", textSnippet: "Third suggested description")]

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

    // MARK: Image size error

    func test_shouldDisplayImageSizeErrorAlert_turns_false_upon_selecting_image_with_invalid_size() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: [.fake()],
                                       onSave: { _ in })

        // When
        sut.onAddImage = { _ in
            // Image less than expected size 400*400
            MediaPickerImage(image: UIImage.gridicon(.calendar, size: .init(width: 100, height: 100)),
                             source: .media(media: .fake()))
        }

        // Then
        sut.addImage(from: .siteMediaLibrary)
        waitUntil {
            sut.shouldDisplayImageSizeErrorAlert == true
        }
    }

    // MARK: Tagline
    func test_tagline_footer_text_is_plural_when_multiple_characters_remaining() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: [.fake()],
                                       onSave: { _ in })
        // When
        sut.tagline = sampleString(length: 1)

        // Then
        let expectedString = String(format: BlazeEditAdViewModel.Localization.LengthLimit.plural, 31)
        XCTAssertEqual(sut.taglineFooterText, expectedString)
    }

    func test_tagline_footer_text_is_singular_when_one_character_remaining() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: [.fake()],
                                       onSave: { _ in })
        // When
        sut.tagline = sampleString(length: 31)

        // Then
        let expectedString = String(format: BlazeEditAdViewModel.Localization.LengthLimit.singular, 1)
        XCTAssertEqual(sut.taglineFooterText, expectedString)
    }

    func test_tagline_footer_text_is_plural_when_zero_characters_remaining() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: [.fake()],
                                       onSave: { _ in })
        // When
        sut.tagline = sampleString(length: 32)

        // Then
        let expectedString = String(format: BlazeEditAdViewModel.Localization.LengthLimit.plural, 0)
        XCTAssertEqual(sut.taglineFooterText, expectedString)
    }

    func test_tagline_footer_text_shows_error_when_tagline_is_empty() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: [.fake()],
                                       onSave: { _ in })

        // When
        sut.tagline = ""

        // Then
        XCTAssertEqual(sut.taglineFooterText, BlazeEditAdViewModel.Localization.taglineEmpty)
    }

    func test_tagline_footer_text_shows_error_when_tagline_exceeds_limit() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: [.fake()],
                                       onSave: { _ in })

        // When
        sut.tagline = String(repeating: "a", count: BlazeEditAdViewModel.Constants.taglineMaxLength + 1)

        // Then
        let expectedMessage = String(format: BlazeEditAdViewModel.Localization.taglineLengthExceedsLimit, BlazeEditAdViewModel.Constants.taglineMaxLength)
        XCTAssertEqual(sut.taglineFooterText, expectedMessage)
    }

    // MARK: Description

    func test_description_footer_text_is_plural_when_multiple_characters_remaining() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: [.fake()],
                                       onSave: { _ in })
        // When
        sut.description = sampleString(length: 1)

        // Then
        let expectedString = String(format: BlazeEditAdViewModel.Localization.LengthLimit.plural, 139)
        XCTAssertEqual(sut.descriptionFooterText, expectedString)
    }

    func test_description_footer_text_is_singular_when_one_character_remaining() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: [.fake()],
                                       onSave: { _ in })
        // When
        sut.description = sampleString(length: 139)

        // Then
        let expectedString = String(format: BlazeEditAdViewModel.Localization.LengthLimit.singular, 1)
        XCTAssertEqual(sut.descriptionFooterText, expectedString)
    }

    func test_description_footer_text_is_plural_when_zero_characters_remaining() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: [.fake()],
                                       onSave: { _ in })
        // When
        sut.description = sampleString(length: 140)

        // Then
        let expectedString = String(format: BlazeEditAdViewModel.Localization.LengthLimit.plural, 0)
        XCTAssertEqual(sut.descriptionFooterText, expectedString)
    }

    func test_description_footer_text_shows_error_when_description_is_empty() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: [.fake()],
                                       onSave: { _ in })

        // When
        sut.description = ""

        // Then
        XCTAssertEqual(sut.descriptionFooterText, BlazeEditAdViewModel.Localization.descriptionEmpty)
    }

    func test_description_footer_text_shows_error_when_description_exceeds_limit() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: [.fake()],
                                       onSave: { _ in })

        // When
        sut.description = String(repeating: "a", count: BlazeEditAdViewModel.Constants.descriptionMaxLength + 1)

        // Then
        let expectedMessage = String(
            format: BlazeEditAdViewModel.Localization.descriptionLengthExceedsLimit,
            BlazeEditAdViewModel.Constants.descriptionMaxLength
        )
        XCTAssertEqual(sut.descriptionFooterText, expectedMessage)
    }

    // MARK: Save button
    func test_save_button_is_disabled_when_no_change_made_to_ad_data() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: [.fake()],
                                       onSave: { _ in })

        // Then
        XCTAssertFalse(sut.isSaveButtonEnabled)
    }

    func test_save_button_is_enabled_when_image_is_changed() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: [.fake()],
                                       onSave: { _ in })

        // When
        sut.onAddImage = { _ in
            MediaPickerImage(image: UIImage.gridicon(.calendar, size: .init(width: 600, height: 600)),
                             source: .media(media: .fake()))
        }

        // Then
        sut.addImage(from: .siteMediaLibrary)
        waitUntil {
            sut.isSaveButtonEnabled == true
        }
    }

    func test_save_button_is_enabled_when_tagline_is_changed_even_though_image_is_nil() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: BlazeEditAdData(image: nil,
                                                               tagline: "Sample Tagline",
                                                               description: "Sample description"),
                                       suggestions: [.fake()],
                                       onSave: { _ in })

        // When
        sut.tagline = "Test"

        // Then
        XCTAssertTrue(sut.isSaveButtonEnabled)
    }

    func test_save_button_is_enabled_when_tagline_is_changed() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: [.fake()],
                                       onSave: { _ in })

        // When
        sut.tagline = "Test"

        // Then
        XCTAssertTrue(sut.isSaveButtonEnabled)
    }

    func test_save_button_is_enabled_when_description_is_changed() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: [.fake()],
                                       onSave: { _ in })

        // When
        sut.description = "Test"

        // Then
        XCTAssertTrue(sut.isSaveButtonEnabled)
    }

    func test_save_button_is_disabled_when_tagline_exceeds_character_limit() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: [.fake()],
                                       onSave: { _ in })

        // When
        sut.tagline = String(repeating: "a", count: BlazeEditAdViewModel.Constants.taglineMaxLength + 1)

        // Then
        XCTAssertFalse(sut.isSaveButtonEnabled)
    }

    func test_save_button_is_disabled_when_description_exceeds_character_limit() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: [.fake()],
                                       onSave: { _ in })

        // When
        sut.description = String(repeating: "a", count: BlazeEditAdViewModel.Constants.descriptionMaxLength + 1)

        // Then
        XCTAssertFalse(sut.isSaveButtonEnabled)
    }

    func test_save_button_is_enabled_when_description_is_changed_even_though_image_is_nil() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: BlazeEditAdData(image: nil,
                                                               tagline: "Sample Tagline",
                                                               description: "Sample description"),
                                       suggestions: [.fake()],
                                       onSave: { _ in })

        // When
        sut.description = "Test"

        // Then
        XCTAssertTrue(sut.isSaveButtonEnabled)
    }

    // MARK: Can select previous suggestions

    func test_canSelectPreviousSuggestion_is_false_initially() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: [.fake(), .fake(), .fake()],
                                       onSave: { _ in })

        // Then
        XCTAssertFalse(sut.canSelectPreviousSuggestion)
    }

    func test_canSelectPreviousSuggestion_is_true_when_second_suggestion_selected() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: sampleAISuggestions,
                                       onSave: { _ in })

        // When
        sut.didTapNext()
        sut.didTapNext()

        XCTAssertEqual(sut.tagline, "Second suggested tagline")

        // Then
        XCTAssertTrue(sut.canSelectPreviousSuggestion)
    }

    func test_canSelectPreviousSuggestion_is_false_when_first_suggestion_selected() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: sampleAISuggestions,
                                       onSave: { _ in })

        // When
        sut.didTapNext()
        sut.didTapPrevious()

        XCTAssertEqual(sut.tagline, "First suggested tagline")

        // Then
        XCTAssertFalse(sut.canSelectPreviousSuggestion)
    }

    // MARK: Can select next suggestions

    func test_canSelectNextSuggestion_is_true_initially() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: sampleAISuggestions,
                                       onSave: { _ in })

        // Then
        XCTAssertTrue(sut.canSelectNextSuggestion)
    }

    func test_canSelectNextSuggestion_is_false_when_last_suggestion_selected() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: sampleAISuggestions,
                                       onSave: { _ in })

        // When
        sut.didTapNext()
        sut.didTapNext()
        sut.didTapNext()

        XCTAssertEqual(sut.tagline, "Third suggested tagline")

        // Then
        XCTAssertFalse(sut.canSelectNextSuggestion)
    }

    // MARK: `didTapPrevious`

    func test_didTapPrevious_does_not_change_selection_if_no_suggestion_selected() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: sampleAISuggestions,
                                       onSave: { _ in })

        // When
        sut.didTapPrevious()

        // Then
        XCTAssertEqual(sut.tagline, "Sample Tagline")
    }

    func test_didTapPrevious_selects_previous_item_when_a_suggestion_selected_already() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: sampleAISuggestions,
                                       onSave: { _ in })

        sut.didTapNext()
        sut.didTapNext()
        XCTAssertEqual(sut.tagline, "Second suggested tagline")

        // When
        sut.didTapPrevious()

        // Then
        XCTAssertEqual(sut.tagline, "First suggested tagline")
    }

    // MARK: `didTapNext`

    func test_didTapNext_selects_first_item_when_no_suggestion_is_selected_already() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: sampleAISuggestions,
                                       onSave: { _ in })

        // When
        sut.didTapNext()

        // Then
        XCTAssertEqual(sut.tagline, "First suggested tagline")
    }

    func test_didTapNext_selects_next_item_when_a_suggestion_selected_already() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: sampleAISuggestions,
                                       onSave: { _ in })
        sut.didTapNext()
        XCTAssertEqual(sut.tagline, "First suggested tagline")

        // When
        sut.didTapNext()

        // Then
        XCTAssertEqual(sut.tagline, "Second suggested tagline")
    }

    func test_didTapNext_does_not_change_selection_when_the_last_suggestion_selected() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: sampleAISuggestions,
                                       onSave: { _ in })
        sut.didTapNext()
        sut.didTapNext()
        sut.didTapNext()
        XCTAssertEqual(sut.tagline, "Third suggested tagline")

        // When
        sut.didTapNext()

        // Then
        XCTAssertEqual(sut.tagline, "Third suggested tagline")
    }

    // MARK: Preselect suggestion
    func test_it_preselects_suggestion_if_injected_tagline_and_description_match() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: BlazeEditAdData(image: MediaPickerImage(image: UIImage.emailImage,
                                                                                       source: .media(media: .fake())),
                                                               tagline: sampleAISuggestions[1].siteName,
                                                               description: sampleAISuggestions[1].textSnippet),
                                       suggestions: sampleAISuggestions,
                                       onSave: { _ in })

        // Then
        // Check that suggestion at index 1 is selected by testing button states
        XCTAssertTrue(sut.canSelectPreviousSuggestion)
        XCTAssertTrue(sut.canSelectNextSuggestion)
    }

    // MARK: - isTaglineValidated and isDescriptionValidated

    func test_isTaglineValidated_is_updated_correctly_depending_on_tagline_length() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: sampleAISuggestions,
                                       onSave: { _ in })

        // When
        sut.tagline = ""

        // Then
        XCTAssertFalse(sut.isTaglineValidated)

        // When
        sut.tagline = String(repeating: "a", count: BlazeEditAdViewModel.Constants.taglineMaxLength)

        // Then
        XCTAssertTrue(sut.isTaglineValidated)

        // When
        sut.tagline = String(repeating: "a", count: BlazeEditAdViewModel.Constants.taglineMaxLength + 1)

        // Then
        XCTAssertFalse(sut.isTaglineValidated)
    }

    func test_isDescriptionValidated_is_updated_correctly_depending_on_description_length() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: sampleAdData,
                                       suggestions: sampleAISuggestions,
                                       onSave: { _ in })

        // When
        sut.description = ""

        // Then
        XCTAssertFalse(sut.isDescriptionValidated)

        // When
        sut.description = String(repeating: "a", count: BlazeEditAdViewModel.Constants.descriptionMaxLength)

        // Then
        XCTAssertTrue(sut.isDescriptionValidated)

        // When
        sut.description = String(repeating: "a", count: BlazeEditAdViewModel.Constants.descriptionMaxLength + 1)

        // Then
        XCTAssertFalse(sut.isDescriptionValidated)
    }

    // MARK: Analytics
    func test_AI_suggestion_arrows_tap_is_tracked() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: BlazeEditAdData(image: MediaPickerImage(image: UIImage.emailImage,
                                                                                       source: .media(media: .fake())),
                                                               tagline: sampleAISuggestions[1].siteName,
                                                               description: sampleAISuggestions[1].textSnippet),
                                       suggestions: sampleAISuggestions,
                                       analytics: analytics,
                                       onSave: { _ in })

        // When
        sut.didTapPrevious()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.filter { $0 == ("blaze_creation_edit_ad_ai_suggestion_tapped")}.count, 1)

        // When
        sut.didTapNext()

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.filter { $0 == ("blaze_creation_edit_ad_ai_suggestion_tapped")}.count, 2)
    }

    func test_save_button_tap_is_tracked() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       productID: 34,
                                       adData: BlazeEditAdData(image: MediaPickerImage(image: UIImage.emailImage,
                                                                                       source: .media(media: .fake())),
                                                               tagline: sampleAISuggestions[1].siteName,
                                                               description: sampleAISuggestions[1].textSnippet),
                                       suggestions: sampleAISuggestions,
                                       analytics: analytics,
                                       onSave: { _ in })

        // When
        sut.didTapSave()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_creation_edit_ad_save_tapped"))
    }
}

private extension BlazeEditAdViewModelTests {
    func sampleString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var string = ""
        for _ in 1...length {
            let letter = letters.randomElement() ?? "a"
            string.append(letter)
        }
        return string
    }
}
