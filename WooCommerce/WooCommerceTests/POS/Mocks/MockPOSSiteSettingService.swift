@testable import Yosemite

final class MockPOSSiteSettingService: POSSiteSettingServiceProtocol {
    var setFeatureResult: Result<Bool, Error> = .success(true)

    func setFeature(siteID: Int64, feature: SiteSettingsFeature, enabled: Bool) async throws -> Bool {
        switch setFeatureResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        }
    }
}
