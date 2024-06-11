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
