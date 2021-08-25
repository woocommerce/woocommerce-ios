import Networking
import Storage

/// Protocol for `AnnouncementsRemote` mainly used for mocking.
///
public protocol AnnouncementsRemoteProtocol {

    func getAnnouncement(appId: String,
                         appVersion: String,
                         locale: String,
                         completion: @escaping (Result<Announcement?, Error>) -> Void)
}

// MARK: - AnnouncementsStore
//
public class AnnouncementsStore: Store {

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

    private let appVersion = UserAgent.bundleShortVersion

    private lazy var featureAnnouncementsFileURL: URL? = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(Constants.featureAnnouncementsFileName)
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
        case .synchronizeAnnouncements(let onCompletion):
            synchronizeAnnouncements(onCompletion: onCompletion)
        }
    }
}

private extension AnnouncementsStore {

    /// Get Announcements from Announcements API and persist this information on disk.
    func synchronizeAnnouncements(onCompletion: @escaping (Announcement?) -> Void) {

        remote.getAnnouncement(appId: Constants.WooCommerceAppId,
                               appVersion: appVersion,
                               locale: Locale.current.identifier) { [weak self] result in
            switch result {
            case .success(let announcement):
                guard let announcement = announcement else {
                    onCompletion(nil)
                    return
                }
                try? self?.saveAnnouncement(announcement)
                onCompletion(announcement)
            case .failure:
                onCompletion(nil)
            }
        }
    }

    /// Load the latest saved `Announcement` for the current app version. Returns nil if there is no saved announcement.
    func loadSavedAnnouncement() -> Announcement? {
        guard let fileURL = featureAnnouncementsFileURL,
              let savedAnnouncement: Announcement = try? fileStorage.data(for: fileURL) else {
            return nil
        }

        return savedAnnouncement
    }

    /// Save the `Announcement` to the appropriate file.
    func saveAnnouncement(_ announcement: Announcement) throws {
        guard let fileURL = featureAnnouncementsFileURL else {
            throw StorageError.unableToFindFileURL
        }
        try fileStorage.write(announcement, to: fileURL)
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

// MARK: - I/O Errors
private enum StorageError: Error {
    case unableToFindFileURL
}
