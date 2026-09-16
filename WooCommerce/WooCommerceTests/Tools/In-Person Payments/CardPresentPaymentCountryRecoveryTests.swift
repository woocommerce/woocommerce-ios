import Combine
import Foundation
import Testing
import Yosemite
import WooFoundation
@testable import WooCommerce

@MainActor
struct CardPresentPaymentCountryRecoveryTests {
    private let siteID: Int64 = 123

    @Test func test_recovery_when_settings_arrive_then_resolves_country() {
        // Given
        let stores = makeStores()
        let settings = MockSelectedSiteSettings()
        var requests = 0
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            guard case let .synchronizeGeneralSiteSettings(_, completion) = action else { return }
            requests += 1
            settings.siteSettings = [countrySetting(.GB)]
            completion(nil)
        }
        let sut = makeRecovery(stores: stores, settings: settings)

        // When
        sut.recoverIfNeeded()
        sut.recoverIfNeeded()

        // Then
        #expect(sut.configuration.countryCode == .GB)
        #expect(sut.notice == nil)
        #expect(!sut.isLoading)
        #expect(requests == 1)
    }

    @Test func test_recovery_when_request_fails_then_stops_until_explicit_retry() throws {
        // Given
        let stores = makeStores()
        let settings = MockSelectedSiteSettings()
        var requests = 0
        var complete: ((Error?) -> Void)?
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            guard case let .synchronizeGeneralSiteSettings(_, completion) = action else { return }
            requests += 1
            complete = completion
        }
        let sut = makeRecovery(stores: stores, settings: settings)

        // When
        sut.recoverIfNeeded()
        sut.recoverIfNeeded()
        #expect(sut.isLoading)
        #expect(requests == 1)
        let failRequest = try #require(complete)
        failRequest(NSError(domain: "Settings", code: 1))
        sut.recoverIfNeeded()

        // Then
        #expect(requests == 1)
        #expect(!sut.isLoading)
        let notice = try #require(sut.notice)
        notice.callToActionHandler()
        #expect(requests == 2)
        settings.siteSettings = [countrySetting(.GB)]
        let finishRequest = try #require(complete)
        finishRequest(nil)
        #expect(sut.configuration.countryCode == .GB)
        #expect(sut.notice == nil)
    }

    @Test(arguments: [CountryCode.GB, .LT])
    func test_recovery_when_country_is_known_then_does_not_request_settings(country: CountryCode) {
        // Given
        let stores = makeStores()
        var requested = false
        stores.whenReceivingAction(ofType: SettingAction.self) { _ in requested = true }
        let sut = makeRecovery(country: country, stores: stores, settings: MockSelectedSiteSettings())

        // When
        sut.recoverIfNeeded()
        sut.retry()

        // Then
        #expect(!requested)
        #expect(sut.notice == nil)
        #expect(sut.configuration.countryCode == country)
    }

    @Test func test_recovery_when_response_has_no_country_then_offers_retry_without_looping() {
        // Given
        let stores = makeStores()
        var requests = 0
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            guard case let .synchronizeGeneralSiteSettings(_, completion) = action else { return }
            requests += 1
            completion(nil)
        }
        let sut = makeRecovery(stores: stores, settings: MockSelectedSiteSettings())

        // When
        sut.recoverIfNeeded()
        sut.recoverIfNeeded()

        // Then
        #expect(requests == 1)
        #expect(sut.notice != nil)
        #expect(!sut.isLoading)
    }

    @Test func test_settings_update_when_for_another_site_then_ignores_country() {
        // Given
        let settings = MockSelectedSiteSettings()
        let changes = PassthroughSubject<MockSelectedSiteSettings.SettingsUpdate, Never>()
        settings.mockSettingsStream = changes.eraseToAnyPublisher()
        let sut = makeRecovery(stores: makeStores(), settings: settings)

        // When
        changes.send((siteID: siteID + 1, settings: [countrySetting(.GB)], source: .storageChange))

        // Then
        #expect(sut.configuration.countryCode == .unknown)
        changes.send((siteID: siteID, settings: [countrySetting(.LT)], source: .storageChange))
        #expect(sut.configuration.countryCode == .LT)
        #expect(sut.notice == nil)
    }

    @Test func test_recovery_when_store_changes_during_request_then_ignores_result() throws {
        // Given
        let stores = makeStores()
        let settings = MockSelectedSiteSettings()
        var complete: ((Error?) -> Void)?
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            guard case let .synchronizeGeneralSiteSettings(_, completion) = action else { return }
            complete = completion
        }
        let sut = makeRecovery(stores: stores, settings: settings)
        sut.recoverIfNeeded()

        // When
        stores.sessionManager.setStoreId(siteID + 1)
        settings.siteSettings = [countrySetting(.GB)]
        let finishRequest = try #require(complete)
        finishRequest(nil)

        // Then
        #expect(sut.configuration.countryCode == .unknown)
        #expect(settings.refreshCallCount == 0)
        #expect(sut.notice == nil)
        #expect(!sut.isLoading)
    }

    private func makeStores() -> MockStoresManager {
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.sessionManager.setStoreId(siteID)
        return stores
    }

    private func makeRecovery(country: CountryCode = .unknown,
                              stores: StoresManager,
                              settings: SelectedSiteSettingsProtocol) -> CardPresentPaymentCountryRecovery {
        CardPresentPaymentCountryRecovery(siteID: siteID, configuration: .init(country: country), stores: stores, settings: settings)
    }

    private func countrySetting(_ country: CountryCode) -> SiteSetting {
        .fake().copy(siteID: siteID, settingID: "woocommerce_default_country", value: country.rawValue, settingGroupKey: "general")
    }
}
