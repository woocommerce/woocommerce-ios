import Foundation
import WooFoundation

/// Provides information about which catalog mode is being used for Point of Sale
public protocol POSCatalogModeProviderProtocol {
    /// Checks eligibility and determines whether the local GRDB catalog should be used.
    ///
    /// This performs a one-time async check of all eligibility criteria and caches the result.
    /// Subsequent calls return the cached value immediately.
    ///
    /// - Parameter siteID: The site ID to check
    /// - Returns: True if local catalog should be used based on all eligibility criteria
    func shouldUseLocalCatalog(for siteID: Int64) async -> Bool
}

/// Determines catalog mode based on comprehensive eligibility criteria.
///
/// This provider evaluates all requirements for local catalog functionality:
/// - Feature flag enablement (gates the entire feature)
/// - Country support (US, GB only)
/// - Currency support (USD for US, GBP for GB)
/// - Catalog size limits (≤1000 items: products + variations)
///
/// The eligibility check is performed once per site and cached, as these criteria
/// don't change during a session (except via app restart or site change).
public final class POSCatalogModeProvider: POSCatalogModeProviderProtocol {
    private let isFeatureFlagEnabled: Bool
    private let catalogSizeChecker: POSCatalogSizeCheckerProtocol
    private let currencySettings: CurrencySettings
    private let siteAddress: SiteAddress

    // Cache eligibility result per site
    private var eligibilityCache: [Int64: Bool] = [:]

    public init(isFeatureFlagEnabled: Bool,
                catalogSizeChecker: POSCatalogSizeCheckerProtocol,
                currencySettings: CurrencySettings,
                siteAddress: SiteAddress) {
        self.isFeatureFlagEnabled = isFeatureFlagEnabled
        self.catalogSizeChecker = catalogSizeChecker
        self.currencySettings = currencySettings
        self.siteAddress = siteAddress
    }

    public func shouldUseLocalCatalog(for siteID: Int64) async -> Bool {
        // Check cache first
        if let cached = eligibilityCache[siteID] {
            return cached
        }

        // Perform comprehensive eligibility check
        let isEligible = await checkEligibility(for: siteID)

        // Cache the result
        eligibilityCache[siteID] = isEligible

        return isEligible
    }

    private func checkEligibility(for siteID: Int64) async -> Bool {
        // 1. Feature flag must be enabled
        guard isFeatureFlagEnabled else {
            DDLogInfo("📋 POSCatalogModeProvider: Local catalog disabled - feature flag not enabled")
            return false
        }

        // 2. Country must be supported (US or GB)
        let supportedCountries: [CountryCode] = [.US, .GB]
        guard supportedCountries.contains(siteAddress.countryCode) else {
            DDLogInfo("📋 POSCatalogModeProvider: Local catalog disabled - unsupported country: \(siteAddress.countryCode)")
            return false
        }

        // 3. Currency must match country requirements
        let supportedCurrencies: [CountryCode: [CurrencyCode]] = [
            .US: [.USD],
            .GB: [.GBP]
        ]
        let expectedCurrencies = supportedCurrencies[siteAddress.countryCode] ?? []
        guard expectedCurrencies.contains(currencySettings.currencyCode) else {
            DDLogInfo("📋 POSCatalogModeProvider: Local catalog disabled - unsupported currency: \(currencySettings.currencyCode) for country: \(siteAddress.countryCode)")
            return false
        }

        // 4. Catalog size must be within limits
        do {
            let catalogSize = try await catalogSizeChecker.checkCatalogSize(for: siteID)
            let sizeLimit = Constants.defaultSizeLimitForPOSCatalog
            guard catalogSize.totalCount <= sizeLimit else {
                DDLogInfo("📋 POSCatalogModeProvider: Local catalog disabled - catalog too large: \(catalogSize.totalCount) > \(sizeLimit)")
                return false
            }
        } catch {
            DDLogError("⚠️ POSCatalogModeProvider: Failed to check catalog size for site \(siteID): \(error)")
            return false
        }

        DDLogInfo("✅ POSCatalogModeProvider: Local catalog enabled for site \(siteID)")
        return true
    }
}

private extension POSCatalogModeProvider {
    enum Constants {
        /// Maximum number of items (products + variations) supported for local catalog
        static let defaultSizeLimitForPOSCatalog = 1000
    }
}
