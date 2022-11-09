import Combine
import SwiftUI
import Yosemite

/// View model for `DomainSelectorView`.
final class DomainSelectorViewModel: ObservableObject {
    /// Current search term entered by the user.
    /// Each update will trigger a remote call for domain suggestions.
    @Published var searchTerm: String = ""

    /// View models for each domain row after domain suggestions are loaded remotely.
    @Published private(set) var domainRows: [DomainRowViewModel] = []

    /// Subscription for search query changes for domain search.
    private var searchQuerySubscription: AnyCancellable?

    private let stores: StoresManager
    private let debounceDuration: Double

    init(stores: StoresManager = ServiceLocator.stores,
         debounceDuration: Double = Constants.fieldDebounceDuration) {
        self.stores = stores
        self.debounceDuration = debounceDuration
        observeDomainQuery()
    }
}

private extension DomainSelectorViewModel {
    func observeDomainQuery() {
        searchQuerySubscription = $searchTerm
            .filter { $0.isNotEmpty }
            .removeDuplicates()
            .debounce(for: .seconds(debounceDuration), scheduler: DispatchQueue.main)
            .sink { [weak self] searchTerm in
                guard let self = self else { return }
                Task { @MainActor in
                    let result = await self.loadFreeDomainSuggestions(query: searchTerm)
                    switch result {
                    case .success(let suggestions):
                        self.handleFreeDomainSuggestions(suggestions, query: searchTerm)
                    case .failure(let error):
                        self.handleError(error)
                    }
                }
            }
    }

    @MainActor
    func loadFreeDomainSuggestions(query: String) async -> Result<[FreeDomainSuggestion], Error> {
        await withCheckedContinuation { continuation in
            let action = DomainAction.loadFreeDomainSuggestions(query: searchTerm) { result in
                continuation.resume(returning: result)
            }
            stores.dispatch(action)
        }
    }

    @MainActor
    func handleFreeDomainSuggestions(_ suggestions: [FreeDomainSuggestion], query: String) {
        domainRows = suggestions
            .filter { $0.isFree }
            .map {
                DomainRowViewModel(domainName: $0.name, searchQuery: query)
            }
    }

    @MainActor
    func handleError(_ error: Error) {
        // TODO-8045: error handling - maybe show an error message.
        DDLogError("Cannot load domain suggestions for \(searchTerm)")
    }
}

private extension DomainSelectorViewModel {
    enum Constants {
        static let fieldDebounceDuration = 0.3
    }
}
