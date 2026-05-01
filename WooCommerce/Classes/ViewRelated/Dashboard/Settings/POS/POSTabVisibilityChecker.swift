import Foundation
import UIKit
import class WooFoundation.CurrencySettings
import enum WooFoundation.CountryCode
import enum WooFoundation.CurrencyCode
import protocol Experiments.FeatureFlagService
import struct Yosemite.SiteSetting
import struct Yosemite.Site
import protocol Yosemite.POSEligibilityServiceProtocol
import protocol Yosemite.StoresManager
import class Yosemite.POSEligibilityService
import enum Yosemite.FeatureFlagAction
import class Yosemite.SiteAddress
import enum Yosemite.POSCountryCurrencyValidator
import protocol Yosemite.CardPresentPaymentsCountryExpansionEligibilityServiceProtocol
import class Yosemite.CardPresentPaymentsCountryExpansionEligibilityService
import class Yosemite.CardPresentPaymentsCountryExpansionEligibilityRefresher

final class POSTabVisibilityChecker: POSTabVisibilityCheckerProtocol {
    private let site: Site
    private let userInterfaceIdiom: UIUserInterfaceIdiom
    private let siteSettings: SelectedSiteSettingsProtocol
    private let eligibilityService: POSEligibilityServiceProtocol
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService
    private let expansionEligibilityService: CardPresentPaymentsCountryExpansionEligibilityServiceProtocol
    private let expansionEligibilityRefresher: CardPresentPaymentsCountryExpansionEligibilityRefresher

    init(site: Site,
         userInterfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom,
         siteSettings: SelectedSiteSettingsProtocol = ServiceLocator.selectedSiteSettings,
         eligibilityService: POSEligibilityServiceProtocol = POSEligibilityService(),
         stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         expansionEligibilityService: CardPresentPaymentsCountryExpansionEligibilityServiceProtocol = CardPresentPaymentsCountryExpansionEligibilityService(),
         expansionEligibilityRefresher: CardPresentPaymentsCountryExpansionEligibilityRefresher? = nil) {
        self.site = site
        self.userInterfaceIdiom = userInterfaceIdiom
        self.siteSettings = siteSettings
        self.eligibilityService = eligibilityService
        self.stores = stores
        self.featureFlagService = featureFlagService
        self.expansionEligibilityService = expansionEligibilityService
        self.expansionEligibilityRefresher = expansionEligibilityRefresher ?? CardPresentPaymentsCountryExpansionEligibilityRefresher(
            eligibilityService: expansionEligibilityService,
            remoteFeatureFlagProvider: CardPresentPaymentsCountryExpansionEligibilityRefresher.makeRemoteFeatureFlagProvider(stores: stores)
        )
    }

    /// Checks the initial visibility of the POS tab without dependance on network requests.
    func checkInitialVisibility() -> Bool {
        eligibilityService.loadCachedPOSTabVisibility(siteID: site.siteID) ?? false
    }

    /// Checks the initial visibility without the `POSTabVisibilityChecker` instsance
    /// Used for the initial state check when a site instance hasn't been loaded but a `siteID` is available
    static func checkInitialVisibility(
        for siteID: Int64,
        eligibilityService: POSEligibilityServiceProtocol = POSEligibilityService()
    ) -> Bool {
        return eligibilityService.loadCachedPOSTabVisibility(siteID: siteID) ?? false
    }

    /// Checks the final visibility of the POS tab.
    func checkVisibility() async -> Bool {
        guard userInterfaceIdiom == .pad else {
            return false
        }

        async let siteSettingsEligibility = waitAndCheckSiteSettingsEligibility()
        async let featureFlagEligibility = checkRemoteFeatureEligibility()

        switch await siteSettingsEligibility {
        case .ineligible(.unsupportedCountry):
            return false
        default:
            break
        }

        return await featureFlagEligibility == .eligible
    }
}

// MARK: - Site Settings Related Eligibility Check

private extension POSTabVisibilityChecker {
    enum SiteSettingsEligibilityState {
        case eligible
        case ineligible(reason: SiteSettingsIneligibleReason)
    }

