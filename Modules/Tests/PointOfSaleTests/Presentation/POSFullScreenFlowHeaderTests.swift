import Testing
@testable import PointOfSale

struct POSFullScreenFlowHeaderTests {
    private let closeAction = POSModalFlowAction(handler: .init(), isEnabled: true, accessibilityLabel: "Close", accessibilityIdentifier: nil)
    private let backAction = POSModalFlowAction(handler: .init(), isEnabled: true, accessibilityLabel: "Back", accessibilityIdentifier: nil)

    @Test func test_fullScreen_when_created_with_title_only_then_has_no_steps() {
        // Given
        let style = POSModalCompactStyle.fullScreen(title: "Card reader")

        // Then
        #expect(style == .fullScreen(title: "Card reader", hasSteps: false))
        #expect(style.fullScreenTitle == "Card reader")
        #expect(style.hasSteps == false)
    }

    @Test func test_hasSteps_when_style_is_not_fullScreen_then_is_false_and_has_no_title() {
        // Then
        #expect(POSModalCompactStyle.dialog.hasSteps == false)
        #expect(POSModalCompactStyle.bottomSheet.hasSteps == false)
        #expect(POSModalCompactStyle.dialog.fullScreenTitle == nil)
    }

    @Test func test_buttons_when_flow_has_no_steps_then_close_is_leading() {
        // When
        let buttons = POSFullScreenFlowHeaderButtons(hasSteps: false, backAction: nil, closeAction: closeAction)

        // Then
        #expect(buttons.leading == .close(closeAction))
        #expect(buttons.trailingClose == nil)
    }

    @Test func test_buttons_when_flow_has_no_steps_and_no_close_then_header_has_title_only() {
        // When
        let buttons = POSFullScreenFlowHeaderButtons(hasSteps: false, backAction: nil, closeAction: nil)

        // Then
        #expect(buttons.leading == nil)
        #expect(buttons.trailingClose == nil)
    }

    @Test func test_buttons_when_flow_has_steps_then_back_is_leading_and_close_is_trailing() {
        // When
        let buttons = POSFullScreenFlowHeaderButtons(hasSteps: true, backAction: backAction, closeAction: closeAction)

        // Then
        #expect(buttons.leading == .back(backAction))
        #expect(buttons.trailingClose == closeAction)
    }

    @Test func test_buttons_when_step_has_no_back_action_then_back_arrow_closes_the_flow() {
        // When
        let buttons = POSFullScreenFlowHeaderButtons(hasSteps: true, backAction: nil, closeAction: closeAction)

        // Then
        #expect(buttons.leading == .back(closeAction))
        #expect(buttons.trailingClose == closeAction)
    }
}
