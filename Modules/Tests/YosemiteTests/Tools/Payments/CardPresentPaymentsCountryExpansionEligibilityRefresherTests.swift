import Foundation
import Testing
import enum WooFoundation.CountryCode
@testable import Yosemite

@Suite("CardPresentPaymentsCountryExpansionEligibilityRefresher Tests")
struct CardPresentPaymentsCountryExpansionEligibilityRefresherTests {
    private let siteID: Int64 = 99

    // MARK: - Country → flag mapping

    @Test("flag(for:) returns nil for existing supported countries")
    func test_flag_for_existing_supported_countries() {
        for country in [CountryCode.US, .PR, .CA, .GB] {
            #expect(CardPresentPaymentsCountryExpansionEligibilityRefresher.flag(for: country) == nil,
                    "Expected \(country) to require no expansion flag")
        }
    }

    @Test("flag(for:) returns inPersonPaymentsCountryExpansion for the primary group")
    func test_flag_for_primary_expansion_group() {
        for country in [CountryCode.FR, .DE, .IE, .NL, .SG, .NZ] {
            #expect(CardPresentPaymentsCountryExpansionEligibilityRefresher.flag(for: country)
                    == .inPersonPaymentsCountryExpansion,
                    "Expected \(country) to map to inPersonPaymentsCountryExpansion")
        }
    }

    @Test("flag(for:) returns inPersonPaymentsCountryExpansionEUExtended for the EU extended group")
    func test_flag_for_eu_extended_expansion_group() {
        for country in [CountryCode.AT, .BE, .FI, .IT, .LU, .PT, .ES] {
            #expect(CardPresentPaymentsCountryExpansionEligibilityRefresher.flag(for: country)
                    == .inPersonPaymentsCountryExpansionEUExtended,
                    "Expected \(country) to map to inPersonPaymentsCountryExpansionEUExtended")
        }
    }

    @Test("flag(for:) returns nil for AU (intentionally excluded — RSM-642/643)")
    func test_flag_for_excluded_australia() {
        #expect(CardPresentPaymentsCountryExpansionEligibilityRefresher.flag(for: .AU) == nil)
    }

    // MARK: - Refresh behaviour

    @Test("refresh short-circuits to true for existing supported countries without dispatching a flag")
    func test_refresh_short_circuits_for_existing_country() async {
        // Given
        let service = SpyEligibilityService()
        var providerInvocations: [RemoteFeatureFlag] = []
        let refresher = CardPresentPaymentsCountryExpansionEligibilityRefresher(
            eligibilityService: service,
            remoteFeatureFlagProvider: { flag in
                providerInvocations.append(flag)
                return false
            }
        )

        // When
        await refresher.refresh(siteID: siteID, countryCode: .US)

        // Then
        #expect(providerInvocations.isEmpty, "Existing supported country must not dispatch a flag check")
        #expect(service.cachedValues == [siteID: true])
    }

    @Test("refresh persists the provider's true value for primary-group countries")
    func test_refresh_persists_true_for_primary_group_when_flag_on() async {
        // Given
        let service = SpyEligibilityService()
        let refresher = CardPresentPaymentsCountryExpansionEligibilityRefresher(
            eligibilityService: service,
            remoteFeatureFlagProvider: { flag in
                #expect(flag == .inPersonPaymentsCountryExpansion)
                return true
            }
        )

        // When
        await refresher.refresh(siteID: siteID, countryCode: .FR)

        // Then
        #expect(service.cachedValues == [siteID: true])
    }

    @Test("refresh persists the provider's false value for primary-group countries")
    func test_refresh_persists_false_for_primary_group_when_flag_off() async {
        // Given
        let service = SpyEligibilityService()
        let refresher = CardPresentPaymentsCountryExpansionEligibilityRefresher(
            eligibilityService: service,
            remoteFeatureFlagProvider: { _ in false }
        )

        // When
        await refresher.refresh(siteID: siteID, countryCode: .NZ)

        // Then
        #expect(service.cachedValues == [siteID: false])
    }

    @Test("refresh dispatches inPersonPaymentsCountryExpansionEUExtended for EU extended countries")
    func test_refresh_dispatches_eu_extended_flag() async {
        // Given
        let service = SpyEligibilityService()
        var dispatchedFlag: RemoteFeatureFlag?
        let refresher = CardPresentPaymentsCountryExpansionEligibilityRefresher(
            eligibilityService: service,
            remoteFeatureFlagProvider: { flag in
                dispatchedFlag = flag
                return true
            }
        )

        // When
        await refresher.refresh(siteID: siteID, countryCode: .ES)

        // Then
        #expect(dispatchedFlag == .inPersonPaymentsCountryExpansionEUExtended)
        #expect(service.cachedValues == [siteID: true])
    }

    @Test("refresh persists per site")
    func test_refresh_persists_per_site() async {
        // Given
        let service = SpyEligibilityService()
        let refresher = CardPresentPaymentsCountryExpansionEligibilityRefresher(
            eligibilityService: service,
            remoteFeatureFlagProvider: { _ in true }
        )

        // When
        await refresher.refresh(siteID: 1, countryCode: .DE)
        await refresher.refresh(siteID: 2, countryCode: .ES)
        await refresher.refresh(siteID: 3, countryCode: .US)

        // Then
        #expect(service.cachedValues == [1: true, 2: true, 3: true])
    }
}

// MARK: - Test Helpers

private final class SpyEligibilityService: CardPresentPaymentsCountryExpansionEligibilityServiceProtocol {
    private(set) var cachedValues: [Int64: Bool] = [:]

    func isEligible(siteID: Int64) -> Bool {
        cachedValues[siteID] ?? false
    }

    func cacheEligibility(siteID: Int64, isEligible: Bool) {
        cachedValues[siteID] = isEligible
    }
}
