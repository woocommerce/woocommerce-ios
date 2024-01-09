import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// View model for `BlazeTargetLanguagePickerView`
final class BlazeTargetLanguagePickerViewModel: ObservableObject {

    @Published var searchQuery: String = ""
    /// Languages to be displayed after filtering with `searchQuery` if available.
    @Published private(set) var languages: [BlazeTargetLanguage] = []
    @Published private var fetchedLanguages: [BlazeTargetLanguage] = []

    private let siteID: Int64
    private let locale: Locale
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let onSelection: (Set<BlazeTargetLanguage>?) -> Void

    /// Blaze target language ResultsController.
    private lazy var resultsController: ResultsController<StorageBlazeTargetLanguage> = {
        let sortDescriptorByID = NSSortDescriptor(keyPath: \StorageBlazeTargetLanguage.id, ascending: true)
        let resultsController = ResultsController<StorageBlazeTargetLanguage>(storageManager: storageManager,
                                                                              sortedBy: [sortDescriptorByID])
        return resultsController
    }()

    init(siteID: Int64,
         locale: Locale = .current,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         onSelection: @escaping (Set<BlazeTargetLanguage>?) -> Void) {
        self.siteID = siteID
        self.locale = locale
        self.stores = stores
        self.storageManager = storageManager
        self.onSelection = onSelection

        configureResultsController()
        configureDisplayedData()
    }

    @MainActor
    func syncLanguages() async {
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
        }
    }

    func confirmSelection(_ selectedLanguages: Set<BlazeTargetLanguage>?) {
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

    func configureDisplayedData() {
        $searchQuery.debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
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
