import Foundation
import Testing
import Yosemite
import WooFoundationCore
import YosemiteTestHelpers
@testable import WooCommerce

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct WidgetSiteListSyncManagerTests {

    @Test func start_when_wpcom_credentials_then_writes_active_woo_sites() async {
        // Given
        let context = makeTestContext()
        await context.insert(sites: [
            Self.makeSite(siteID: 1, name: "Alpha", isWooCommerceActive: true),
            Self.makeSite(siteID: 2, name: "Beta", isWooCommerceActive: true),
            Self.makeSite(siteID: 3, name: "Non-Woo", isWooCommerceActive: false)
        ])

        // When
        context.sut.start()

        // Then
        let sites = context.widgetSiteListStore.sites()
        #expect(sites.map(\.siteID) == [1, 2])
        #expect(sites.map(\.name) == ["Alpha", "Beta"])
    }

    @Test func start_when_non_wpcom_credentials_then_writes_empty_list() async {
        // Given
        let context = makeTestContext(isWPCom: false)
        await context.insert(sites: [
            Self.makeSite(siteID: 1, name: "Alpha", isWooCommerceActive: true)
        ])

        // When
        context.sut.start()

        // Then
        #expect(context.widgetSiteListStore.sites().isEmpty)
    }

    @Test func start_when_sites_are_hidden_then_excludes_them() async {
        // Given
        let context = makeTestContext()
        context.userDefaults.saveHiddenStoreIDs([2])
        await context.insert(sites: [
            Self.makeSite(siteID: 1, name: "Alpha", isWooCommerceActive: true),
            Self.makeSite(siteID: 2, name: "Beta", isWooCommerceActive: true),
            Self.makeSite(siteID: 3, name: "Gamma", isWooCommerceActive: true)
        ])

        // When
        context.sut.start()

        // Then
        #expect(context.widgetSiteListStore.sites().map(\.siteID) == [1, 3])
    }

    @Test func start_when_default_site_is_set_then_sorts_default_first() async {
        // Given
        let context = makeTestContext(defaultStoreID: 2)
        await context.insert(sites: [
            Self.makeSite(siteID: 1, name: "Alpha", isWooCommerceActive: true),
            Self.makeSite(siteID: 2, name: "Beta", isWooCommerceActive: true),
            Self.makeSite(siteID: 3, name: "Gamma", isWooCommerceActive: true)
        ])

        // When
        context.sut.start()

        // Then
        #expect(context.widgetSiteListStore.sites().map(\.siteID) == [2, 1, 3])
    }

    @Test func start_when_general_site_settings_present_then_includes_currency_settings() async {
        // Given
        let context = makeTestContext()
        await context.insert(sites: [
            Self.makeSite(siteID: 1, name: "Alpha", isWooCommerceActive: true)
        ])
        await context.insert(siteSettings: Self.makeFullCurrencySiteSettings(siteID: 1, currencyCode: "EUR"))

        // When
        context.sut.start()

        // Then
        let sites = context.widgetSiteListStore.sites()
        #expect(sites.count == 1)
        #expect(sites[0].currencySettings?.currencyCode == .EUR)
    }

    @Test func start_when_general_site_settings_partial_then_omits_currency_settings() async {
        // Given
        let context = makeTestContext()
        await context.insert(sites: [
            Self.makeSite(siteID: 1, name: "Alpha", isWooCommerceActive: true)
        ])
        await context.insert(siteSettings: [
            Self.makeSiteSetting(siteID: 1, settingID: "woocommerce_currency", value: "EUR")
        ])

        // When
        context.sut.start()

        // Then
        let sites = context.widgetSiteListStore.sites()
        #expect(sites.count == 1)
        #expect(sites[0].currencySettings == nil)
    }

    @Test func start_when_settings_are_in_a_different_group_then_omits_currency_settings() async {
        // Given
        let context = makeTestContext()
        await context.insert(sites: [
            Self.makeSite(siteID: 1, name: "Alpha", isWooCommerceActive: true)
        ])
        // Insert with a non-general group - manager should ignore.
        await context.insert(siteSettings: Self.makeFullCurrencySiteSettings(siteID: 1,
                                                                              currencyCode: "EUR",
                                                                              settingGroupKey: "advanced"))

        // When
        context.sut.start()

        // Then
        #expect(context.widgetSiteListStore.sites().first?.currencySettings == nil)
    }

    @Test func storage_change_when_site_added_then_rebuilds_list() async {
        // Given
        let context = makeTestContext()
        await context.insert(sites: [
            Self.makeSite(siteID: 1, name: "Alpha", isWooCommerceActive: true)
        ])
        context.sut.start()
        #expect(context.widgetSiteListStore.sites().map(\.siteID) == [1])

        // When
        await context.insert(sites: [
            Self.makeSite(siteID: 2, name: "Beta", isWooCommerceActive: true)
        ])

        // Then
        #expect(context.widgetSiteListStore.sites().map(\.siteID) == [1, 2])
    }

    @Test func logOut_event_when_received_then_clears_list() async throws {
        // Given
        let context = makeTestContext()
        await context.insert(sites: [
            Self.makeSite(siteID: 1, name: "Alpha", isWooCommerceActive: true)
        ])
        context.sut.start()
        #expect(context.widgetSiteListStore.sites().isEmpty == false)

        // When
        context.notificationCenter.post(name: .logOutEventReceived, object: nil)
        try await Task.sleep(for: .milliseconds(50))

        // Then
        #expect(context.widgetSiteListStore.sites().isEmpty)
    }

    @Test func stop_when_called_after_start_then_clears_list() async {
        // Given
        let context = makeTestContext()
        await context.insert(sites: [
            Self.makeSite(siteID: 1, name: "Alpha", isWooCommerceActive: true)
        ])
        context.sut.start()
        #expect(context.widgetSiteListStore.sites().isEmpty == false)

        // When
        context.sut.stop()

        // Then
        #expect(context.widgetSiteListStore.sites().isEmpty)
    }

    @Test func start_when_called_twice_then_does_not_throw_or_duplicate_writes() async {
        // Given
        let context = makeTestContext()
        await context.insert(sites: [
            Self.makeSite(siteID: 1, name: "Alpha", isWooCommerceActive: true)
        ])

        // When
        context.sut.start()
        context.sut.start()

        // Then
        #expect(context.widgetSiteListStore.sites().count == 1)
    }
}

