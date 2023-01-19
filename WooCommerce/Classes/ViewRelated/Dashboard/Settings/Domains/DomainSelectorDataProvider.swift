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
    let productID: Int64

    init(domainSuggestion: PaidDomainSuggestion) {
        self.name = domainSuggestion.name
        self.attributedDetail = {
            var attributedCost = AttributedString(.init(format: Localization.priceFormat, domainSuggestion.cost, domainSuggestion.term))
            attributedCost.font = .body
            attributedCost.foregroundColor = .init(.secondaryLabel)

            if let saleCost = domainSuggestion.saleCost {
                attributedCost.strikethroughStyle = .single

                var attributedSaleCost = AttributedString(saleCost)
                attributedSaleCost.font = .body
                attributedSaleCost.foregroundColor = .init(.domainSalePrice)

                return attributedSaleCost + .init(" ") + attributedCost
            } else {
                return attributedCost
            }
        }()
        self.productID = domainSuggestion.productID
    }
}

private extension PaidDomainSuggestionViewModel {
    enum Localization {
        static let priceFormat = NSLocalizedString(
            "%1$@ / %2$@",
            comment: "The original price of a domain. %1$@ is the price per term. " +
            "%2$@ is the duration of each pricing term, usually year."
        )
    }
}

/// Provides domain suggestions that are paid.
final class PaidDomainSelectorDataProvider: DomainSelectorDataProvider {
    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    @MainActor
    func loadDomainSuggestions(query: String) async throws -> [PaidDomainSuggestionViewModel] {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(DomainAction.loadPaidDomainSuggestions(query: query) { result in
                continuation.resume(with: result.map { $0.map { PaidDomainSuggestionViewModel(domainSuggestion: $0) } })
            })
        }
    }
}
