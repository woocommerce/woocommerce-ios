import Foundation
import Yosemite
import protocol Storage.StorageManagerType
import protocol WooFoundation.Analytics

/// View model for `BlazeTargetLanguagePickerView`
final class BlazeTargetLanguagePickerViewModel: ObservableObject {

    @Published var selectedLanguages: Set<BlazeTargetLanguage>?
    @Published var searchQuery: String = ""
    @Published private(set) var syncState = SyncState.syncing

    @Published private var fetchedLanguages: [BlazeTargetLanguage] = []

    @Published private var isSyncingData: Bool = false
    @Published private var syncError: Error?

    private let siteID: Int64
    private let locale: Locale
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let analytics: Analytics
    private let onSelection: (Set<BlazeTargetLanguage>?) -> Void

    var shouldDisableSaveButton: Bool {
        selectedLanguages?.isEmpty == true || syncState == .error || syncState == .syncing
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
         analytics: Analytics = ServiceLocator.analytics,
         onSelection: @escaping (Set<BlazeTargetLanguage>?) -> Void) {
        self.siteID = siteID
        self.selectedLanguages = selectedLanguages
        self.locale = locale
        self.stores = stores
        self.storageManager = storageManager
        self.analytics = analytics
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
        analytics.track(event: .Blaze.Language.saveTapped())
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
        $fetchedLanguages.combineLatest($isSyncingData, $syncError, $searchQuery)
            .map { languages, isSyncing, error, query -> SyncState in
                if error != nil, languages.isEmpty {
                    return .error
                } else if isSyncing, languages.isEmpty {
                    return .syncing
                }
                let items: [BlazeTargetLanguage] = {
                    guard query.isNotEmpty else {
                        return languages
                    }
                    return languages.filter { $0.name.lowercased().contains(query.lowercased()) }
                }()
                return .result(items: items)
            }
            .assign(to: &$syncState)
    }
}

extension BlazeTargetLanguagePickerViewModel {
    enum SyncState: Equatable {
        case syncing
        case result(items: [BlazeTargetLanguage])
        case error
    }
}
