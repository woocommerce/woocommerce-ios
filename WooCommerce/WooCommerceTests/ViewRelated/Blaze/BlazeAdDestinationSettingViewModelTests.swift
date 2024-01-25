import XCTest
@testable import WooCommerce

final class BlazeAdDestinationSettingViewModelTests: XCTestCase {
    private let sampleProductURL = "https://woo.com/product/"
    private let sampleHomeURL = "https://woo.com/"
    private let threeParameters = "one=a&two=b&three=c"
    private let maxParameterLength = 2096

    var finalDestinationURL: String {
        "\(sampleProductURL)?\(threeParameters)"
    }

    func test_save_button_disabled_when_first_entering_screen() {
        // Given
        let sut =  BlazeAdDestinationSettingViewModel(
            productURL: sampleProductURL,
            homeURL: sampleHomeURL,
            finalDestinationURL: finalDestinationURL,
            onSave: { _ in }
        )
        // Then
        XCTAssertTrue(sut.shouldDisableSaveButton)
    }

    func test_save_button_enabled_after_initial_value_is_changed() {
        // Given
        let sut =  BlazeAdDestinationSettingViewModel(
            productURL: sampleProductURL,
            homeURL: sampleHomeURL,
            finalDestinationURL: finalDestinationURL,
            onSave: { _ in }
        )

        // When
        XCTAssertTrue(sut.shouldDisableSaveButton)
        sut.deleteParameter(at: IndexSet(integer: 1))

        // Then
        XCTAssertFalse(sut.shouldDisableSaveButton)
    }

    func test_add_parameter_button_disabled_if_parameters_already_maxed() {
        // Given
        var maxLengthQueryString: String {
            var parameterPrefix = "a="
            let fillLength = maxParameterLength - parameterPrefix.count
            let fillChar = "b"

            parameterPrefix.append(String(repeating: fillChar, count: fillLength))
            return parameterPrefix
        }

        let sut =  BlazeAdDestinationSettingViewModel(
            productURL: sampleProductURL,
            homeURL: sampleHomeURL,
            finalDestinationURL: sampleProductURL + "?" + maxLengthQueryString,
            onSave: { _ in }
        )

        // Then
        XCTAssertTrue(sut.shouldDisableAddParameterButton)
    }


    func test_given_existing_parameters_then_remaining_characters_count_is_correct() {
        // Given
        let sut =  BlazeAdDestinationSettingViewModel(
            productURL: sampleProductURL,
            homeURL: sampleHomeURL,
            finalDestinationURL: finalDestinationURL,
            onSave: { _ in }
        )

        // Then
        XCTAssertEqual(sut.calculateRemainingCharacters(), maxParameterLength - threeParameters.count)
    }

    func test_given_existing_parameters_when_one_is_deleted_then_parameters_count_is_correct() {
        // Given
        let sut =  BlazeAdDestinationSettingViewModel(
            productURL: sampleProductURL,
            homeURL: sampleHomeURL,
            finalDestinationURL: finalDestinationURL,
            onSave: { _ in }
        )

        // When
        XCTAssertEqual(sut.parameters.count, 3)
        sut.deleteParameter(at: IndexSet(integer: 1))

        // Then
        XCTAssertEqual(sut.parameters.count, 2)
    }
}
