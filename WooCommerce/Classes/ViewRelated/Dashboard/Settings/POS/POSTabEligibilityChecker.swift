import Foundation
import UIKit
import class WooFoundation.CurrencySettings
import enum WooFoundation.CountryCode
import enum WooFoundation.CurrencyCode
import struct Yosemite.SiteSetting
import struct Yosemite.Site
import protocol Yosemite.StoresManager
import struct Yosemite.SystemPlugin
import enum Yosemite.FeatureFlagAction
import enum Yosemite.SettingAction
import protocol Yosemite.POSSystemStatusServiceProtocol
import class Yosemite.POSSystemStatusService
import protocol Yosemite.POSSiteSettingServiceProtocol
import class Yosemite.POSSiteSettingService
import class Yosemite.SiteAddress
import enum Networking.SiteSettingsFeature
import class WooFoundation.VersionHelpers
import protocol PointOfSale.POSEntryPointEligibilityCheckerProtocol
import enum PointOfSale.POSEligibilityState
import enum PointOfSale.POSIneligibleReason
import enum Yosemite.POSCountryCurrencyValidator
import protocol Yosemite.CardPresentPaymentsCountryExpansionEligibilityServiceProtocol
import class Yosemite.CardPresentPaymentsCountryExpansionEligibilityService

final class POSTabEligibilityChecker: POSEntryPointEligibilityCheckerProtocol {
    private let siteID: Int64
    private let siteSettings: SelectedSiteSettingsProtocol
    private let stores: StoresManager
    private let systemStatusService: POSSystemStatusServiceProtocol
    private let siteSettingService: POSSiteSettingServiceProtocol
    private let appPasswordSupportState: ApplicationPasswordsExperimentState
    private let expansionEligibilityService: CardPresentPaymentsCountryExpansionEligibilityServiceProtocol

    init(siteID: Int64,
         siteSettings: SelectedSiteSettingsProtocol = ServiceLocator.selectedSiteSettings,
         stores: StoresManager = ServiceLocator.stores,
         systemStatusService: POSSystemStatusServiceProtocol? = nil,
         siteSettingService: POSSiteSettingServiceProtocol? = nil,
         expansionEligibilityService: CardPresentPaymentsCountryExpansionEligibilityServiceProtocol = CardPresentPaymentsCountryExpansionEligibilityService()) {
        self.siteID = siteID
        self.siteSettings = siteSettings
        self.stores = stores
        self.expansionEligibilityService = expansionEligibilityService
        self.appPasswordSupportState = ApplicationPasswordsExperimentState()

        let credentials = stores.sessionManager.defaultCredentials
        let selectedSite = stores.sessionManager.defaultSitePublisher.map { $0?.toJetpackSite() }.eraseToAnyPublisher()
        let appPasswordSupport = appPasswordSupportState.$isAvailableAndEnabled.eraseToAnyPublisher()
        self.systemStatusService = systemStatusService ?? POSSystemStatusService(
            credentials: credentials,
            selectedSite: selectedSite,
            appPasswordSupportState: appPasswordSupport,
            storageManager: ServiceLocator.storageManager
        )
        self.siteSettingService = siteSettingService ?? POSSiteSettingService(
            credentials: credentials,
            selectedSite: selectedSite,
            appPasswordSupportState: appPasswordSupport
        )
    }

    /// Determines whether the POS entry point can be shown based on the selected store and feature gates.
    func checkEligibility() async -> POSEligibilityState {
        // Bypass eligibility checks for screenshot tests
        if ProcessConfiguration.shouldBypassPOSEligibilityChecks {
            return .eligible
        }

        async let siteSettingsEligibility = checkSiteSettingsEligibility()
        async let pluginEligibility = checkPluginEligibility()

        switch await siteSettingsEligibility {
        case .eligible:
            break
        case .ineligible(let reason):
            return .ineligible(reason: reason)
        }

        switch await pluginEligibility {
        case .eligible:
            return .eligible
        case .ineligible(let reason):
            return .ineligible(reason: reason)
        }
    }

    func refreshEligibility(ineligibleReason: POSIneligibleReason) async throws -> POSEligibilityState {
        switch ineligibleReason {
        case .siteSettingsNotAvailable, .unsupportedCurrency:
            do {
                try await syncSiteSettingsRemotely()
                return await checkEligibility()
            } catch POSTabEligibilityCheckerError.selfDeallocated {
                return .ineligible(reason: .selfDeallocated)
            } catch {
                throw error
            }
        case .unsupportedWooCommerceVersion, .wooCommercePluginNotFound:
            return await checkEligibility()
        case .featureSwitchDisabled:
            _ = try await siteSettingService.setFeature(siteID: siteID, feature: .pointOfSale, enabled: true)
            return await checkEligibility()
        case .selfDeallocated:
            return await checkEligibility()
        }
    }
}

// MARK: - WC Plugin Related Eligibility Check

