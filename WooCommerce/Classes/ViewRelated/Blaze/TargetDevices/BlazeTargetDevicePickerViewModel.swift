import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// View model for `BlazeTargetDevicePicker`
final class BlazeTargetDevicePickerViewModel: ObservableObject {

    @Published private(set) var syncState = SyncState.syncing
    @Published private var devices: [BlazeTargetDevice] = []
    @Published private var isSyncingData: Bool = false
    @Published private var syncError: Error?

    /// Blaze target device ResultsController.
    private lazy var resultsController: ResultsController<StorageBlazeTargetDevice> = {
        let predicate = NSPredicate(format: "locale == %@", locale.identifier)
        let sortDescriptorByID = NSSortDescriptor(keyPath: \StorageBlazeTargetDevice.id, ascending: true)
        let resultsController = ResultsController<StorageBlazeTargetDevice>(storageManager: storageManager,
                                                                            matching: predicate,
                                                                            sortedBy: [sortDescriptorByID])
        return resultsController
    }()

    private let siteID: Int64
    private let locale: Locale
    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let onSelection: (Set<BlazeTargetDevice>?) -> Void

    init(siteID: Int64,
         locale: Locale = .current,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         onSelection: @escaping (Set<BlazeTargetDevice>?) -> Void) {
        self.siteID = siteID
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

    func confirmSelection(_ selectedDevices: Set<BlazeTargetDevice>?) {
        onSelection(selectedDevices)
    }
}

private extension BlazeTargetDevicePickerViewModel {
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
        devices = resultsController.fetchedObjects
    }

    func configureSyncState() {
        $devices.combineLatest($isSyncingData, $syncError)
            .map { devices, isSyncing, error -> SyncState in
                if error != nil {
                    return .error
                } else if isSyncing, devices.isEmpty {
                    return .syncing
                }
                return .result(items: devices)
            }
            .assign(to: &$syncState)
    }
}

extension BlazeTargetDevicePickerViewModel {
    enum SyncState {
        case syncing
        case result(items: [BlazeTargetDevice])
        case error
    }
}
