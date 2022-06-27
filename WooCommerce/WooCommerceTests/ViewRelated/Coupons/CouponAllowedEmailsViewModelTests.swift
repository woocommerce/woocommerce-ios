import XCTest
@testable import WooCommerce

final class CouponAllowedEmailsViewModelTests: XCTestCase {

    func test_completion_block_is_triggered_when_address_validation_succeeds() {
        // Given
        var savedAddresses: String?
        let completionBlock: (String) -> Void = { email in
            savedAddresses = email
        }
        let viewModel = CouponAllowedEmailsViewModel(allowedEmails: "", onCompletion: completionBlock)

        // When
        viewModel.emailPatterns = "*@mail.com"
        viewModel.validateEmails {}

        // Then
        XCTAssertEqual(savedAddresses, "*@mail.com")
        XCTAssertNil(viewModel.notice)
    }

    func test_completion_block_is_triggered_when_allowed_email_list_is_empty() {
        // Given
        var savedAddresses: String?
        let completionBlock: (String) -> Void = { email in
            savedAddresses = email
        }
        let viewModel = CouponAllowedEmailsViewModel(allowedEmails: "test@mail.com", onCompletion: completionBlock)

        // When
        viewModel.emailPatterns = ""
        viewModel.validateEmails {}

        // Then
        XCTAssertEqual(savedAddresses, "")
        XCTAssertNil(viewModel.notice)
    }

    func test_completion_block_is_not_triggered_and_notice_is_not_nil_when_address_validation_fails() {
        var savedAddresses: String?
        let completionBlock: (String) -> Void = { email in
            savedAddresses = email
        }
        let viewModel = CouponAllowedEmailsViewModel(allowedEmails: "", onCompletion: completionBlock)

        // When
        viewModel.emailPatterns = "*@mail"
        viewModel.validateEmails {}

        // Then
        XCTAssertNil(savedAddresses)
        XCTAssertNotNil(viewModel.notice)
    }
}
