import Foundation
import Yosemite

/// Provides domain suggestions data of a generic type.
/// The generic type allows different domain suggestion schemas, like free and paid domains.
protocol DomainSelectorDataProvider {
    associatedtype DomainSuggestion

    /// Loads domain suggestions async from the remote.
    /// - Parameter query: Search query for the domain suggestions.
    /// - Returns: A list of domain suggestions.
    func loadDomainSuggestions(query: String) async throws -> [DomainSuggestion]
}

/// View model for free domain suggestion UI that shows the domain name.
struct FreeDomainSuggestionViewModel: DomainSuggestionViewProperties, Equatable {
    let name: String
    let attributedDetail: AttributedString? = nil

    init(domainSuggestion: FreeDomainSuggestion) {
        self.name = domainSuggestion.name
    }
}

/// Provides domain suggestions that are free.
final class FreeDomainSelectorDataProvider: DomainSelectorDataProvider {
    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    @MainActor
    func loadDomainSuggestions(query: String) async throws -> [FreeDomainSuggestionViewModel] {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(DomainAction.loadFreeDomainSuggestions(query: query) { result in
                continuation.resume(with: result.map { $0
                    .filter { $0.isFree }
                    .map { FreeDomainSuggestionViewModel(domainSuggestion: $0) }
                })
            })
        }
    }
}

/// View model for paid domain suggestion UI that shows the domain name and attributed price info.
/// The product ID is for creating a cart after a domain is selected.
struct PaidDomainSuggestionViewModel: DomainSuggestionViewProperties, Equatable {
    let name: String
    let attributedDetail: AttributedString?

    /// Whether the domain is a premium domain. A premium domain cannot be redeemed with domain credit.
    let isPremium: Bool

    // Properties for cart creation after a domain is selected.
    let productID: Int64
    let supportsPrivacy: Bool
    let hasDomainCredit: Bool

    init(domainSuggestion: PaidDomainSuggestion, hasDomainCredit: Bool) {
        self.name = domainSuggestion.name
        self.attributedDetail = {
            var attributedCost = AttributedString(.init(format: Localization.priceFormat, domainSuggestion.cost, domainSuggestion.term))
            attributedCost.font = .body
            attributedCost.foregroundColor = .init(.secondaryLabel)

            if hasDomainCredit && !domainSuggestion.isPremium {
                // Strikethrough style for the original cost string.
                attributedCost.strikethroughStyle = .single

                var attributedDomainCreditPricing = AttributedString(Localization.domainCreditPricing)
                attributedDomainCreditPricing.font = .body
                attributedDomainCreditPricing.foregroundColor = .init(.domainCreditPricing)

                return attributedCost + .init(" ") + attributedDomainCreditPricing
            } else if let saleCost = domainSuggestion.saleCost {
                // Strikethrough style for the original cost string.
                if let range = attributedCost.range(of: domainSuggestion.cost) {
                    attributedCost[range].strikethroughStyle = .single
                }

                var attributedSaleCost = AttributedString(saleCost)
                attributedSaleCost.font = .body
                attributedSaleCost.foregroundColor = .init(.domainSalePrice)

                return attributedSaleCost + .init(" ") + attributedCost
            } else {
                return attributedCost
            }
        }()
        self.isPremium = domainSuggestion.isPremium
        self.productID = domainSuggestion.productID
        self.supportsPrivacy = domainSuggestion.supportsPrivacy
        self.hasDomainCredit = hasDomainCredit
    }
}

extension PaidDomainSuggestionViewModel {
    enum Localization {
        static let priceFormat = NSLocalizedString(
            "%1$@ / %2$@",
            comment: "The original price of a domain. %1$@ is the price per term. " +
            "%2$@ is the duration of each pricing term, usually year."
        )
        static let domainCreditPricing = NSLocalizedString(
            "Free for the first year",
            comment: "Label shown for domains that are free for the first year with available domain credit."
        )
    }
}

/// Provides domain suggestions that are paid.
final class PaidDomainSelectorDataProvider: DomainSelectorDataProvider {
    private let stores: StoresManager
    private let hasDomainCredit: Bool

    init(stores: StoresManager = ServiceLocator.stores, hasDomainCredit: Bool) {
        self.stores = stores
        self.hasDomainCredit = hasDomainCredit
    }

    @MainActor
    func loadDomainSuggestions(query: String) async throws -> [PaidDomainSuggestionViewModel] {
        return try await withCheckedThrowingContinuation { [hasDomainCredit] continuation in
            stores.dispatch(DomainAction.loadPaidDomainSuggestions(query: query, currencySettings: ServiceLocator.currencySettings) { result in
                continuation.resume(with: result.map { $0.map { PaidDomainSuggestionViewModel(domainSuggestion: $0,
                                                                                              hasDomainCredit: hasDomainCredit) } })
            })
        }
    }
}
