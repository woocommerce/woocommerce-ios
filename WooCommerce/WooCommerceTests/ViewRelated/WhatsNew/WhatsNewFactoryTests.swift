import XCTest
import WordPressKit
@testable import WooCommerce

final class WhatsNewFactoryTests: XCTestCase {

    func test_create_whats_new_view_controller_has_expected_properties() throws {
        // Arrange
        let announcement = try makeWordPressAnnouncement()

        // Act
        let viewController = WhatsNewFactory.whatsNew(announcement, onDismiss: {}) as? WhatsNewHostingController

        // Assert
        XCTAssertEqual(viewController?.rootView.viewModel.items.count, 1)
        XCTAssertEqual(viewController?.modalPresentationStyle, .formSheet)
    }
}

// MARK: - Mocks
//
private extension WhatsNewFactoryTests {
    func makeWordPressAnnouncement() throws -> WordPressKit.Announcement {
        let jsonData = try JSONSerialization.data(withJSONObject: [
            "appVersionName": "1",
            "minimumAppVersion": "",
            "maximumAppVersion": "",
            "appVersionTargets": [],
            "detailsUrl": "http://wordpress.org",
            "features": [[
                "title": "foo",
                "subtitle": "bar",
                "iconBase64": "",
                "iconUrl": "https://s0.wordpress.com/i/store/mobile/plans-premium.png"
            ]],
            "announcementVersion": "2",
            "isLocalized": true,
            "responseLocale": "en_US"
        ])

        return try JSONDecoder().decode(Announcement.self, from: jsonData)
    }
}
