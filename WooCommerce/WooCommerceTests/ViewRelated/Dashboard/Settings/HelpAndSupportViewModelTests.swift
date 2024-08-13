import XCTest
@testable import WooCommerce

class HelpAndSupportViewModelTests: XCTestCase {
    func test_mac_catalyst_environment_shows_only_help_center() {
        let viewModel = HelpAndSupportViewModel(isAuthenticated: true, isZendeskEnabled: true, isMacCatalyst: true)
        let rows = viewModel.getRows()
        XCTAssertEqual(rows, [.helpCenter])
    }

    func test_zendesk_disabled_shows_only_help_center() {
        let viewModel = HelpAndSupportViewModel(isAuthenticated: true, isZendeskEnabled: false, isMacCatalyst: false)
        let rows = viewModel.getRows()
        XCTAssertEqual(rows, [.helpCenter])
    }

    func test_unauthenticated_user_does_not_see_system_status_report() {
        let viewModel = HelpAndSupportViewModel(isAuthenticated: false, isZendeskEnabled: true, isMacCatalyst: false)
        let rows = viewModel.getRows()
        XCTAssertEqual(rows, [.helpCenter, .contactSupport, .contactEmail, .applicationLog])
        XCTAssertFalse(rows.contains(.systemStatusReport))
    }

    func test_authenticated_user_sees_all_options() {
        let viewModel = HelpAndSupportViewModel(isAuthenticated: true, isZendeskEnabled: true, isMacCatalyst: false)
        let rows = viewModel.getRows()
        XCTAssertEqual(rows, [.helpCenter, .contactSupport, .contactEmail, .applicationLog, .systemStatusReport])
    }

    func test_row_order_is_correct() {
        let viewModel = HelpAndSupportViewModel(isAuthenticated: true, isZendeskEnabled: true, isMacCatalyst: false)
        let rows = viewModel.getRows()
        XCTAssertEqual(rows.first, .helpCenter)
        XCTAssertEqual(rows.last, .systemStatusReport)
    }

    func test_help_center_always_present() {
        let viewModels = [
            HelpAndSupportViewModel(isAuthenticated: true, isZendeskEnabled: true, isMacCatalyst: true),
            HelpAndSupportViewModel(isAuthenticated: false, isZendeskEnabled: false, isMacCatalyst: false),
            HelpAndSupportViewModel(isAuthenticated: true, isZendeskEnabled: true, isMacCatalyst: false)
        ]

        for viewModel in viewModels {
            let rows = viewModel.getRows()
            XCTAssertTrue(rows.contains(.helpCenter), "Help Center should always be present")
        }
    }
}
