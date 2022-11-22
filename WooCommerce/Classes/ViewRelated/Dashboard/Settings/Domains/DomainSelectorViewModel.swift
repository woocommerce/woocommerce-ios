import Combine
import SwiftUI
import Yosemite
import enum Networking.DotcomError

/// View model for `DomainSelectorView`.
final class DomainSelectorViewModel: ObservableObject {
    /// Current search term entered by the user.
    /// Each update will trigger a remote call for domain suggestions.
    @Published var searchTerm: String = ""

    /// Domain names after domain suggestions are loaded remotely.
    @Published private var domains: [String] = []

    /// Error message from loading domain suggestions.
    @Published private var errorMessage: String?

    /// Whether domain suggestions are being loaded.
    @Published private(set) var isLoadingDomainSuggestions: Bool = false

    /// The state of the main domain selector view based on the search query and loading state.
    @Published private(set) var state: DomainSelectorView.ViewState = .placeholder

    /// Subscription for search query changes for domain search.
    private var searchQuerySubscription: AnyCancellable?

    private let stores: StoresManager
    private let debounceDuration: Double

    init(initialSearchTerm: String = "",
         stores: StoresManager = ServiceLocator.stores,
         debounceDuration: Double = Constants.fieldDebounceDuration) {
        self.stores = stores
        self.debounceDuration = debounceDuration

        // Sets the initial search term after related subscriptions are set up
        // so that the initial value is always emitted.
        // In `observeDomainQuery`, `share()` transforms the publisher to `PassthroughSubject`
        // and thus the initial value isn't emitted in `observeDomainQuery` until setting the value afterward.
        observeDomainQuery()
        self.searchTerm = initialSearchTerm

        configureState()
    }
}

private extension DomainSelectorViewModel {
    func observeDomainQuery() {
        searchQuerySubscription = $searchTerm
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .debounce(for: .seconds(debounceDuration), scheduler: DispatchQueue.main)
            .filter { $0.isNotEmpty }
            .removeDuplicates()
            .sink { [weak self] searchTerm in
                guard let self = self else { return }
                Task { @MainActor in
                    self.errorMessage = nil
                    self.isLoadingDomainSuggestions = true
                    let result = await self.loadFreeDomainSuggestions(query: searchTerm)
                    self.isLoadingDomainSuggestions = false

                    switch result {
                    case .success(let suggestions):
                        self.handleFreeDomainSuggestions(suggestions, query: searchTerm)
                    case .failure(let error):
                        self.handleError(error)
                    }
                }
            }
    }

    func configureState() {
        Publishers.CombineLatest4($searchTerm, $isLoadingDomainSuggestions, $errorMessage, $domains)
            .map { searchTerm, isLoadingDomainSuggestions, errorMessage, domains in
                if searchTerm.isEmpty {
                    return .placeholder
                } else if isLoadingDomainSuggestions {
                    return .loading
                } else if let errorMessage {
                    return .error(message: errorMessage)
                } else {
                    return .results(domains: domains)
                }
            }
            .assign(to: &$state)
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
        domains = suggestions
            .filter { $0.isFree }
            .map {
                $0.name
            }
    }

    @MainActor
    func handleError(_ error: Error) {
        if let dotcomError = error as? DotcomError,
            case let .unknown(_, message) = dotcomError {
            errorMessage = message
        } else {
            errorMessage = Localization.defaultErrorMessage
        }
        DDLogError("Cannot load domain suggestions for \(searchTerm): \(error)")
    }
}

private extension DomainSelectorViewModel {
    enum Constants {
        static let fieldDebounceDuration = 0.3
    }
}

extension DomainSelectorViewModel {
    enum Localization {
        static let defaultErrorMessage =
        NSLocalizedString("Please try another query.",
                          comment: "Default message when there is an unexpected error loading domain suggestions on the domain selector.")
    }
}
