import Foundation
import Yosemite

/// View model for `BlazeTargetLocationPickerView`
final class BlazeTargetLocationPickerViewModel: ObservableObject {

    @Published var selectedLocations: Set<BlazeTargetLocation>?
    @Published var searchQuery: String = ""

    @Published private(set) var isSearching = false
    @Published private(set) var searchResults: [BlazeTargetLocation] = []

    var shouldDisableSaveButton: Bool {
        selectedLocations?.isEmpty == true
    }

    private let siteID: Int64
    private let locale: Locale
    private let stores: StoresManager
    private let onCompletion: (Set<BlazeTargetLocation>?) -> Void

    init(siteID: Int64,
         locale: Locale = .current,
         selectedLocations: Set<BlazeTargetLocation>? = nil,
         stores: StoresManager = ServiceLocator.stores,
         onCompletion: @escaping (Set<BlazeTargetLocation>?) -> Void) {
        self.selectedLocations = selectedLocations
        self.siteID = siteID
        self.locale = locale
        self.stores = stores
        self.onCompletion = onCompletion

        observeSearchQuery()
    }

    func selectItem(_ item: BlazeTargetLocation) {
        var items = selectedLocations ?? .init()
        items.insert(item)
        selectedLocations = items
    }

    func confirmSelection() {
        // TODO
    }
}

private extension BlazeTargetLocationPickerViewModel {
    func observeSearchQuery() {
        $searchQuery
            .filter { $0.count >= 3 }
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.isSearching = true
            })
            .asyncMap { [weak self] query -> [BlazeTargetLocation] in
                guard let self else {
                    return []
                }
                return await self.searchLocation(query: query)
            }
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.isSearching = false
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
