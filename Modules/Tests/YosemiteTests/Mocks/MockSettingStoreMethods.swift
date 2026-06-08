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

    var retrieveAnalyticsOrderDateTypeResult: Result<AnalyticsOrderDateType, Error> = .success(.paid)
    var retrieveAnalyticsOrderDateTypeReceivedSiteID: Int64?
    var updateAnalyticsOrderDateTypeResult: Result<Void, Error> = .success(())
    var updateAnalyticsOrderDateTypeReceivedSiteID: Int64?
    var updateAnalyticsOrderDateTypeReceivedValue: AnalyticsOrderDateType?
    var retrieveAnalyticsImportUpdateModeResult: Result<AnalyticsImportUpdateMode, Error> = .success(.immediate)
    var retrieveAnalyticsImportUpdateModeReceivedSiteID: Int64?
    var updateAnalyticsImportUpdateModeResult: Result<Void, Error> = .success(())
    var updateAnalyticsImportUpdateModeReceivedSiteID: Int64?
    var updateAnalyticsImportUpdateModeReceivedValue: AnalyticsImportUpdateMode?

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

    func retrieveAnalyticsOrderDateType(siteID: Int64) async throws -> AnalyticsOrderDateType {
        retrieveAnalyticsOrderDateTypeReceivedSiteID = siteID
        switch retrieveAnalyticsOrderDateTypeResult {
        case .success(let dateType):
            return dateType
        case .failure(let error):
            throw error
        }
    }

    func updateAnalyticsOrderDateType(siteID: Int64, value: AnalyticsOrderDateType) async throws {
        updateAnalyticsOrderDateTypeReceivedSiteID = siteID
        updateAnalyticsOrderDateTypeReceivedValue = value
        switch updateAnalyticsOrderDateTypeResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    func retrieveAnalyticsImportUpdateMode(siteID: Int64) async throws -> AnalyticsImportUpdateMode {
        retrieveAnalyticsImportUpdateModeReceivedSiteID = siteID
        switch retrieveAnalyticsImportUpdateModeResult {
        case .success(let mode):
            return mode
        case .failure(let error):
            throw error
        }
    }

    func updateAnalyticsImportUpdateMode(siteID: Int64, value: AnalyticsImportUpdateMode) async throws {
        updateAnalyticsImportUpdateModeReceivedSiteID = siteID
        updateAnalyticsImportUpdateModeReceivedValue = value
        switch updateAnalyticsImportUpdateModeResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
}