// MARK: - Test context

private extension WidgetSiteListSyncManagerTests {
    @MainActor
    final class TestContext {
        let storageManager: MockStorageManager
        let sessionManager: SessionManager
        let stores: MockStoresManager
        let userDefaults: UserDefaults
        let widgetSiteListStore: WidgetSiteListStore
        let notificationCenter: NotificationCenter
        let sut: WidgetSiteListSyncManager

        init(storageManager: MockStorageManager,
             sessionManager: SessionManager,
             stores: MockStoresManager,
             userDefaults: UserDefaults,
             widgetSiteListStore: WidgetSiteListStore,
             notificationCenter: NotificationCenter,
             sut: WidgetSiteListSyncManager) {
            self.storageManager = storageManager
            self.sessionManager = sessionManager
            self.stores = stores
            self.userDefaults = userDefaults
            self.widgetSiteListStore = widgetSiteListStore
            self.notificationCenter = notificationCenter
            self.sut = sut
        }

        deinit {
            sut.stop()
        }

        func insert(sites: [Site]) async {
            await withCheckedContinuation { continuation in
                storageManager.performAndSave({ [storageManager] _ in
                    sites.forEach { storageManager.insertSampleSite(readOnlySite: $0) }
                }, completion: {
                    continuation.resume()
                }, on: .main)
            }
        }

        func insert(siteSettings: [SiteSetting]) async {
            await withCheckedContinuation { continuation in
                storageManager.performAndSave({ [storageManager] _ in
                    siteSettings.forEach { storageManager.insertSampleSiteSetting(readOnlySiteSetting: $0) }
                }, completion: {
                    continuation.resume()
                }, on: .main)
            }
        }
    }

    func makeTestContext(isWPCom: Bool = true,
                         defaultStoreID: Int64? = nil) -> TestContext {
        let storageManager = MockStorageManager()

        let sessionSuiteName = "WidgetSiteListSyncManagerTests-session-\(UUID().uuidString)"
        let sessionDefaults = UserDefaults(suiteName: sessionSuiteName)!
        sessionDefaults.removePersistentDomain(forName: sessionSuiteName)
        let sessionKeychainName = "com.woocommerce.tests.widget-site-list.\(UUID().uuidString)"

        let sessionManager = SessionManager(defaults: sessionDefaults,
                                            keychainServiceName: sessionKeychainName)
        sessionManager.defaultCredentials = isWPCom ? SessionSettings.wpcomCredentials : SessionSettings.wporgCredentials
        sessionManager.defaultStoreID = defaultStoreID
        let stores = MockStoresManager(sessionManager: sessionManager)

        let suiteName = "WidgetSiteListSyncManagerTests-\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)

        let widgetSiteListStore = WidgetSiteListStore(userDefaults: userDefaults)
        let notificationCenter = NotificationCenter()

        let sut = WidgetSiteListSyncManager(stores: stores,
                                            storageManager: storageManager,
                                            widgetSiteListStore: widgetSiteListStore,
                                            userDefaults: userDefaults,
                                            notificationCenter: notificationCenter)

        return TestContext(storageManager: storageManager,
                           sessionManager: sessionManager,
                           stores: stores,
                           userDefaults: userDefaults,
                           widgetSiteListStore: widgetSiteListStore,
                           notificationCenter: notificationCenter,
                           sut: sut)
    }
}

// MARK: - Sample factories

private extension WidgetSiteListSyncManagerTests {
    static func makeSite(siteID: Int64,
                         name: String,
                         isWooCommerceActive: Bool,
                         timezone: String = "UTC",
                         gmtOffset: Double = 0) -> Site {
        Site.fake().copy(siteID: siteID,
                         name: name,
                         isWooCommerceActive: isWooCommerceActive,
                         timezone: timezone,
                         gmtOffset: gmtOffset)
    }

    static func makeSiteSetting(siteID: Int64,
                                settingID: String,
                                value: String,
                                settingGroupKey: String = SiteSettingGroup.general.rawValue) -> SiteSetting {
        SiteSetting.fake().copy(siteID: siteID,
                                settingID: settingID,
                                value: value,
                                settingGroupKey: settingGroupKey)
    }

    static func makeFullCurrencySiteSettings(siteID: Int64,
                                             currencyCode: String,
                                             settingGroupKey: String = SiteSettingGroup.general.rawValue) -> [SiteSetting] {
        [
            ("woocommerce_currency", currencyCode),
            ("woocommerce_currency_pos", "left"),
            ("woocommerce_price_thousand_sep", ","),
            ("woocommerce_price_decimal_sep", "."),
            ("woocommerce_price_num_decimals", "2")
        ].map { (settingID, value) in
            makeSiteSetting(siteID: siteID, settingID: settingID, value: value, settingGroupKey: settingGroupKey)
        }
    }
}
