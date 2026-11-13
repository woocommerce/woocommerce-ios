import XCTest
@testable import WooCommerce

final class CardPresentModalBluetoothRequiredTests: XCTestCase {
    private var viewModel: CardPresentModalBluetoothRequired!
    private var closures: Closures!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        closures = Closures()
        viewModel = CardPresentModalBluetoothRequired(error: Expectations.error, primaryAction: closures.primaryAction())
    }

    override func tearDown() {
        viewModel = nil
        closures = nil
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
    func test_primary_button_title_is_not_nil() {
        XCTAssertNotNil(viewModel.primaryButtonTitle)
    }

    @MainActor
    func test_secondary_button_title_is_nil() {
        XCTAssertNotNil(viewModel.secondaryButtonTitle)
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


private extension CardPresentModalBluetoothRequiredTests {
    enum Expectations {
        static let image = UIImage.paymentErrorImage
        static let error = MockError()
    }

    final class MockError: Error {
        var localizedDescription: String {
            "description"
        }
    }
}


private final class Closures {
    var didTapPrimary = false

    func primaryAction() -> () -> Void {
        return {[weak self] in
            self?.didTapPrimary = true
        }
    }
}
