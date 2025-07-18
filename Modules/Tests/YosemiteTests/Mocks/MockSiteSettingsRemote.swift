import Networking

final class MockSiteSettingsRemote: SiteSettingsRemoteProtocol {
    var setFeatureCalled: Bool = false
    var spySetFeatureSiteID: Int64?
    var spySetFeatureFeature: SiteSettingsFeature?
    var spySetFeatureEnabled: Bool?
    var setFeatureResult: Result<Bool, Error> = .success(true)

    func setFeature(for siteID: Int64, feature: SiteSettingsFeature, enabled: Bool) async throws -> Bool {
        setFeatureCalled = true
        spySetFeatureSiteID = siteID
        spySetFeatureFeature = feature
        spySetFeatureEnabled = enabled

        switch setFeatureResult {
        case .success(let result):
            return result
        case .failure(let error):
            throw error
        }
    }
}
