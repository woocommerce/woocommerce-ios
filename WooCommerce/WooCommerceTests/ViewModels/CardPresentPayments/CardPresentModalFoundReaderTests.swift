import XCTest
@testable import WooCommerce

final class CardPresentModalFoundReaderTests: XCTestCase {
    private var viewModel: CardPresentModalFoundReader!
    private var closures: Closures!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        closures = Closures()
        viewModel = CardPresentModalFoundReader(name: Expectations.name,
                                                connect: closures.primaryAction(),
                                                continueSearch: closures.secondaryAction(),
                                                cancel: closures.auxiliaryAction())
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
    func test_primary_button_title_is_not_nil() {
        XCTAssertNotNil(viewModel.primaryButtonTitle)
    }

    @MainActor
    func test_secondary_button_title_is_not_nil() {
        XCTAssertNotNil(viewModel.secondaryButtonTitle)
    }

    @MainActor
    func test_auxiliary_button_title_is_not_nil() {
        XCTAssertNotNil(viewModel.auxiliaryButtonTitle)
    }

    @MainActor
    func test_bottom_title_is_nil() {
        XCTAssertNil(viewModel.bottomTitle)
    }

    @MainActor
    func test_bottom_subTitle_is_nil() {
        XCTAssertNil(viewModel.bottomSubtitle)
    }

    @MainActor
    func test_primary_button_action_calls_closure() {
        viewModel.didTapPrimaryButton(in: UIViewController())

        XCTAssertTrue(closures.didTapConnect)
    }

    @MainActor
    func test_secondary_button_action_calls_closure() {
        viewModel.didTapSecondaryButton(in: nil)

        XCTAssertTrue(closures.didTapContinue)
    }

    @MainActor
    func test_auxiliary_button_action_calls_closure() {
        viewModel.didTapAuxiliaryButton(in: nil)

        XCTAssertTrue(closures.didTapCancel)
    }
}


private extension CardPresentModalFoundReaderTests {
    enum Expectations {
        static let name = "name"
        static let amount = "amount"
        static let image = UIImage.cardReaderFound
    }
}


private final class Closures {
    var didTapConnect = false
    var didTapContinue = false
    var didTapCancel = false

    func primaryAction() -> () -> Void {
        return {[weak self] in
            self?.didTapConnect = true
        }
    }

    func secondaryAction() -> () -> Void {
        return {[weak self] in
            self?.didTapContinue = true
        }
    }

    func auxiliaryAction() -> () -> Void {
        return {[weak self] in
            self?.didTapCancel = true
        }
    }
}
