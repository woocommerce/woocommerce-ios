import XCTest
@testable import WooCommerce

final class CardPresentModalConnectingToReaderTests: XCTestCase {
    private var viewModel: CardPresentModalConnectingToReader!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        viewModel = CardPresentModalConnectingToReader()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    @MainActor
    func test_viewmodel_provides_expected_image() {
        XCTAssertEqual(viewModel.image, Expectations.image)
    }

    @MainActor
    func test_topTitle_is_not_nil() {
        XCTAssertNotNil(viewModel.topTitle)
    }

    @MainActor
    func test_topSubtitle_is_nil() {
        XCTAssertNil(viewModel.topSubtitle)
    }

    @MainActor
    func test_primary_button_title_is_nil() {
        XCTAssertNil(viewModel.primaryButtonTitle)
    }

    @MainActor
    func test_secondary_button_title_is_nil() {
        XCTAssertNil(viewModel.secondaryButtonTitle)
    }

    @MainActor
    func test_auxiliary_button_title_is_nil() {
        XCTAssertNil(viewModel.auxiliaryButtonTitle)
    }

    @MainActor
    func test_bottom_title_is_not_nil() {
        XCTAssertNotNil(viewModel.bottomTitle)
    }

    @MainActor
    func test_bottom_subTitle_is_nil() {
        XCTAssertNil(viewModel.bottomSubtitle)
    }
}


private extension CardPresentModalConnectingToReaderTests {
    enum Expectations {
        static let image = UIImage.cardReaderConnecting
    }
}
