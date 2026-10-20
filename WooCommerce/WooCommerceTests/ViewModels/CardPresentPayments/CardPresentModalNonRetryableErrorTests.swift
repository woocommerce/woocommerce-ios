import XCTest
@testable import WooCommerce

final class CardPresentModalNonRetryableErrorTests: XCTestCase {
    private var viewModel: CardPresentModalNonRetryableError!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        viewModel = CardPresentModalNonRetryableError(amount: Expectations.amount,
                                                      error: Expectations.error,
                                                      onDismiss: {},
                                                      emailReceiptAction: {})
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
    func test_topSubtitle_provides_expected_title() {
        XCTAssertEqual(viewModel.topSubtitle, Expectations.amount)
    }

    @MainActor
    func test_primary_button_title_is_not_nil() {
        XCTAssertNotNil(viewModel.primaryButtonTitle)
    }

    @MainActor
    func test_secondary_button_title_is_nil() {
        XCTAssertNotNil(viewModel.secondaryButtonTitle)
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


private extension CardPresentModalNonRetryableErrorTests {
    enum Expectations {
        static let amount = "amount"
        static let image = UIImage.paymentErrorImage
        static let error = MockError()
    }

    final class MockError: Error {
        var localizedDescription: String {
            "description"
        }
    }
}
