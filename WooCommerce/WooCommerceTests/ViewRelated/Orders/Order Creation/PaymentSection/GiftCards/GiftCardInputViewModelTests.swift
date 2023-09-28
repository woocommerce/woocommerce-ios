import XCTest
@testable import WooCommerce

final class GiftCardInputViewModelTests: XCTestCase {

    // MARK: - `isValid`

    func test_isValid_is_false_when_initial_code_is_empty() throws {
        // Given
        let viewModel = GiftCardInputViewModel(code: "", setGiftCard: { _ in }, dismiss: {})

        // Then
        XCTAssertFalse(viewModel.isValid)
    }

    func test_isValid_is_true_when_initial_code_is_valid() throws {
        // Given
        let viewModel = GiftCardInputViewModel(code: "a7WP-MYVG-KNDC-Z5F6", setGiftCard: { _ in }, dismiss: {})

        // Then
        XCTAssertTrue(viewModel.isValid)
    }

    func test_isValid_is_false_when_initial_code_is_invalid() throws {
        // Given
        let viewModel = GiftCardInputViewModel(code: "a7WP-MYVG-KNDC", setGiftCard: { _ in }, dismiss: {})

        // Then
        XCTAssertFalse(viewModel.isValid)
    }

    func test_isValid_becomes_true_when_code_is_valid() throws {
        // Given
        let viewModel = GiftCardInputViewModel(code: "", setGiftCard: { _ in }, dismiss: {})

        // When
        viewModel.code = "a7WP-MYVG-KNDC-Z5F6"

        // Then
        XCTAssertTrue(viewModel.isValid)
    }

    // MARK: - `errorMessage`

    func test_errorMessage_is_nil_when_initial_code_is_empty() throws {
        // Given
        let viewModel = GiftCardInputViewModel(code: "", setGiftCard: { _ in }, dismiss: {})

        // Then
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_errorMessage_is_nil_when_initial_code_is_valid() throws {
        // Given
        let viewModel = GiftCardInputViewModel(code: "a7WP-MYVG-KNDC-Z5F6", setGiftCard: { _ in }, dismiss: {})

        // Then
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_errorMessage_is_not_nil_when_initial_code_is_invalid() throws {
        // Given
        let viewModel = GiftCardInputViewModel(code: "a7WP-MYVG-KNDC", setGiftCard: { _ in }, dismiss: {})

        // Then
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func test_errorMessage_becomes_nil_when_code_is_valid() throws {
        // Given
        let viewModel = GiftCardInputViewModel(code: "a7WP-MYVG-KNDC", setGiftCard: { _ in }, dismiss: {})

        // When
        viewModel.code = "a7WP-MYVG-KNDC-Z5F6"

        // Then
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - `apply`

    func test_apply_invokes_setGiftCard_with_code() throws {
        let code = waitFor { promise in
            // Given
            let viewModel = GiftCardInputViewModel(code: "", setGiftCard: { code in
                promise(code)
            }, dismiss: {})

            // When
            viewModel.code = "a7WP"
            viewModel.apply()
        }

        // Then
        XCTAssertEqual(code, "a7WP")
    }

    // MARK: - `remove`

    func test_remove_invokes_setGiftCard_with_nil_value() throws {
        let code = waitFor { promise in
            // Given
            let viewModel = GiftCardInputViewModel(code: "AADI", setGiftCard: { code in
                promise(code)
            }, dismiss: {})

            // When
            viewModel.code = "a7WP"
            viewModel.remove()
        }

        // Then
        XCTAssertNil(code)
    }

    // MARK: - `cancel`

    func test_cancel_invokes_dismiss() throws {
        waitFor { promise in
            // Given
            let viewModel = GiftCardInputViewModel(code: "", setGiftCard: { _ in }, dismiss: {
                // Then
                promise(())
            })

            // When
            viewModel.code = "a7WP"
            viewModel.cancel()
        }
    }
}