    enum SiteSettingsIneligibleReason {
        case siteSettingsNotAvailable
        case unsupportedCountry(supportedCountries: [CountryCode])
        case unsupportedCurrency(countryCode: CountryCode, supportedCurrencies: [CurrencyCode])
    }

    func waitAndCheckSiteSettingsEligibility() async -> SiteSettingsEligibilityState {
        // Waits for the first site settings that matches the given site ID.
        let siteSettings = await waitForSiteSettingsRefresh()
        guard siteSettings.isNotEmpty else {
            return .ineligible(reason: .siteSettingsNotAvailable)
        }

        // Conditions that can change if site settings are synced during the lifetime.
        let countryCode = SiteAddress(siteSettings: siteSettings).countryCode
        let currencyCode = CurrencySettings(siteSettings: siteSettings).currencyCode

        // Refresh the per-site IPP country expansion eligibility cache (RSM-637) before
        // validating, so the country/currency check reflects the latest remote feature
        // flag rather than a stale or empty cache on first launch.
        await expansionEligibilityRefresher.refresh(siteID: site.siteID, countryCode: countryCode)

        return isEligibleFromCountryAndCurrencyCode(countryCode: countryCode, currencyCode: currencyCode)
    }

    func waitForSiteSettingsRefresh() async -> [SiteSetting] {
        for await siteSettings in siteSettings.settingsStream.values {
            guard siteSettings.siteID == site.siteID, siteSettings.settings.isNotEmpty, siteSettings.source != .initialLoad else {
                continue
            }
            return siteSettings.settings
        }
        // If we get here, the stream completed without yielding any values for our site ID which is unexpected.
        return []
    }

    func isEligibleFromCountryAndCurrencyCode(countryCode: CountryCode, currencyCode: CurrencyCode) -> SiteSettingsEligibilityState {
        let validationResult = POSCountryCurrencyValidator.validate(
            countryCode: countryCode,
            currencyCode: currencyCode,
            siteID: site.siteID,
            eligibilityService: expansionEligibilityService
        )

        switch validationResult {
        case .eligible:
            return .eligible
        case .ineligible(let reason):
            switch reason {
            case .unsupportedCountry(let supportedCountries):
                return .ineligible(reason: .unsupportedCountry(supportedCountries: supportedCountries))
            case .unsupportedCurrency(let countryCode, let supportedCurrencies):
                return .ineligible(reason: .unsupportedCurrency(countryCode: countryCode, supportedCurrencies: supportedCurrencies))
            }
        }
    }
}

// MARK: - Remote Feature Flag Eligibility Check

private extension POSTabVisibilityChecker {
    enum RemoteFeatureFlagEligibilityState: Equatable {
        case eligible
        case ineligible(reason: RemoteFeatureFlagIneligibleReason)
    }

    enum RemoteFeatureFlagIneligibleReason: Equatable {
        case selfDeallocated
        case featureFlagDisabled
    }

    @MainActor
    func checkRemoteFeatureEligibility() async -> RemoteFeatureFlagEligibilityState {
        // Only whitelisted accounts in WPCOM have the Point of Sale remote feature flag enabled. These can be found at D159901-code
        // If the account is whitelisted, then the remote value takes preference over the local feature flag configuration
        await withCheckedContinuation { [weak self] continuation in
            guard let self else {
                return continuation.resume(returning: .ineligible(reason: .selfDeallocated))
            }
            let action = FeatureFlagAction.isRemoteFeatureFlagEnabled(.pointOfSale, defaultValue: false) { [weak self] result in
                guard let self else {
                    return continuation.resume(returning: .ineligible(reason: .selfDeallocated))
                }
                switch result {
                case true:
                    // The site is whitelisted.
                    continuation.resume(returning: .eligible)
                case false:
                    // When the site is not whitelisted, check the local feature flag configuration.
                    let localFeatureFlag = featureFlagService.isFeatureFlagEnabled(.pointOfSale)
                    continuation.resume(returning: localFeatureFlag ? .eligible : .ineligible(reason: .featureFlagDisabled))
                }
            }
            self.stores.dispatch(action)
        }
    }
}
