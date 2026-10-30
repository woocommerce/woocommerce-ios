import Synchronization
@testable import Yosemite

@dynamicMemberLookup
final class MockSettingStoreMethods: SettingStoreMethodsProtocol {
    struct State {
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
    }

    private let state = Mutex(State())

    subscript<T: Sendable>(dynamicMember keyPath: WritableKeyPath<State, T>) -> T {
        get { state.withLock { $0[keyPath: keyPath] } }
        set { state.withLock { $0[keyPath: keyPath] = newValue } }
    }

    func synchronizeGeneralSiteSettings(siteID: Int64,
                                      onCompletion: @escaping @Sendable (Error?) -> Void) {
        state.withLock { $0.generalSiteSettingsSyncCalled = true }
        onCompletion(nil)
    }

    func synchronizeProductSiteSettings(siteID: Int64,
                                      onCompletion: @escaping @Sendable (Error?) -> Void) {
        state.withLock { $0.productSiteSettingsSyncCalled = true }
        onCompletion(nil)
    }

    func retrieveSiteAPI(siteID: Int64,
                        detectUnexpectedResponses: Bool,
                        onCompletion: @escaping @Sendable (Result<Yosemite.SiteAPI, Error>) -> Void) {
        state.withLock { $0.retrieveSiteAPICalled = true }
    }

    func retrieveCouponSetting(siteID: Int64,
                             onCompletion: @escaping @Sendable (Result<Bool, Error>) -> Void) {
        let couponsEnabled = state.withLock {
            $0.retrieveCouponSettingCalled = true
            return $0.couponsEnabled
        }
        onCompletion(.success(couponsEnabled))
    }

    func enableCouponSetting(siteID: Int64,
                           onCompletion: @escaping @Sendable (Result<Void, Error>) -> Void) {
        state.withLock { $0.enableCouponSettingCalled = true }
        onCompletion(.success(()))
    }

    func retrieveAnalyticsSetting(siteID: Int64,
                                onCompletion: @escaping @Sendable (Result<Bool, Error>) -> Void) {
        state.withLock { $0.retrieveAnalyticsSettingCalled = true }
        onCompletion(.success(true))
    }

    func enableAnalyticsSetting(siteID: Int64,
                              onCompletion: @escaping @Sendable (Result<Void, Error>) -> Void) {
        state.withLock { $0.enableAnalyticsSettingCalled = true }
        onCompletion(.success(()))
    }

    func retrieveTaxBasedOnSetting(siteID: Int64,
                                 onCompletion: @escaping @Sendable (Result<Yosemite.TaxBasedOnSetting, Error>) -> Void) {
        state.withLock { $0.retrieveTaxBasedOnSettingCalled = true }
    }

    func isFeatureEnabled(siteID: Int64, feature: SiteSettingsFeature) async throws -> Bool {
        try state.withLock { try $0.featureEnabled.get() }
    }

    func retrievePointOfSaleSettings(siteID: Int64) async throws -> [SiteSetting] {
        try state.withLock {
            $0.retrievePointOfSaleSettingsCalled = true
            $0.retrievePointOfSaleSettingsSiteID = siteID
            return try $0.retrievePointOfSaleSettingsResult.get()
        }
    }

    func retrieveAnalyticsOrderDateType(siteID: Int64) async throws -> AnalyticsOrderDateType {
        try state.withLock {
            $0.retrieveAnalyticsOrderDateTypeReceivedSiteID = siteID
            return try $0.retrieveAnalyticsOrderDateTypeResult.get()
        }
    }

    func updateAnalyticsOrderDateType(siteID: Int64, value: AnalyticsOrderDateType) async throws {
        try state.withLock {
            $0.updateAnalyticsOrderDateTypeReceivedSiteID = siteID
            $0.updateAnalyticsOrderDateTypeReceivedValue = value
            try $0.updateAnalyticsOrderDateTypeResult.get()
        }
    }

    func retrieveAnalyticsImportUpdateMode(siteID: Int64) async throws -> AnalyticsImportUpdateMode {
        try state.withLock {
            $0.retrieveAnalyticsImportUpdateModeReceivedSiteID = siteID
            return try $0.retrieveAnalyticsImportUpdateModeResult.get()
        }
    }

    func updateAnalyticsImportUpdateMode(siteID: Int64, value: AnalyticsImportUpdateMode) async throws {
        try state.withLock {
            $0.updateAnalyticsImportUpdateModeReceivedSiteID = siteID
            $0.updateAnalyticsImportUpdateModeReceivedValue = value
            try $0.updateAnalyticsImportUpdateModeResult.get()
        }
    }
}
