import Networking

final class MockSiteSettingsRemote: SiteSettingsRemoteProtocol {
    var setFeatureCalled: Bool = false
    var spySetFeatureSiteID: Int64?
    var spySetFeatureFeature: SiteSettingsFeature?
    var spySetFeatureEnabled: Bool?
    var setFeatureResult: Result<Bool, Error> = .success(true)

    var loadAnalyticsOrderDateTypeResult: Result<SiteSetting, Error> = .success(SiteSetting.fake())
    var spyLoadAnalyticsOrderDateTypeSiteID: Int64?
    var updateAnalyticsOrderDateTypeResult: Result<SiteSetting, Error> = .success(SiteSetting.fake())
    var spyUpdateAnalyticsOrderDateTypeSiteID: Int64?
    var spyUpdateAnalyticsOrderDateTypeValue: String?

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

    func loadAnalyticsOrderDateType(for siteID: Int64) async throws -> SiteSetting {
        spyLoadAnalyticsOrderDateTypeSiteID = siteID
        switch loadAnalyticsOrderDateTypeResult {
        case .success(let setting):
            return setting
        case .failure(let error):
            throw error
        }
    }

    func updateAnalyticsOrderDateType(for siteID: Int64, value: String) async throws -> SiteSetting {
        spyUpdateAnalyticsOrderDateTypeSiteID = siteID
        spyUpdateAnalyticsOrderDateTypeValue = value
        switch updateAnalyticsOrderDateTypeResult {
        case .success(let setting):
            return setting
        case .failure(let error):
            throw error
        }
    }
}
