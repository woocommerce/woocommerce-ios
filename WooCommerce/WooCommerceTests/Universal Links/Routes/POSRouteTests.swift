import XCTest

@testable import WooCommerce

final class POSRouteTests: XCTestCase {

    private var deepLinkNavigator: MockDeepLinkNavigator!
    private var sut: POSRoute!

    override func setUp() {
        deepLinkNavigator = MockDeepLinkNavigator()
        sut = POSRoute(deepLinkNavigator: deepLinkNavigator)
    }

    func test_canHandle_returns_true_for_pos_learn_more_deep_link_path() {
        XCTAssertTrue(sut.canHandle(subPath: "pos/learn-more"))
    }

    func test_canHandle_returns_false_for_pos_root_without_subpath() {
        XCTAssertFalse(sut.canHandle(subPath: "pos"))
    }

    func test_canHandle_returns_false_for_unrelated_path() {
        XCTAssertFalse(sut.canHandle(subPath: "orders"))
    }

    func test_performAction_forwards_pos_learn_more_deep_link() throws {
        // Given
        let path = "pos/learn-more"

        // When
        let reportedHandled = sut.perform(for: path, with: [:])

        // Then
        XCTAssertTrue(reportedHandled)
        let navigatedDestination = try XCTUnwrap(deepLinkNavigator.spyNavigatedDestination as? POSPromotionDestination)
        assertEqual(POSPromotionDestination.learnMore, navigatedDestination)
    }

    func test_performAction_does_not_forward_unrecognised_deep_link() {
        // Given
        let path = "pos/some-future-feature"

        // When
        let reportedHandled = sut.perform(for: path, with: [:])

        // Then
        XCTAssertFalse(reportedHandled)
        XCTAssertFalse(deepLinkNavigator.spyDidNavigate)
    }
}
