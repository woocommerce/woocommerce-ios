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
    @Published private(set) var domains: [String] = []

    /// Error message from loading domain suggestions.
    @Published private(set) var errorMessage: String?

    /// Error message from loading domain suggestions.
    @Published private(set) var isLoadingDomainSuggestions: Bool = false

    /// Placeholder image is set when the search term is empty. Otherwise, the placeholder image is `nil`.
    @Published private(set) var placeholderImage: UIImage?

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
        // and thus the initial value isn't emitted in `observeDomainQuery`.
        observeDomainQuery()
        self.searchTerm = initialSearchTerm
    }
}

private extension DomainSelectorViewModel {
    func observeDomainQuery() {
        let searchTermPublisher = $searchTerm
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .debounce(for: .seconds(debounceDuration), scheduler: DispatchQueue.main)
            .share()

        searchQuerySubscription = searchTermPublisher
            .filter { $0.isNotEmpty }
            .removeDuplicates()
            .sink { [weak self] searchTerm in
                guard let self = self else { return }
                Task { @MainActor in
                    self.errorMessage = nil
                    self.placeholderImage = nil
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

        searchTermPublisher
            .map {
                $0.isEmpty ? UIImage.domainSearchPlaceholderImage: nil
            }
            .assign(to: &$placeholderImage)
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
