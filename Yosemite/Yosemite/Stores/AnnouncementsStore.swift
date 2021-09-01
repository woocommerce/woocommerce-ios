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

public typealias IsDisplayed = Bool

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

    private lazy var storageAnnouncement: StorageAnnouncement? = {
        guard let fileUrl = featureAnnouncementsFileURL else { return nil }
        return try? fileStorage.data(for: fileUrl)
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

        case .markSavedAnnouncementAsDisplayed(let onCompletion):
            markSavedAnnouncementAsDisplayed(onCompletion: onCompletion)
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
                    try self.saveAnnouncementIfNeeded(announcement)
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
    func mapAnnouncementToStorageModel(_ announcement: Announcement, displayed: Bool = false) -> StorageAnnouncement {
        let mappedFeatures = announcement.features.map {
            StorageFeature(title: $0.title,
                           subtitle: $0.subtitle,
                           iconUrl: $0.iconUrl,
                           iconBase64: $0.iconBase64)
        }

        return StorageAnnouncement(appVersionName: announcement.appVersionName,
                                   minimumAppVersion: announcement.minimumAppVersion,
                                   maximumAppVersion: announcement.maximumAppVersion,
                                   appVersionTargets: announcement.appVersionTargets,
                                   detailsUrl: announcement.detailsUrl,
                                   announcementVersion: announcement.announcementVersion,
                                   isLocalized: announcement.isLocalized,
                                   responseLocale: announcement.responseLocale,
                                   features: mappedFeatures,
                                   displayed: displayed)
    }

    /// Save the `Announcement` on disk if it's a new or a different announcement comparing to the existing one
    func saveAnnouncementIfNeeded(_ announcement: Announcement) throws {
        if let storageAnnouncement = storageAnnouncement {
            guard !announcement.isSameVersion(storageAnnouncement) else {
                throw AnnouncementsStorageError.announcementAlreadyExists
            }
        }

        guard let fileURL = featureAnnouncementsFileURL else { throw AnnouncementsStorageError.unableToFindFileURL }
        let mappedAnnouncement = self.mapAnnouncementToStorageModel(announcement)
        try fileStorage.write(mappedAnnouncement, to: fileURL)
    }

    /// Load the latest saved `Announcement`. Returns an Error if there is no saved announcement.
    func loadSavedAnnouncement(onCompletion: (Result<(Announcement, IsDisplayed), Error>) -> Void) {
        do {
            onCompletion(.success((try savedAnnouncement(), storageAnnouncement?.displayed == true)))
        } catch {
            onCompletion(.failure(AnnouncementsStorageError.noAnnouncementSaved))
        }
    }

    func markSavedAnnouncementAsDisplayed(onCompletion: (Result<Void, Error>) -> Void) {
        guard let fileURL = featureAnnouncementsFileURL else {
            return onCompletion(.failure(AnnouncementsStorageError.unableToFindFileURL))
        }

        do {
            let savedAnnouncement = try savedAnnouncement()
            let mappedAnnouncement = self.mapAnnouncementToStorageModel(savedAnnouncement, displayed: true)
            try fileStorage.write(mappedAnnouncement, to: fileURL)
            onCompletion(.success(()))
        }
        catch {
            onCompletion(.failure(AnnouncementsStorageError.noAnnouncementSaved))
        }
    }

    func savedAnnouncement() throws -> Announcement {
        guard let fileURL = featureAnnouncementsFileURL else { throw AnnouncementsStorageError.unableToFindFileURL }
        do {
            let savedModel: StorageAnnouncement = try fileStorage.data(for: fileURL)
            let encodedObject = try JSONEncoder().encode(savedModel)
            return try JSONDecoder().decode(Announcement.self, from: encodedObject)
        } catch {
            throw AnnouncementsStorageError.noAnnouncementSaved
        }
    }
}

// MARK: - Announcement Extension
private extension Announcement {
    func isSameVersion(_ announcement: StorageAnnouncement) -> Bool {
        appVersionName == announcement.appVersionName && announcementVersion == announcement.announcementVersion
    }
}

// MARK: - Constants
private enum Constants {
    // MARK: File Names
    static let featureAnnouncementsFileName = "feature-announcements.plist"

    // MARK: - App IDs
    static let WooCommerceAppId = "4"
}

// MARK: - Errors
enum AnnouncementsStorageError: Error {
    case unableToFindFileURL
    case noAnnouncementSaved
    case announcementAlreadyExists
}

enum AnnouncementsError: Error {
    case announcementNotFound
}
