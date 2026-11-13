import XCTest
@testable import WooCommerce

final class CardPresentModalSuccessTests: XCTestCase {
    private var viewModel: CardPresentModalSuccess!
    private var closures: Closures!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        closures = Closures()
        viewModel = CardPresentModalSuccess(printReceipt: closures.printReceipt(),
                                            emailReceipt: closures.emailReceipt(),
                                            noReceiptAction: closures.noReceiptAction())
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

        XCTAssertTrue(closures.didTapPrint)
    }

    @MainActor
    func test_secondary_button_action_calls_closure() {
        viewModel.didTapSecondaryButton(in: UIViewController())

        XCTAssertTrue(closures.didTapEmail)
    }

    @MainActor
    func test_auxiliary_button_action_calls_closure() {
        viewModel.didTapAuxiliaryButton(in: UIViewController())

        XCTAssertTrue(closures.didTapNoReceipt)
    }
}


private extension CardPresentModalSuccessTests {
    enum Expectations {
        static let image = UIImage.celebrationImage
    }
}


private final class Closures {
    var didTapPrint = false
    var didTapEmail = false
    var didTapNoReceipt = false

    func printReceipt() -> () -> Void {
        return { [weak self] in
            self?.didTapPrint = true
        }
    }

    func emailReceipt() -> () -> Void {
        return { [weak self] in
            self?.didTapEmail = true
        }
    }

    func noReceiptAction() -> () -> Void {
        return { [weak self] in
            self?.didTapNoReceipt = true
        }
    }
}
