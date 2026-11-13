import XCTest
import TestKit
@testable import WooCommerce
@testable import Yosemite

final class CardPresentModalTapCardTests: XCTestCase {
    private var viewModel: CardPresentModalTapCard!
    private var closures: Closures!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        closures = Closures()
        viewModel = CardPresentModalTapCard(
            name: Expectations.name,
            amount: Expectations.amount,
            transactionType: .collectPayment,
            inputMethods: [.tap, .swipe, .insert],
            onCancel: closures.onCancel()
        )
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
    func test_topTitle_provides_expected_title() {
        XCTAssertEqual(viewModel.topTitle, Expectations.name)
    }

    @MainActor
    func test_topSubtitle_provides_expected_title() {
        XCTAssertEqual(viewModel.topSubtitle, Expectations.amount)
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
    func test_bottom_subTitle_is_not_nil() {
        XCTAssertNotNil(viewModel.bottomSubtitle)
    }

    @MainActor
    func test_secondary_button_calls_closure() throws {
        viewModel.didTapSecondaryButton(in: UIViewController())
        XCTAssertTrue(closures.didTapCancel)
    }
}

private extension CardPresentModalTapCardTests {
    enum Expectations {
        static let name = "name"
        static let amount = "amount"
        static let image = UIImage.cardPresentImage
    }
}

private final class Closures {
    var didTapCancel = false

    func onCancel() -> () -> Void {
        return { [weak self] in
            self?.didTapCancel = true
        }
    }
}
