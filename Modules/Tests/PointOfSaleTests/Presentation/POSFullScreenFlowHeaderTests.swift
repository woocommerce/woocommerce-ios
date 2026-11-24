import Testing
@testable import PointOfSale

struct POSFullScreenFlowHeaderTests {
    private let closeAction = POSModalFlowAction(handler: .init(), isEnabled: true, accessibilityLabel: "Close", accessibilityIdentifier: nil)
    private let backAction = POSModalFlowAction(handler: .init(), isEnabled: true, accessibilityLabel: "Back", accessibilityIdentifier: nil)

    @Test func test_fullScreenTitle_when_style_is_fullScreen_then_returns_title() {
        // Given
        let style = POSModalCompactStyle.fullScreen(title: "Card reader")

        // Then
        #expect(style.fullScreenTitle == "Card reader")
    }

    @Test func test_fullScreenTitle_when_style_is_not_fullScreen_then_is_nil() {
        // Then
        #expect(POSModalCompactStyle.dialog.fullScreenTitle == nil)
        #expect(POSModalCompactStyle.bottomSheet.fullScreenTitle == nil)
    }

    @Test func test_buttons_when_only_close_is_offered_then_close_is_leading() {
        // When
        let buttons = POSFullScreenFlowHeaderButtons(title: "Card reader", backAction: nil, closeAction: closeAction)

        // Then
        #expect(buttons.leading == .close(closeAction))
        #expect(buttons.trailingClose == nil)
    }

    @Test(arguments: ["Card reader", ""])
    func test_buttons_when_nothing_is_offered_then_header_has_no_buttons(title: String) {
        // When
        let buttons = POSFullScreenFlowHeaderButtons(title: title, backAction: nil, closeAction: nil)

        // Then
        #expect(buttons.leading == nil)
        #expect(buttons.trailingClose == nil)
    }

    @Test func test_buttons_when_title_is_in_content_and_only_close_is_offered_then_close_stays_trailing() {
        // When
        let buttons = POSFullScreenFlowHeaderButtons(title: "", backAction: nil, closeAction: closeAction)

        // Then
        #expect(buttons.leading == nil)
        #expect(buttons.trailingClose == closeAction)
    }

    @Test(arguments: ["Card reader", ""])
    func test_buttons_when_back_and_close_are_offered_then_back_is_leading_and_close_is_trailing(title: String) {
        // When
        let buttons = POSFullScreenFlowHeaderButtons(title: title, backAction: backAction, closeAction: closeAction)

        // Then
        #expect(buttons.leading == .back(backAction))
        #expect(buttons.trailingClose == closeAction)
    }

    @Test(arguments: ["Card reader", ""])
    func test_buttons_when_only_back_is_offered_then_back_is_leading_without_close(title: String) {
        // When
        let buttons = POSFullScreenFlowHeaderButtons(title: title, backAction: backAction, closeAction: nil)

        // Then
        #expect(buttons.leading == .back(backAction))
        #expect(buttons.trailingClose == nil)
    }
}