private extension POSTabEligibilityChecker {
    /// Checks the eligibility of the WooCommerce plugin and plugin version based POS feature switch value.
    ///
    /// - Parameter pluginEligibility: An optional parameter that can provide pre-fetched plugin eligibility state.
    /// - Returns: The eligibility state for POS based on the WooCommerce plugin and POS feature switch.
    func checkPluginEligibility() async -> POSEligibilityState {
        do {
            let info = try await systemStatusService.loadWooCommercePluginAndPOSFeatureSwitch(siteID: siteID)
            let wcPluginEligibility = checkWooCommercePluginEligibility(wcPlugin: info.wcPlugin)
            switch wcPluginEligibility {
            case .eligible:
                return .eligible
            case .ineligible(let reason):
                return .ineligible(reason: reason)
            case .pendingFeatureSwitchCheck:
                let isFeatureSwitchEnabled = info.featureValue == true
                return isFeatureSwitchEnabled ? .eligible : .ineligible(reason: .featureSwitchDisabled)
            }
        } catch {
            return .ineligible(reason: .wooCommercePluginNotFound)
        }
    }

    enum PluginEligibilityState {
        case eligible
        case ineligible(reason: POSIneligibleReason)
        case pendingFeatureSwitchCheck
    }

    func checkWooCommercePluginEligibility(wcPlugin: SystemPlugin?) -> PluginEligibilityState {
        guard let wcPlugin, wcPlugin.active else {
            return .ineligible(reason: .wooCommercePluginNotFound)
        }

        guard VersionHelpers.isVersionSupported(version: wcPlugin.version,
                                                minimumRequired: Constants.wcPluginMinimumVersion) else {
            return .ineligible(reason: .unsupportedWooCommerceVersion(minimumVersion: Constants.wcPluginMinimumVersion))
        }

        // For versions below 10.0.0, the feature is enabled by default.
        let isFeatureSwitchSupported = VersionHelpers.isVersionSupported(version: wcPlugin.version,
                                                                         minimumRequired: Constants.wcPluginMinimumVersionWithFeatureSwitch,
                                                                         includesDevAndBetaVersions: true)
        if !isFeatureSwitchSupported {
            return .eligible
        }

        // For versions that support the feature switch, checks if the feature switch is enabled separately.
        return .pendingFeatureSwitchCheck
    }
}

// MARK: - Site Settings Related Eligibility Check

private extension POSTabEligibilityChecker {
    enum SiteSettingsEligibilityState {
        case eligible
        case ineligible(reason: SiteSettingsIneligibleReason)
    }

    enum SiteSettingsIneligibleReason {
        case siteSettingsNotAvailable
        case unsupportedCountry(supportedCountries: [CountryCode])
        case unsupportedCurrency(countryCode: CountryCode, supportedCurrencies: [CurrencyCode])
    }

    func checkSiteSettingsEligibility() async -> POSEligibilityState {
        let siteSettingsEligibility = await waitAndCheckSiteSettingsEligibility()
        switch siteSettingsEligibility {
        case .eligible:
            return .eligible
        case .ineligible(reason: let reason):
            switch reason {
            case .siteSettingsNotAvailable, .unsupportedCountry:
                // This is an edge case where the store country is expected to be eligible from the visilibity check, but site settings might have
                // changed to an unsupported country during the session. In this case, we return an ineligible reason that prompts the merchant to
                // relaunch the app.
                return .ineligible(reason: .siteSettingsNotAvailable)
            case let .unsupportedCurrency(countryCode: countryCode, supportedCurrencies: supportedCurrencies):
                return .ineligible(reason: .unsupportedCurrency(countryCode: countryCode, supportedCurrencies: supportedCurrencies))
            }
        }
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

        return isEligibleFromCountryAndCurrencyCode(countryCode: countryCode, currencyCode: currencyCode)
    }

    func waitForSiteSettingsRefresh() async -> [SiteSetting] {
        for await siteSettings in siteSettings.settingsStream.values {
            guard siteSettings.siteID == siteID, siteSettings.settings.isNotEmpty, siteSettings.source != .initialLoad else {
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
            siteID: siteID,
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

    @MainActor
    func syncSiteSettingsRemotely() async throws {
        try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<Void, Error>) in
            guard let self else {
                return continuation.resume(throwing: POSTabEligibilityCheckerError.selfDeallocated)
            }
            stores.dispatch(SettingAction.synchronizeGeneralSiteSettings(siteID: siteID) { [weak self] error in
                guard let self else {
                    return continuation.resume(throwing: POSTabEligibilityCheckerError.selfDeallocated)
                }
                if let error {
                    return continuation.resume(throwing: error)
                }
                siteSettings.refresh()
                continuation.resume(returning: ())
            })
        }
    }

}

private enum POSTabEligibilityCheckerError: Error {
    case selfDeallocated
}

private extension POSTabEligibilityChecker {
    enum Constants {
        static let wcPlugin = "woocommerce/woocommerce.php"
        static let wcPluginMinimumVersion = "9.6.0-beta"
        static let wcPluginMinimumVersionWithFeatureSwitch = "10.0.0"
    }
}
