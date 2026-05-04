import Foundation
import Testing
import Storage
@testable import Yosemite

@Suite("CardPresentPaymentsCountryExpansionEligibilityService Tests")
struct CardPresentPaymentsCountryExpansionEligibilityServiceTests {
    private let siteID: Int64 = 1234

    @Test("isEligible returns false when no value has been cached")
    func test_isEligible_returns_false_when_uncached() {
        // Given
        let mockStore = MockSiteSpecificAppSettingsStoreMethods()
        mockStore.currentSiteID = siteID
        let service = CardPresentPaymentsCountryExpansionEligibilityService(siteSpecificAppSettingsStoreMethods: mockStore)

        // When / Then
        #expect(service.isEligible(siteID: siteID) == false)
    }

    @Test("isEligible returns true after cacheEligibility(true)")
    func test_isEligible_returns_true_after_caching_true() {
        // Given
        let mockStore = MockSiteSpecificAppSettingsStoreMethods()
        mockStore.currentSiteID = siteID
        let service = CardPresentPaymentsCountryExpansionEligibilityService(siteSpecificAppSettingsStoreMethods: mockStore)

        // When
        service.cacheEligibility(siteID: siteID, isEligible: true)

        // Then
        #expect(service.isEligible(siteID: siteID) == true)
    }

    @Test("isEligible returns false after cacheEligibility(false)")
    func test_isEligible_returns_false_after_caching_false() {
        // Given
        let mockStore = MockSiteSpecificAppSettingsStoreMethods()
        mockStore.currentSiteID = siteID
        mockStore.mockCardPresentPaymentsCountryExpansionEligibility = true
        let service = CardPresentPaymentsCountryExpansionEligibilityService(siteSpecificAppSettingsStoreMethods: mockStore)

        // When
        service.cacheEligibility(siteID: siteID, isEligible: false)

        // Then
        #expect(service.isEligible(siteID: siteID) == false)
        #expect(mockStore.spySavedCardPresentPaymentsCountryExpansionEligibility == false)
        #expect(mockStore.spySavedCardPresentPaymentsCountryExpansionEligibilitySiteID == siteID)
    }

    @Test("cacheEligibility persists per site via the storage methods")
    func test_cacheEligibility_persists_per_site() {
        // Given
        let mockStore = MockSiteSpecificAppSettingsStoreMethods()
        mockStore.currentSiteID = siteID
        let service = CardPresentPaymentsCountryExpansionEligibilityService(siteSpecificAppSettingsStoreMethods: mockStore)

        // When
        service.cacheEligibility(siteID: siteID, isEligible: true)

        // Then
        #expect(mockStore.saveCardPresentPaymentsCountryExpansionEligibilityCalled == true)
        #expect(mockStore.spySavedCardPresentPaymentsCountryExpansionEligibility == true)
        #expect(mockStore.spySavedCardPresentPaymentsCountryExpansionEligibilitySiteID == siteID)
    }
}
