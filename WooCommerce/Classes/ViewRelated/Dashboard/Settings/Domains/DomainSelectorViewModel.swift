import Combine
import SwiftUI
import Yosemite
import enum Networking.DotcomError

/// Properties that are necessary for displaying a domain suggestion in the UI.
protocol DomainSuggestionViewProperties {
    /// Domain name.
    var name: String { get }
    /// Optional attributed detail, e.g. price info for paid domains.
    var attributedDetail: AttributedString? { get }
}

/// View model for `DomainSelectorView`.
final class DomainSelectorViewModel<DataProvider: DomainSelectorDataProvider,
                                    DomainSuggestion: Equatable & DomainSuggestionViewProperties>: ObservableObject
where DataProvider.DomainSuggestion == DomainSuggestion {
    /// The state of the main view below the fixed header.
    enum ViewState: Equatable {
        /// When loading domain suggestions.
        case loading
        /// Shown when the search query is empty.
        case placeholder
        /// When there is an error loading domain suggestions.
        case error(message: String)
        /// When domain suggestions are displayed.
        case results(domains: [DomainSuggestion])
    }

    /// Current search term entered by the user.
    /// Each update will trigger a remote call for domain suggestions.
    @Published var searchTerm: String = ""

    /// Domain names after domain suggestions are loaded remotely.
    @Published private var domains: [DomainSuggestion] = []

    /// Error message from loading domain suggestions.
    @Published private var errorMessage: String?

    /// Whether domain suggestions are being loaded.
    @Published private(set) var isLoadingDomainSuggestions: Bool = false

    /// The state of the main domain selector view based on the search query and loading state.
    @Published private(set) var state: ViewState = .placeholder

    /// Subscription for search query changes for domain search.
    private var searchQuerySubscription: AnyCancellable?

    private let dataProvider: DataProvider
    private let debounceDuration: Double

    init(initialSearchTerm: String = "",
         dataProvider: DataProvider,
         debounceDuration: Double = Constants.fieldDebounceDuration) {
        self.dataProvider = dataProvider
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
        let searchQuery = $searchTerm
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isNotEmpty }
            .removeDuplicates()
        // In order to always trigger a network request for the initial search query while supporting debounce
        // for the following user input, the first search query is concatenated with the debounce version.
        searchQuerySubscription = Publishers.Concatenate(
            prefix: searchQuery.first(),
            suffix: searchQuery
                .debounce(for: .seconds(debounceDuration), scheduler: DispatchQueue.main)
        )
            .removeDuplicates()
            .eraseToAnyPublisher()
            .sink { [weak self] searchTerm in
                guard let self = self else { return }
                Task { @MainActor in
                    self.errorMessage = nil
                    self.isLoadingDomainSuggestions = true

                    do {
                        self.domains = try await self.loadDomainSuggestions(query: searchTerm)
                        self.isLoadingDomainSuggestions = false
                    } catch {
                        self.isLoadingDomainSuggestions = false
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
    func loadDomainSuggestions(query: String) async throws -> [DomainSuggestion] {
        try await dataProvider.loadDomainSuggestions(query: query)
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
        static var fieldDebounceDuration: Double {
            0.3
        }
    }
}

extension DomainSelectorViewModel {
    enum Localization {
        static var defaultErrorMessage: String {
            NSLocalizedString("Please try another query.",
                              comment: "Default message when there is an unexpected error loading domain suggestions on the domain selector.")
        }
    }
}
