import Foundation
import Yosemite
import protocol Storage.StorageManagerType
import protocol WooFoundation.Analytics

/// View model for `BlazeTargetTopicPickerView`
final class BlazeTargetTopicPickerViewModel: ObservableObject {

    @Published var selectedTopics: Set<BlazeTargetTopic>?
    @Published var searchQuery: String = ""
    @Published private(set) var syncState = SyncState.syncing
    @Published private var displayedTopics: [BlazeTargetTopic] = []
    @Published private var fetchedTopics: [BlazeTargetTopic] = []
    @Published private var isSyncingData: Bool = false
    @Published private var syncError: Error?

    var shouldDisableSaveButton: Bool {
        selectedTopics?.isEmpty == true || syncState == .error || syncState == .syncing
    }

    /// Blaze target device ResultsController.
    private lazy var resultsController: ResultsController<StorageBlazeTargetTopic> = {
        let predicate = NSPredicate(format: "locale == %@", locale.identifier)
        let sortDescriptorByID = NSSortDescriptor(keyPath: \StorageBlazeTargetTopic.name, ascending: true)
        let resultsController = ResultsController<StorageBlazeTargetTopic>(storageManager: storageManager,
                                                                           matching: predicate,
                                                                           sortedBy: [sortDescriptorByID])
        return resultsController
    }()

    private let siteID: Int64
    private let locale: Locale
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let analytics: Analytics
    private let onSelection: (Set<BlazeTargetTopic>?) -> Void

    init(siteID: Int64,
         selectedTopics: Set<BlazeTargetTopic>? = nil,
         locale: Locale = .current,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics,
         onSelection: @escaping (Set<BlazeTargetTopic>?) -> Void) {
        self.siteID = siteID
        self.selectedTopics = selectedTopics
        self.locale = locale
        self.stores = stores
        self.storageManager = storageManager
        self.analytics = analytics
        self.onSelection = onSelection

        configureResultsController()
        configureSyncState()
    }

    @MainActor
    func syncTopics() async {
        syncError = nil
        isSyncingData = true
        do {
            try await withCheckedThrowingContinuation { continuation in
                stores.dispatch(BlazeAction.synchronizeTargetTopics(siteID: siteID, locale: locale.identifier) { result in
                    switch result {
                    case .success:
                        continuation.resume(returning: Void())
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                })
            }
        } catch {
            DDLogError("⛔️ Error syncing Blaze target topics: \(error)")
            syncError = error
        }
        isSyncingData = false
    }

    func confirmSelection() {
        analytics.track(event: .Blaze.Interest.saveTapped())
        onSelection(selectedTopics)
    }
}

private extension BlazeTargetTopicPickerViewModel {
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
        fetchedTopics = resultsController.fetchedObjects
    }

    func configureSyncState() {
        $fetchedTopics.combineLatest($searchQuery, $isSyncingData, $syncError)
            .map { topics, query, isSyncing, error -> SyncState in
                if error != nil, topics.isEmpty {
                    return .error
                } else if isSyncing, topics.isEmpty {
                    return .syncing
                }
                let items: [BlazeTargetTopic] = {
                    guard query.isNotEmpty else {
                        return topics
                    }
                    return topics.filter { $0.name.lowercased().contains(query.lowercased()) }
                }()
                return .result(items: items)
            }
            .assign(to: &$syncState)
    }
}

extension BlazeTargetTopicPickerViewModel {
    enum SyncState: Equatable {
        case syncing
        case result(items: [BlazeTargetTopic])
        case error
    }
}
