import XCTest
@testable import WooCommerce

class ErrorTopBannerFactoryTests: XCTestCase {

    func test_top_banner_has_two_actions() throws {
        // Given
        let topBannerView = ErrorTopBannerFactory.createTopBanner(isExpanded: false,
                                    expandedStateChangeHandler: {},
                                    onTroubleshootButtonPressed: {},
                                    onContactSupportButtonPressed: {})

        // Then
        XCTAssertNotNil(topBannerView)
        let view = try XCTUnwrap(topBannerView)
        let mirrorView = try TopBannerViewMirror(from: view)
        XCTAssertEqual(mirrorView.actionButtons.count, 2)
    }

    func test_tapping_top_banner_troubleshoot_button_triggers_callback() throws {
        // Given
        var isTroubleshootButtonPressed = false
        let topBannerView = ErrorTopBannerFactory.createTopBanner(isExpanded: false,
                                                                  expandedStateChangeHandler: {},
                                                                  onTroubleshootButtonPressed: {
                                                                    isTroubleshootButtonPressed = true
                                                                  },
                                                                  onContactSupportButtonPressed: {})

        // Then
        let view = try XCTUnwrap(topBannerView)
        let mirrorView = try TopBannerViewMirror(from: view)
        mirrorView.actionButtons.first?.sendActions(for: .touchUpInside)
        XCTAssertTrue(isTroubleshootButtonPressed)
    }

    func test_tapping_top_banner_contact_support_button_triggers_callback() throws {
        // Given
        var isContactSupportButtonPressed = false
        let topBannerView = ErrorTopBannerFactory.createTopBanner(isExpanded: false,
                                                                  expandedStateChangeHandler: {},
                                                                  onTroubleshootButtonPressed: {},
                                                                  onContactSupportButtonPressed: {
                                                                    isContactSupportButtonPressed = true
                                                                  })

        // Then
        let view = try XCTUnwrap(topBannerView)
        let mirrorView = try TopBannerViewMirror(from: view)
        mirrorView.actionButtons[1].sendActions(for: .touchUpInside)
        XCTAssertTrue(isContactSupportButtonPressed)
    }
}
