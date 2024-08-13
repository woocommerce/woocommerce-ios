import XCTest
@testable import WooCommerce

final class HelpAndSupportViewModelTests: XCTestCase {
    func test_given_mac_catalyst_environment_when_getting_rows_then_only_help_center_is_shown() {
        // Given
        let viewModel = HelpAndSupportViewModel(isAuthenticated: true, isZendeskEnabled: true, isMacCatalyst: true)

        // When
        let rows = viewModel.getRows()

        // Then
        XCTAssertEqual(rows, [.helpCenter])
    }

    func test_given_zendesk_disabled_when_getting_rows_then_only_help_center_is_shown() {
        // Given
        let viewModel = HelpAndSupportViewModel(isAuthenticated: true, isZendeskEnabled: false, isMacCatalyst: false)

        // When
        let rows = viewModel.getRows()

        // Then
        XCTAssertEqual(rows, [.helpCenter])
    }

    func test_given_unauthenticated_user_when_getting_rows_then_system_status_report_is_not_shown() {
        // Given
        let viewModel = HelpAndSupportViewModel(isAuthenticated: false, isZendeskEnabled: true, isMacCatalyst: false)

        // When
        let rows = viewModel.getRows()

        // Then, .systemStatusReport should not be included.
        XCTAssertEqual(rows, [.helpCenter, .contactSupport, .contactEmail, .applicationLog])
    }

    func test_given_authenticated_user_when_getting_rows_then_all_options_are_shown() {
        // Given
        let viewModel = HelpAndSupportViewModel(isAuthenticated: true, isZendeskEnabled: true, isMacCatalyst: false)

        // When
        let rows = viewModel.getRows()

        // Then
        XCTAssertEqual(rows, [.helpCenter, .contactSupport, .contactEmail, .applicationLog, .systemStatusReport])
    }

    func test_given_all_options_when_getting_rows_then_order_is_correct() {
        // Given
        let viewModel = HelpAndSupportViewModel(isAuthenticated: true, isZendeskEnabled: true, isMacCatalyst: false)

        // When
        let rows = viewModel.getRows()

        // Then
        XCTAssertEqual(rows.first, .helpCenter)
        XCTAssertEqual(rows.last, .systemStatusReport)
    }
}
