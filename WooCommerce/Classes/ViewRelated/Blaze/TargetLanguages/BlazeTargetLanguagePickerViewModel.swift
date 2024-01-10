import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// View model for `BlazeTargetLanguagePickerView`
final class BlazeTargetLanguagePickerViewModel: ObservableObject {

    @Published var selectedLanguages: Set<BlazeTargetLanguage>?
    @Published var searchQuery: String = ""
    @Published private(set) var syncState = SyncState.syncing

    /// Languages to be displayed after filtering with `searchQuery` if available.
    @Published private var languages: [BlazeTargetLanguage] = []
    @Published private var fetchedLanguages: [BlazeTargetLanguage] = []

    @Published private var isSyncingData: Bool = false
    @Published private var syncError: Error?

    private let siteID: Int64
    private let locale: Locale
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let onSelection: (Set<BlazeTargetLanguage>?) -> Void

    var shouldDisableSaveButton: Bool {
        selectedLanguages?.isEmpty == true
    }

    /// Blaze target language ResultsController.
    private lazy var resultsController: ResultsController<StorageBlazeTargetLanguage> = {
        let predicate = NSPredicate(format: "locale == %@", locale.identifier)
        let sortDescriptorByID = NSSortDescriptor(keyPath: \StorageBlazeTargetLanguage.id, ascending: true)
        let resultsController = ResultsController<StorageBlazeTargetLanguage>(storageManager: storageManager,
                                                                              matching: predicate,
                                                                              sortedBy: [sortDescriptorByID])
        return resultsController
    }()

    init(siteID: Int64,
         selectedLanguages: Set<BlazeTargetLanguage>? = nil,
         locale: Locale = .current,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         onSelection: @escaping (Set<BlazeTargetLanguage>?) -> Void) {
        self.siteID = siteID
        self.selectedLanguages = selectedLanguages
        self.locale = locale
        self.stores = stores
        self.storageManager = storageManager
        self.onSelection = onSelection

        configureResultsController()
        configureDisplayedData()
    }

    @MainActor
    func syncLanguages() async {
        syncError = nil
        isSyncingData = true
        do {
            try await withCheckedThrowingContinuation { continuation in
                stores.dispatch(BlazeAction.synchronizeTargetLanguages(siteID: siteID, locale: locale.identifier) { result in
                    switch result {
                    case .success:
                        continuation.resume(returning: Void())
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                })
            }
        } catch {
            DDLogError("⛔️ Error syncing Blaze target languages: \(error)")
            syncError = error
        }
        isSyncingData = false
    }

    func confirmSelection() {
        onSelection(selectedLanguages)
    }
}

private extension BlazeTargetLanguagePickerViewModel {
    /// Performs initial fetch from storage and updates results.
    func configureResultsController() {
        resultsController.onDidChangeContent = { [weak self] in
            self?.updateResults()
        }
        resultsController.onDidResetContent = { [weak self] in
            self?.updateResults()
        }

        do {
            try resultsController.performFetch()
            updateResults()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    func updateResults() {
        fetchedLanguages = resultsController.fetchedObjects
    }

    /// Observes changes in the search query and filter the fetched results for display.
    /// The debounce in search query messes with the initial state, so we ignore the initial query
    /// and display the first fetch result immediately.
    ///
    func configureDisplayedData() {
        $languages.combineLatest($isSyncingData, $syncError)
            .map { devices, isSyncing, error -> SyncState in
                if error != nil, devices.isEmpty {
                    return .error
                } else if isSyncing, devices.isEmpty {
                    return .syncing
                }
                return .result(items: devices)
            }
            .assign(to: &$syncState)

        $fetchedLanguages
            .prefix(1) // first fetch result is displayed immediately, ignoring the empty search query
            .assign(to: &$languages)

        $searchQuery
            .dropFirst() // ignores initial value
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .combineLatest($fetchedLanguages)
            .map { query, languages in
                guard query.isNotEmpty else {
                    return languages
                }
                return languages.filter { $0.name.lowercased().contains(query.lowercased()) }
            }
            .assign(to: &$languages)
    }
}

extension BlazeTargetLanguagePickerViewModel {
    enum SyncState: Equatable {
        case syncing
        case result(items: [BlazeTargetLanguage])
        case error
    }
}
