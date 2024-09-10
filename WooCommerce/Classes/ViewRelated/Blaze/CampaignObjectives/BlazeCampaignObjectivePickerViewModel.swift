import Foundation
import Yosemite
import protocol Storage.StorageManagerType
import protocol WooFoundation.Analytics

/// View model for `BlazeCampaignObjectivePickerView`
///
final class BlazeCampaignObjectivePickerViewModel: ObservableObject {

    @Published var selectedObjective: BlazeCampaignObjective?
    @Published var saveSelectionForFutureCampaigns = true

    @Published private(set) var fetchedData: [BlazeCampaignObjective] = []
    @Published private(set) var isSyncingData: Bool = false
    @Published private(set) var syncError: Error?

    var shouldDisableSaveButton: Bool {
        selectedObjective == nil || isSyncingData || syncError != nil
    }

    /// Blaze target device ResultsController.
    private lazy var resultsController: ResultsController<StorageBlazeCampaignObjective> = {
        let predicate = NSPredicate(format: "locale == %@", locale.identifier)
        let sortDescriptorByID = NSSortDescriptor(keyPath: \StorageBlazeCampaignObjective.title, ascending: true)
        let resultsController = ResultsController<StorageBlazeCampaignObjective>(storageManager: storageManager,
                                                                                 matching: predicate,
                                                                                 sortedBy: [sortDescriptorByID])
        return resultsController
    }()

    private let siteID: Int64
    private let locale: Locale
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let analytics: Analytics
    private let onSelection: (BlazeCampaignObjective?) -> Void

    init(siteID: Int64,
         selectedObjective: BlazeCampaignObjective? = nil,
         locale: Locale = .current,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics,
         onSelection: @escaping (BlazeCampaignObjective?) -> Void) {
        self.siteID = siteID
        self.selectedObjective = selectedObjective
        self.locale = locale
        self.stores = stores
        self.storageManager = storageManager
        self.analytics = analytics
        self.onSelection = onSelection

        configureResultsController()
    }

    @MainActor
    func syncData() async {
        syncError = nil
        isSyncingData = true
        do {
            try await withCheckedThrowingContinuation { continuation in
                stores.dispatch(BlazeAction.synchronizeCampaignObjectives(siteID: siteID, locale: locale.identifier) { result in
                    switch result {
                    case .success:
                        continuation.resume(returning: Void())
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                })
            }
        } catch {
            DDLogError("⛔️ Error syncing Blaze campaign objective: \(error)")
            syncError = error
        }
        isSyncingData = false
    }

    func confirmSelection() {
        // TODO: add tracking
        onSelection(selectedObjective)
    }
}

private extension BlazeCampaignObjectivePickerViewModel {
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
        fetchedData = resultsController.fetchedObjects
    }
}
