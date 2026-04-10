@testable import WooCommerce
@testable import Yosemite
import Combine

final class MockSelectedSiteSettings: SelectedSiteSettingsProtocol {
    var mockSettingsStream: AnyPublisher<(siteID: Int64, settings: [SiteSetting], source: SettingsUpdateSource), Never>?
    var siteSettings: [SiteSetting] = []

    var settingsStream: AnyPublisher<(siteID: Int64, settings: [SiteSetting], source: SettingsUpdateSource), Never> {
        return mockSettingsStream ?? Empty().eraseToAnyPublisher()
    }

    func refresh() {
        // Mock implementation - no action needed.
    }
}
