import XCTest
import Hardware
import TestKit
@testable import WooCommerce

final class CardPresentModalConnectingFailedTests: XCTestCase {
    private var viewModel: CardPresentModalConnectingFailed!
    private var closures: Closures!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        closures = Closures()
        viewModel = CardPresentModalConnectingFailed(
            error: CardReaderServiceError.connection(underlyingError: .alreadyConnectedToReader),
            retrySearch: closures.continueSearch(),
            cancelSearch: closures.cancelSearch()
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
    func test_bottom_title_is_error_description() {
        assertEqual(UnderlyingError.alreadyConnectedToReader.localizedDescription, viewModel.bottomTitle)
    }

    @MainActor
    func test_bottom_subTitle_is_nil() {
        XCTAssertNil(viewModel.bottomSubtitle)
    }
}

private extension CardPresentModalConnectingFailedTests {
    enum Expectations {
        static let image = UIImage.paymentErrorImage
    }
}

private final class Closures {
    var didTapContinueSearch = false
    var didTapCancelSearch = false

    func continueSearch() -> () -> Void {
        return {[weak self] in
            self?.didTapContinueSearch = true
        }
    }

    func cancelSearch() -> () -> Void {
        return {[weak self] in
            self?.didTapCancelSearch = true
        }
    }
}
