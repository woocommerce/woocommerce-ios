import Networking
import Storage
import WordPressKit

/// Protocol for `AnnouncementsRemote` mainly used for mocking.
///
protocol AnnouncementsRemoteProtocol {

    func getAnnouncements(appId: String,
                          appVersion: String,
                          locale: String,
                          completion: @escaping (Result<[Announcement], Error>) -> Void)
}

// MARK: - AnnouncementsStore
//
class AnnouncementsStore: Store {

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

    private var appVersion: String { UserAgent.bundleShortVersion }

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

    func synchronizeFeatures(onCompletion: @escaping ([Feature]) -> Void) {
        guard let languageCode = Locale.current.languageCode else {
            onCompletion([])
            return
        }

        if let savedFeatures = loadSavedAnnouncements().first?.features {
            onCompletion(savedFeatures)
            return
        }

        remote.getAnnouncements(appId: "4",
                                appVersion: appVersion,
                                locale: languageCode) { [weak self] result in
            switch result {
            case .success(let announcements):
                try? self?.saveAnnouncements(announcements)
                onCompletion(announcements.first?.features ?? [])
            case .failure:
                onCompletion([])
            }
        }
    }

    /// Load `Announcements` for the current app version
    func loadSavedAnnouncements() -> [Announcement] {
        guard let savedAnnouncements: [String: [Announcement]] = try? fileStorage.data(for: featureAnnouncementsFileURL) else {
            return []
        }

        return savedAnnouncements[appVersion] ?? []
    }

    /// Save the `Announcements` to the appropriate file.
    func saveAnnouncements(_ announcements: [Announcement]) throws {
        try fileStorage.write([appVersion: announcements], to: featureAnnouncementsFileURL)
    }
}

// MARK: - Constants
//
private enum Constants {

    // MARK: File Names
    static let featureAnnouncementsFileName = "feature-announcements.plist"
}
