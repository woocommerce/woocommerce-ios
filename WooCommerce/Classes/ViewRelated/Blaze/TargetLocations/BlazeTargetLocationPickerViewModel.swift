import Foundation
import Yosemite
import protocol WooFoundation.Analytics

/// View model for `BlazeTargetLocationPickerView`
final class BlazeTargetLocationPickerViewModel: ObservableObject {

    @Published var selectedLocations: Set<BlazeTargetLocation>?
    @Published var searchQuery: String = ""

    @Published private(set) var fetchInProgress = false
    @Published private(set) var searchResults: [BlazeTargetLocation] = []
    @Published private(set) var selectedSearchResults: [BlazeTargetLocation] = []

    var shouldDisableSaveButton: Bool {
        selectedLocations?.isEmpty == true
    }

    var emptyViewImage: UIImage {
        if searchQuery.count < Constants.minimumQueryLength {
            .searchImage
        } else {
            .searchNoResultImage
        }
    }

    var emptyViewMessage: String {
        if searchQuery.isEmpty {
            Localization.searchViewHintMessage
        } else if searchQuery.count < Constants.minimumQueryLength {
            Localization.longerQuery
        } else {
            Localization.noResult
        }
    }

    private let siteID: Int64
    private let locale: Locale
    private let stores: StoresManager
    private let analytics: Analytics
    private let onCompletion: (Set<BlazeTargetLocation>?) -> Void

    init(siteID: Int64,
         locale: Locale = .current,
         selectedLocations: Set<BlazeTargetLocation>? = nil,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         onCompletion: @escaping (Set<BlazeTargetLocation>?) -> Void) {
        self.selectedLocations = selectedLocations
        self.siteID = siteID
        self.locale = locale
        self.stores = stores
        self.analytics = analytics
        self.onCompletion = onCompletion

        // Updates `selectedSearchResults` to display the selected locations on the specific location section.
        if let selectedLocations {
            self.selectedSearchResults = Array(selectedLocations)
        }

        observeSearchQuery()
    }

    func addOptionFromSearchResult(_ item: BlazeTargetLocation) {
        var optionSet = Set(selectedSearchResults)
        optionSet.insert(item)
        selectedSearchResults = Array(optionSet)

        // adds the new item to the selected list
        var selectedItems = selectedLocations ?? []
        selectedItems.insert(item)
        selectedLocations = selectedItems

        // clears search result
        searchResults = []
    }

    func confirmSelection() {
        analytics.track(event: .Blaze.Location.saveTapped())
        onCompletion(selectedLocations)
    }
}

private extension BlazeTargetLocationPickerViewModel {
    func observeSearchQuery() {
        $searchQuery
            .filter { $0.count < Constants.minimumQueryLength }
            .map { _ -> [BlazeTargetLocation] in [] } // clears search result if search query is not long enough
            .assign(to: &$searchResults)

        $searchQuery
            .filter { $0.count >= Constants.minimumQueryLength }
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.fetchInProgress = true
            })
            .asyncMap { [weak self] query -> [BlazeTargetLocation] in
                guard let self else {
                    return []
                }
                return await self.searchLocation(query: query)
            }
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.fetchInProgress = false
            })
            .assign(to: &$searchResults)
    }

    @MainActor
    func searchLocation(query: String) async -> [BlazeTargetLocation] {
        await withCheckedContinuation { continuation in
            stores.dispatch(BlazeAction.fetchTargetLocations(siteID: siteID, query: searchQuery, locale: locale.identifier) { result in
                switch result {
                case .success(let locations):
                    continuation.resume(returning: locations)
                case .failure(let error):
                    DDLogError("⛔️ Error searching target location for Blaze: \(error)")
                    continuation.resume(returning: [])
                }
            })
        }
    }
}

extension BlazeTargetLocationPickerViewModel {

    enum Constants {
        static let minimumQueryLength = 3
    }

    enum Localization {
        static let searchViewHintMessage = NSLocalizedString(
            "blazeTargetLocationPickerViewModel.searchViewHintMessage",
            value: "Start typing country, state or city to see available options",
            comment: "Hint message to enter search query on the target location picker for campaign creation"
        )
        static let longerQuery = NSLocalizedString(
            "blazeTargetLocationPickerViewModel.longerQuery",
            value: "Please enter at least 3 characters to start searching.",
            comment: "Message indicating the minimum length for search queries on the target location picker for campaign creation"
        )
        static let noResult = NSLocalizedString(
            "blazeTargetLocationPickerViewModel.noResult",
            value: "No location found.\nPlease try again.",
            comment: "Message indicating no search result on the target location picker for campaign creation"
        )
    }
}
