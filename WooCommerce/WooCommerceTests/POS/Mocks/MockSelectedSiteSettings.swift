@testable import WooCommerce
@testable import Yosemite
import Combine

final class MockSelectedSiteSettings: SelectedSiteSettingsProtocol {
    typealias SettingsUpdate = (siteID: Int64, settings: [SiteSetting], source: SettingsUpdateSource)

    var mockSettingsStream: AnyPublisher<SettingsUpdate, Never>?
    var siteSettings: [SiteSetting] = []
    var isUsingFallbackCurrency: Bool = false
    private(set) var refreshCallCount = 0

    /// Used when `mockSettingsStream` isn't provided; `refresh()` re-emits on it, mirroring the real object.
    private let refreshSubject = PassthroughSubject<SettingsUpdate, Never>()

    var settingsStream: AnyPublisher<SettingsUpdate, Never> {
        return mockSettingsStream ?? refreshSubject.eraseToAnyPublisher()
    }

    func refresh() {
        refreshCallCount += 1
        refreshSubject.send((siteID: 0, settings: siteSettings, source: .refresh))
    }
}
