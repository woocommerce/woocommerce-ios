@testable import Yosemite

final class MockSettingStoreMethods: SettingStoreMethodsProtocol {
    var generalSiteSettingsSyncCalled = false
    var productSiteSettingsSyncCalled = false
    var retrieveSiteAPICalled = false
    var retrieveCouponSettingCalled = false
    var enableCouponSettingCalled = false
    var retrieveAnalyticsSettingCalled = false
    var enableAnalyticsSettingCalled = false
    var retrieveTaxBasedOnSettingCalled = false
    var retrievePointOfSaleSettingsCalled = false

    var couponsEnabled: Bool = true
    var featureEnabled: Result<Bool, Error> = .success(true)
    var retrievePointOfSaleSettingsResult: Result<[SiteSetting], Error> = .success([])
    var retrievePointOfSaleSettingsSiteID: Int64?

    func synchronizeGeneralSiteSettings(siteID: Int64,
                                      onCompletion: @escaping (Error?) -> Void) {
        generalSiteSettingsSyncCalled = true
        onCompletion(nil)
    }

    func synchronizeProductSiteSettings(siteID: Int64,
                                      onCompletion: @escaping (Error?) -> Void) {
        productSiteSettingsSyncCalled = true
        onCompletion(nil)
    }

    func retrieveSiteAPI(siteID: Int64,
                        onCompletion: @escaping (Result<Yosemite.SiteAPI, Error>) -> Void) {
        retrieveSiteAPICalled = true
    }

    func retrieveCouponSetting(siteID: Int64,
                             onCompletion: @escaping (Result<Bool, Error>) -> Void) {

        retrieveCouponSettingCalled = true
        if couponsEnabled {
            onCompletion(.success(true))
        } else {
            onCompletion(.success(false))
        }
    }

    func enableCouponSetting(siteID: Int64,
                           onCompletion: @escaping (Result<Void, Error>) -> Void) {
        enableCouponSettingCalled = true
        onCompletion(.success(()))
    }

    func retrieveAnalyticsSetting(siteID: Int64,
                                onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        retrieveAnalyticsSettingCalled = true
        onCompletion(.success(true))
    }

    func enableAnalyticsSetting(siteID: Int64,
                              onCompletion: @escaping (Result<Void, Error>) -> Void) {
        enableAnalyticsSettingCalled = true
        onCompletion(.success(()))
    }

    func retrieveTaxBasedOnSetting(siteID: Int64,
                                 onCompletion: @escaping (Result<Yosemite.TaxBasedOnSetting, Error>) -> Void) {
        retrieveTaxBasedOnSettingCalled = true
    }

    func isFeatureEnabled(siteID: Int64, feature: SiteSettingsFeature) async throws -> Bool {
        switch featureEnabled {
        case .success(let isEnabled):
            return isEnabled
        case .failure(let error):
            throw error
        }
    }

    func retrievePointOfSaleSettings(siteID: Int64) async throws -> [SiteSetting] {
        retrievePointOfSaleSettingsCalled = true
        retrievePointOfSaleSettingsSiteID = siteID
        switch retrievePointOfSaleSettingsResult {
        case .success(let settings):
            return settings
        case .failure(let error):
            throw error
        }
    }
}
