import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// View model for `BlazeTargetTopicPickerView`
final class BlazeTargetTopicPickerViewModel {

    @Published var selectedTopics: Set<BlazeTargetTopic>?
    @Published private(set) var syncState = SyncState.syncing
    @Published private var topics: [BlazeTargetTopic] = []
    @Published private var isSyncingData: Bool = false
    @Published private var syncError: Error?

    var shouldDisableSaveButton: Bool {
        selectedTopics?.isEmpty == true || syncState == .error || syncState == .syncing
    }

    /// Blaze target device ResultsController.
    private lazy var resultsController: ResultsController<StorageBlazeTargetTopic> = {
        let predicate = NSPredicate(format: "locale == %@", locale.identifier)
        let sortDescriptorByID = NSSortDescriptor(keyPath: \StorageBlazeTargetTopic.id, ascending: true)
        let resultsController = ResultsController<StorageBlazeTargetTopic>(storageManager: storageManager,
                                                                           matching: predicate,
                                                                           sortedBy: [sortDescriptorByID])
        return resultsController
    }()

    private let siteID: Int64
    private let locale: Locale
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let onSelection: (Set<BlazeTargetTopic>?) -> Void

    init(siteID: Int64,
         selectedTopics: Set<BlazeTargetTopic>? = nil,
         locale: Locale = .current,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         onSelection: @escaping (Set<BlazeTargetTopic>?) -> Void) {
        self.siteID = siteID
        self.selectedTopics = selectedTopics
        self.locale = locale
        self.stores = stores
        self.storageManager = storageManager
        self.onSelection = onSelection

        configureResultsController()
        configureSyncState()
    }

    @MainActor
    func syncDevices() async {
        syncError = nil
        isSyncingData = true
        do {
            try await withCheckedThrowingContinuation { continuation in
                stores.dispatch(BlazeAction.synchronizeTargetDevices(siteID: siteID, locale: locale.identifier) { result in
                    switch result {
                    case .success:
                        continuation.resume(returning: Void())
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                })
            }
        } catch {
            DDLogError("⛔️ Error syncing Blaze target devices: \(error)")
            syncError = error
        }
        isSyncingData = false
    }

    func confirmSelection() {
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
        topics = resultsController.fetchedObjects
    }

    func configureSyncState() {
        $topics.combineLatest($isSyncingData, $syncError)
            .map { topics, isSyncing, error -> SyncState in
                if error != nil, topics.isEmpty {
                    return .error
                } else if isSyncing, topics.isEmpty {
                    return .syncing
                }
                return .result(items: topics)
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
