import XCTest
@testable import WooCommerce

final class BlazeAdDestinationSettingViewModelTests: XCTestCase {
    private let sampleProductURL = "https://woocommerce.com/product/"
    private let sampleHomeURL = "https://woocommerce.com/"
    private let threeParameters = "one=a&two=b&three=c"
    private let maxParameterLength = 2096

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        analyticsProvider = nil
        analytics = nil
        super.tearDown()
    }

    var finalDestinationURL: String {
        "\(sampleProductURL)?\(threeParameters)"
    }

    func test_save_button_disabled_when_first_entering_screen() {
        // Given
        let sut =  BlazeAdDestinationSettingViewModel(
            productURL: sampleProductURL,
            homeURL: sampleHomeURL,
            finalDestinationURL: finalDestinationURL,
            onSave: { _, _ in }
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
            onSave: { _, _ in }
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
            onSave: { _, _ in }
        )

        // Then
        XCTAssertTrue(sut.shouldDisableAddParameterButton)
    }

    func test_parameter_list_is_correct_when_there_are_parameters_in_base_url() {
        // Given
        let defaultParam = "product=bonsai-plant"
        let sut =  BlazeAdDestinationSettingViewModel(
            productURL: sampleProductURL + "?" + defaultParam,
            homeURL: sampleHomeURL,
            finalDestinationURL: sampleProductURL,
            onSave: { _, _ in }
        )

        // Then
        XCTAssertEqual(sut.parameters, [])
    }

    func test_when_destination_changed_then_final_url_is_updated() {
        // Given
        let sut =  BlazeAdDestinationSettingViewModel(
            productURL: sampleProductURL,
            homeURL: sampleHomeURL,
            finalDestinationURL: finalDestinationURL,
            onSave: { _, _ in }
        )

        // When
        XCTAssertEqual(sut.selectedDestinationType, .product)
        sut.setDestinationType(as: .home)

        // Then
        let updatedURL = "\(sampleHomeURL)?\(threeParameters)"
        XCTAssertEqual(sut.selectedDestinationType, .home)
        XCTAssertTrue(sut.finalDestinationLabel.contains(updatedURL))
    }

    func test_final_url_is_correct_when_there_are_parameters_in_base_url() {
        // Given
        let productURL = sampleProductURL + "?product=bonsai-plant"
        let sut =  BlazeAdDestinationSettingViewModel(
            productURL: productURL,
            homeURL: sampleHomeURL,
            finalDestinationURL: productURL,
            onSave: { _, _ in }
        )

        // When
        sut.addNewParameter(item: .init(key: "test", value: "123"))

        // Then
        XCTAssertTrue(sut.finalDestinationLabel.hasSuffix(productURL + "&test=123"))
    }

    func test_given_existing_parameters_then_remaining_characters_count_is_correct() {
        // Given
        let sut =  BlazeAdDestinationSettingViewModel(
            productURL: sampleProductURL,
            homeURL: sampleHomeURL,
            finalDestinationURL: finalDestinationURL,
            onSave: { _, _ in }
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
            onSave: { _, _ in }
        )

        // When
        XCTAssertEqual(sut.parameters.count, 3)
        sut.deleteParameter(at: IndexSet(integer: 1))

        // Then
        XCTAssertEqual(sut.parameters.count, 2)
    }

    func test_remaining_character_count_is_correct_when_there_are_parameters_in_base_url() {
        // Given
        let defaultParam = "product=bonsai-plant"
        let sut =  BlazeAdDestinationSettingViewModel(
            productURL: sampleProductURL,
            homeURL: sampleHomeURL,
            finalDestinationURL: sampleProductURL + "?" + defaultParam,
            onSave: { _, _ in }
        )

        // Then
        XCTAssertEqual(sut.calculateRemainingCharacters(), maxParameterLength - defaultParam.count)

        // When
        sut.addNewParameter(item: .init(key: "test", value: "123"))

        // Then
        XCTAssertEqual(sut.calculateRemainingCharacters(),
                       maxParameterLength - defaultParam.count - "&test=123".count)
    }

    // MARK: Completion block

    func test_confirmSave_sends_url_in_completion_block() throws {
        // Given
        var receivedTargetUrl = ""

        let viewModel = BlazeAdDestinationSettingViewModel(
            productURL: sampleProductURL,
            homeURL: sampleHomeURL,
            finalDestinationURL: sampleProductURL,
            analytics: analytics,
            onSave: { targetUrl, _ in
                receivedTargetUrl = targetUrl
            }
        )

        // When
        viewModel.confirmSave()

        // Then
        XCTAssertEqual(receivedTargetUrl, sampleProductURL)
    }

    func test_confirmSave_sends_params_in_completion_block() throws {
        // Given
        var receivedUrlParams = ""

        let viewModel = BlazeAdDestinationSettingViewModel(
            productURL: sampleProductURL,
            homeURL: sampleHomeURL,
            finalDestinationURL: finalDestinationURL,
            analytics: analytics,
            onSave: { _, urlParams in
                receivedUrlParams = urlParams
            }
        )

        // When
        viewModel.confirmSave()

        // Then
        XCTAssertEqual(receivedUrlParams, threeParameters)
    }

    // MARK: Analytics
    func test_confirmSave_tracks_event() throws {
        // Given
        let viewModel = BlazeAdDestinationSettingViewModel(
            productURL: sampleProductURL,
            homeURL: sampleHomeURL,
            finalDestinationURL: finalDestinationURL,
            analytics: analytics,
            onSave: { _, _ in }
        )

        // When
        viewModel.confirmSave()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("blaze_creation_edit_destination_save_tapped"))
    }
}
