import XCTest
@testable import WooCommerce

final class CardPresentModalScanningForReaderTests: XCTestCase {
    private var viewModel: CardPresentModalScanningForReader!
    private var closures: Closures!

    override func setUp() {
        super.setUp()
        closures = Closures()
        viewModel = CardPresentModalScanningForReader(cancel: closures.primaryAction())
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func test_viewmodel_provides_expected_image() {
        XCTAssertEqual(viewModel.image, Expectations.image)
    }

    func test_topTitle_is_not_nil() {
        XCTAssertNotNil(viewModel.topTitle)
    }

    func test_topSubtitle_is_nil() {
        XCTAssertNil(viewModel.topSubtitle)
    }

    func test_primary_button_title_is_nil() {
        XCTAssertNil(viewModel.primaryButtonTitle)
    }

    func test_secondary_button_title_is_not_nil() {
        XCTAssertNotNil(viewModel.secondaryButtonTitle)
    }

    func test_auxiliary_button_title_is_nil() {
        XCTAssertNil(viewModel.auxiliaryButtonTitle)
    }

    func test_bottom_title_is_not_nil() {
        XCTAssertNotNil(viewModel.bottomTitle)
    }

    func test_bottom_subTitle_is_nil() {
        XCTAssertNil(viewModel.bottomSubtitle)
    }

    func test_secondary_button_action_calls_closure() {
        viewModel.didTapSecondaryButton(in: nil)

        XCTAssertTrue(closures.didTapCancel)
    }
}


private extension CardPresentModalScanningForReaderTests {
    enum Expectations {
        static var name = "name"
        static var amount = "amount"
        static var image = UIImage.cardReaderScanning
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
