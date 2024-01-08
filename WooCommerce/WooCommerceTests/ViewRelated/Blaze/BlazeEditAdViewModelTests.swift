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

    // MARK: Tagline
    func test_tagline_footer_text_is_plural_when_multiple_characters_remaining() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
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
                                       adData: sampleAdData,
                                       suggestions: [.fake()],
                                       onSave: { _ in })

        // When
        sut.tagline = ""

        // Then
        XCTAssertEqual(sut.taglineFooterText, BlazeEditAdViewModel.Localization.taglineEmpty)
    }

    // MARK: Description

    func test_description_footer_text_is_plural_when_multiple_characters_remaining() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
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
                                       adData: sampleAdData,
                                       suggestions: [.fake()],
                                       onSave: { _ in })

        // When
        sut.description = ""

        // Then
        XCTAssertEqual(sut.descriptionFooterText, BlazeEditAdViewModel.Localization.descriptionEmpty)
    }

    // MARK: Save button
    func test_save_button_is_disabled_when_no_change_made_to_ad_data() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       adData: sampleAdData,
                                       suggestions: [.fake()],
                                       onSave: { _ in })

        // Then
        XCTAssertFalse(sut.isSaveButtonEnabled)
    }

    func test_save_button_is_enabled_when_image_is_changed() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
                                       adData: sampleAdData,
                                       suggestions: [.fake()],
                                       onSave: { _ in })

        // When
        sut.onAddImage = { _ in
            MediaPickerImage(image: UIImage.calendar,
                             source: .media(media: .fake()))
        }

        // Then
        sut.addImage(from: .siteMediaLibrary)
        waitUntil {
            sut.isSaveButtonEnabled == true
        }
    }

    func test_save_button_is_enabled_when_tagline_is_changed() {
        // Given
        let sut = BlazeEditAdViewModel(siteID: 123,
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
                                       adData: sampleAdData,
                                       suggestions: [.fake()],
                                       onSave: { _ in })

        // When
        sut.description = "Test"

        // Then
        XCTAssertTrue(sut.isSaveButtonEnabled)
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
