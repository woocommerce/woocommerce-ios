import Networking
import WordPressKit
import Storage

/// Protocol for `AnnouncementsRemote` mainly used for mocking.
///
public protocol AnnouncementsRemoteProtocol {
    func getAnnouncements(appId: String,
                          appVersion: String,
                          locale: String,
                          completion: @escaping (Result<[WordPressKit.Announcement], Error>) -> Void)
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

    public init(dispatcher: Dispatcher,
                storageManager: StorageManagerType,
                network: Network,
                remote: AnnouncementsRemoteProtocol = AnnouncementServiceRemote(),
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
    func synchronizeAnnouncements(onCompletion: @escaping (Result<StorageAnnouncement, Error>) -> Void) {

        remote.getAnnouncements(appId: Constants.WooCommerceAppId,
                                appVersion: appVersion,
                                locale: Locale.current.identifier) { [weak self] result in
            switch result {
            case .success(let announcements):
                guard let self = self, let announcement = announcements.first else {
                    return onCompletion(.failure(AnnouncementsError.unableToGetAnnouncement))
                }
                do {
                    let mappedAnnouncement = self.mapAnnouncementToStorageModel(announcement)
                    try self.saveAnnouncement(mappedAnnouncement)
                    onCompletion(.success(mappedAnnouncement))
                } catch {
                    return onCompletion(.failure(error))
                }
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }

    func mapAnnouncementToStorageModel(_ announcement: WordPressKit.Announcement) -> StorageAnnouncement {
        let mappedFeatures = announcement.features.map {
            Feature(title: $0.title,
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
    func saveAnnouncement(_ announcement: StorageAnnouncement) throws {
        guard let fileURL = featureAnnouncementsFileURL else {
            throw AnnouncementsStorageError.unableToFindFileURL
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

// MARK: - Errors
//
enum AnnouncementsStorageError: Error {
    case unableToFindFileURL
}

enum AnnouncementsError: Error {
    case unableToGetAnnouncement
}
