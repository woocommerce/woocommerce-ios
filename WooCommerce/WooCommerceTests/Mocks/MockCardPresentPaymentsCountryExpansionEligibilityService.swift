import Foundation
import protocol Yosemite.CardPresentPaymentsCountryExpansionEligibilityServiceProtocol

final class MockCardPresentPaymentsCountryExpansionEligibilityService: CardPresentPaymentsCountryExpansionEligibilityServiceProtocol {
    private var eligibilityBySite: [Int64: Bool] = [:]

    init(initialEligibilityBySite: [Int64: Bool] = [:]) {
        self.eligibilityBySite = initialEligibilityBySite
    }

    func isEligible(siteID: Int64) -> Bool {
        eligibilityBySite[siteID] ?? false
    }

    func cacheEligibility(siteID: Int64, isEligible: Bool) {
        eligibilityBySite[siteID] = isEligible
    }
}
