import XCTest
@testable import WooCommerce
import TestKit

final class FirstProductCreatedViewModelTests: XCTestCase {
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

    func test_it_provides_expected_productURL() throws {
        // Given
        let productURL = try XCTUnwrap(Expectations.productURL)
        let productName = Expectations.productName
        let showShareProductButton = Expectations.showShareProductButton

        // When
        let viewModel = FirstProductCreatedViewModel(productURL: productURL,
                                                     productName: productName,
                                                     showShareProductButton: showShareProductButton)
        // Then
        XCTAssertEqual(viewModel.productURL, productURL)
    }

    func test_it_provides_expected_productName() throws {
        // Given
        let productURL = try XCTUnwrap(Expectations.productURL)
        let productName = Expectations.productName
        let showShareProductButton = Expectations.showShareProductButton

        // When
        let viewModel = FirstProductCreatedViewModel(productURL: productURL,
                                                     productName: productName,
                                                     showShareProductButton: showShareProductButton)
        // Then
        XCTAssertEqual(viewModel.productName, productName)
    }

    func test_it_provides_expected_showShareProductButton() throws {
        // Given
        let productURL = try XCTUnwrap(Expectations.productURL)
        let productName = Expectations.productName
        let showShareProductButton = Expectations.showShareProductButton

        // When
        let viewModel = FirstProductCreatedViewModel(productURL: productURL,
                                                     productName: productName,
                                                     showShareProductButton: showShareProductButton)
        // Then
        XCTAssertEqual(viewModel.showShareProductButton, showShareProductButton)
    }

    // MARK: `didTapShareProduct`

    func test_it_logs_an_event_when_share_product_button_is_tapped() throws {
        // Given
        let productURL = try XCTUnwrap(Expectations.productURL)
        let productName = Expectations.productName
        let showShareProductButton = Expectations.showShareProductButton
        let viewModel = FirstProductCreatedViewModel(productURL: productURL,
                                                     productName: productName,
                                                     showShareProductButton: showShareProductButton,
                                                     analytics: analytics)
        assertEmpty(analyticsProvider.receivedEvents)

        // When
        viewModel.didTapShareProduct()

        // Then
        let firstEvent = try XCTUnwrap(analyticsProvider.receivedEvents.first)
        XCTAssertEqual(firstEvent, "first_created_product_share_tapped")
    }

    // MARK: `isSharePopoverPresented`

    func test_popover_is_presented_when_on_ipad_and_AI_not_eligible() throws {
        // Given
        let productURL = try XCTUnwrap(Expectations.productURL)
        let productName = Expectations.productName
        let showShareProductButton = Expectations.showShareProductButton
        let viewModel = FirstProductCreatedViewModel(productURL: productURL,
                                                     productName: productName,
                                                     showShareProductButton: showShareProductButton,
                                                     isPad: true,
                                                     eligibilityChecker: MockShareProductAIEligibilityChecker(canGenerateShareProductMessageUsingAI: false))

        XCTAssertFalse(viewModel.isSharePopoverPresented)

        // When
        viewModel.didTapShareProduct()

        // Then
        XCTAssertTrue(viewModel.isSharePopoverPresented)
    }

    func test_popover_is_not_presented_when_on_ipad_and_AI_eligible() throws {
        // Given
        let productURL = try XCTUnwrap(Expectations.productURL)
        let productName = Expectations.productName
        let showShareProductButton = Expectations.showShareProductButton
        let viewModel = FirstProductCreatedViewModel(productURL: productURL,
                                                     productName: productName,
                                                     showShareProductButton: showShareProductButton,
                                                     isPad: true,
                                                     eligibilityChecker: MockShareProductAIEligibilityChecker(canGenerateShareProductMessageUsingAI: true))

        XCTAssertFalse(viewModel.isSharePopoverPresented)

        // When
        viewModel.didTapShareProduct()

        // Then
        XCTAssertFalse(viewModel.isSharePopoverPresented)
    }

    // MARK: `isShareSheetPresented`

    func test_sheet_is_presented_when_not_on_ipad_and_AI_not_eligible() throws {
        // Given
        let productURL = try XCTUnwrap(Expectations.productURL)
        let productName = Expectations.productName
        let showShareProductButton = Expectations.showShareProductButton
        let viewModel = FirstProductCreatedViewModel(productURL: productURL,
                                                     productName: productName,
                                                     showShareProductButton: showShareProductButton,
                                                     isPad: false,
                                                     eligibilityChecker: MockShareProductAIEligibilityChecker(canGenerateShareProductMessageUsingAI: false))

        XCTAssertFalse(viewModel.isShareSheetPresented)

        // When
        viewModel.didTapShareProduct()

        // Then
        XCTAssertTrue(viewModel.isShareSheetPresented)
    }

    func test_sheet_is_not_presented_when_not_on_ipad_and_AI_eligible() throws {
        // Given
        let productURL = try XCTUnwrap(Expectations.productURL)
        let productName = Expectations.productName
        let showShareProductButton = Expectations.showShareProductButton
        let viewModel = FirstProductCreatedViewModel(productURL: productURL,
                                                     productName: productName,
                                                     showShareProductButton: showShareProductButton,
                                                     isPad: false,
                                                     eligibilityChecker: MockShareProductAIEligibilityChecker(canGenerateShareProductMessageUsingAI: true))

        XCTAssertFalse(viewModel.isShareSheetPresented)

        // When
        viewModel.didTapShareProduct()

        // Then
        XCTAssertFalse(viewModel.isShareSheetPresented)
    }

    // MARK: `launchAISharingFlow`

    func test_it_does_not_fire_launchAISharingFlow_AI_not_eligible() throws {
        // Given
        let productURL = try XCTUnwrap(Expectations.productURL)
        let productName = Expectations.productName
        let showShareProductButton = Expectations.showShareProductButton
        let viewModel = FirstProductCreatedViewModel(productURL: productURL,
                                                     productName: productName,
                                                     showShareProductButton: showShareProductButton,
                                                     eligibilityChecker: MockShareProductAIEligibilityChecker(canGenerateShareProductMessageUsingAI: false))

        // When
        waitForExpectation { exp in
            exp.isInverted = true
            viewModel.launchAISharingFlow = {
                exp.fulfill()
            }

            viewModel.didTapShareProduct()
        }
    }

    func test_it_fires_launchAISharingFlow_when_AI_eligible() throws {
        // Given
        let productURL = try XCTUnwrap(Expectations.productURL)
        let productName = Expectations.productName
        let showShareProductButton = Expectations.showShareProductButton
        let viewModel = FirstProductCreatedViewModel(productURL: productURL,
                                                     productName: productName,
                                                     showShareProductButton: showShareProductButton,
                                                     isPad: true,
                                                     eligibilityChecker: MockShareProductAIEligibilityChecker(canGenerateShareProductMessageUsingAI: true))


        // When
        waitForExpectation { exp in
            viewModel.launchAISharingFlow = {
                exp.fulfill()
            }

            viewModel.didTapShareProduct()
        }
    }
}

private extension FirstProductCreatedViewModelTests {
    private enum Expectations {
        static let productURL = URL(string: "https://example.com/product")
        static let productName = "Sample product"
        static let showShareProductButton = true
    }
}

struct MockShareProductAIEligibilityChecker: ShareProductAIEligibilityChecker {
    var canGenerateShareProductMessageUsingAI: Bool
}
