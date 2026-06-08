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
    var loadAnalyticsScheduledImportResult: Result<SiteSetting, Error> = .success(SiteSetting.fake())
    var spyLoadAnalyticsScheduledImportSiteID: Int64?
    var updateAnalyticsScheduledImportResult: Result<SiteSetting, Error> = .success(SiteSetting.fake())
    var spyUpdateAnalyticsScheduledImportSiteID: Int64?
    var spyUpdateAnalyticsScheduledImportValue: String?

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

    func loadAnalyticsScheduledImport(for siteID: Int64) async throws -> SiteSetting {
        spyLoadAnalyticsScheduledImportSiteID = siteID
        switch loadAnalyticsScheduledImportResult {
        case .success(let setting):
            return setting
        case .failure(let error):
            throw error
        }
    }

    func updateAnalyticsScheduledImport(for siteID: Int64, value: String) async throws -> SiteSetting {
        spyUpdateAnalyticsScheduledImportSiteID = siteID
        spyUpdateAnalyticsScheduledImportValue = value
        switch updateAnalyticsScheduledImportResult {
        case .success(let setting):
            return setting
        case .failure(let error):
            throw error
        }
    }
}
