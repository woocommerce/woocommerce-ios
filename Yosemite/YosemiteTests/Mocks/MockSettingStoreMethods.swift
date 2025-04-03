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
        onCompletion(.success(true))
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
}
