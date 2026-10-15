import XCTest
@testable import WooCommerce

final class CardPresentModalScanningForReaderTests: XCTestCase {
    private var viewModel: CardPresentModalScanningForReader!
    private var closures: Closures!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        closures = Closures()
        viewModel = CardPresentModalScanningForReader(cancel: closures.primaryAction())
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
    func test_secondary_button_title_is_not_nil() {
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

    @MainActor
    func test_secondary_button_action_calls_closure() {
        viewModel.didTapSecondaryButton(in: nil)

        XCTAssertTrue(closures.didTapCancel)
    }
}


private extension CardPresentModalScanningForReaderTests {
    enum Expectations {
        static let name = "name"
        static let amount = "amount"
        static let image = UIImage.cardReaderScanning
    }
}


private final class Closures {
    var didTapCancel = false

    func primaryAction() -> () -> Void {
        return {[weak self] in
            self?.didTapCancel = true
        }
    }
}
