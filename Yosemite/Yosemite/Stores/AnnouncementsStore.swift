import Networking
import Storage

/// Protocol for `AnnouncementsRemote` mainly used for mocking.
///
public protocol AnnouncementsRemoteProtocol {

    func getFeatures(appId: String,
                     appVersion: String,
                     locale: String,
                     completion: @escaping (Result<[WooCommerceFeature], Error>) -> Void)
}

// MARK: - AnnouncementsStore
//
public class AnnouncementsStore: Store {

    typealias IsCached = Bool
    typealias AppVersion = String
    private let remote: AnnouncementsRemoteProtocol
    private let fileStorage: FileStorage

    public init(dispatcher: Dispatcher,
                storageManager: StorageManagerType,
                network: Network,
                remote: AnnouncementsRemoteProtocol,
                fileStorage: FileStorage) {
        self.remote = remote
        self.fileStorage = fileStorage
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    private var appVersion: AppVersion { UserAgent.bundleShortVersion }

    private lazy var featureAnnouncementsFileURL: URL! = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documents!.appendingPathComponent(Constants.featureAnnouncementsFileName)
    }()

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: AnnouncementsAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? AnnouncementsAction else {
            assertionFailure("AnnouncementsStore received an unsupported action")
            return
        }

        switch action {
        case .synchronizeFeatures(let onCompletion):
            synchronizeFeatures(onCompletion: onCompletion)
        }
    }
}

private extension AnnouncementsStore {

    /// Get features from Announcements API and persist this information. If there are saved features for a given app version, load it from disk.
    func synchronizeFeatures(onCompletion: @escaping ([WooCommerceFeature], IsCached) -> Void) {
        let savedFeatures = loadSavedFeatures()
        if !savedFeatures.isEmpty {
            onCompletion(savedFeatures, true)
            return
        }

        remote.getFeatures(appId: Constants.WooCommerceAppId,
                           appVersion: appVersion,
                           locale: Locale.current.identifier) { [weak self] result in
            switch result {
            case .success(let features):
                try? self?.saveFeatures(features)
                onCompletion(features, false)
            case .failure:
                onCompletion([], false)
            }
        }
    }

    /// Load a saved list of`WooCommerceFeature` for the current app version. Return an empty array if there are no saved features.
    func loadSavedFeatures() -> [WooCommerceFeature] {
        guard let savedFeatures: [AppVersion: [WooCommerceFeature]] = try? fileStorage.data(for: featureAnnouncementsFileURL) else {
            return []
        }

        return savedFeatures[appVersion] ?? []
    }

    /// Save the `WooCommerceFeature`(s) to the appropriate file.
    func saveFeatures(_ features: [WooCommerceFeature]) throws {
        try fileStorage.write([appVersion: features], to: featureAnnouncementsFileURL)
    }
}

// MARK: - Constants
//
private enum Constants {

    // MARK: File Names
    static let featureAnnouncementsFileName = "feature-announcements.plist"

    // MARK: - App IDs
    static let WooCommerceAppId = "4"
}
