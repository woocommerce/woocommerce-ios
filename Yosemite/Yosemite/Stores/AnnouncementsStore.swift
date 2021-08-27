import Networking
import WordPressKit
import Storage

/// Protocol for `AnnouncementsRemote` mainly used for mocking.
///
public protocol AnnouncementsRemoteProtocol {
    func getAnnouncements(appId: String,
                          appVersion: String,
                          locale: String,
                          completion: @escaping (Result<[Announcement], Error>) -> Void)
}

extension AnnouncementServiceRemote: AnnouncementsRemoteProtocol {
    public override convenience init() {
        self.init(wordPressComRestApi: WordPressComRestApi(baseUrlString: Settings.wordpressApiBaseURL))
    }
}

// MARK: - AnnouncementsStore
//
public class AnnouncementsStore: Store {

    private let remote: AnnouncementsRemoteProtocol
    private let fileStorage: FileStorage
    private let appVersion = UserAgent.bundleShortVersion

    public init(dispatcher: Dispatcher,
                storageManager: StorageManagerType,
                network: Network,
                remote: AnnouncementsRemoteProtocol = AnnouncementServiceRemote(),
                fileStorage: FileStorage) {
        self.remote = remote
        self.fileStorage = fileStorage
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

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

        case .loadSavedAnnouncement(let onCompletion):
            loadSavedAnnouncement(onCompletion: onCompletion)
        }
    }
}

private extension AnnouncementsStore {

    /// Get Announcements from Announcements API and persist this information on disk.
    func synchronizeAnnouncements(onCompletion: @escaping (Result<Announcement, Error>) -> Void) {

        remote.getAnnouncements(appId: Constants.WooCommerceAppId,
                                appVersion: appVersion,
                                locale: Locale.current.identifier) { [weak self] result in
            switch result {
            case .success(let announcements):
                guard let self = self, let announcement = announcements.first else {
                    return onCompletion(.failure(AnnouncementsError.announcementNotFound))
                }
                do {
                    try self.saveAnnouncement(announcement)
                    onCompletion(.success(announcement))
                } catch {
                    return onCompletion(.failure(error))
                }
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }

    /// Map `WordPressKit.Announcement` to `StorageAnnouncement` model
    func mapAnnouncementToStorageModel(_ announcement: Announcement) -> StorageAnnouncement {
        let mappedFeatures = announcement.features.map {
            StorageFeature(title: $0.title,
                           subtitle: $0.subtitle,
                           iconUrl: $0.iconUrl,
                           iconBase64: $0.iconBase64)
        }

        return StorageAnnouncement(appVersion: announcement.appVersionName,
                                   features: mappedFeatures,
                                   announcementVersion: announcement.announcementVersion,
                                   displayed: false)
    }

    /// Save the `Announcement` to the appropriate file.
    func saveAnnouncement(_ announcement: Announcement) throws {
        let mappedAnnouncement = self.mapAnnouncementToStorageModel(announcement)
        guard let fileURL = featureAnnouncementsFileURL else {
            throw AnnouncementsStorageError.unableToFindFileURL
        }
        try fileStorage.write(mappedAnnouncement, to: fileURL)
    }

    /// Load the latest saved `Announcement`. Returns an Error if there is no saved announcement.
    func loadSavedAnnouncement(onCompletion: (Result<Announcement, Error>) -> Void) {
        guard let fileURL = featureAnnouncementsFileURL else {
            return onCompletion(.failure(AnnouncementsStorageError.unableToFindFileURL))
        }
        do {
            onCompletion(.success(try fileStorage.data(for: fileURL)))
        } catch {
            onCompletion(.failure(AnnouncementsStorageError.noAnnouncementSaved))
        }
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

// MARK: - Errors
//
enum AnnouncementsStorageError: Error {
    case unableToFindFileURL
    case noAnnouncementSaved
}

enum AnnouncementsError: Error {
    case announcementNotFound
}
