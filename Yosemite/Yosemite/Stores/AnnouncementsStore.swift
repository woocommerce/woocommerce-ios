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

    public init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network, remote: AnnouncementsRemoteProtocol) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

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

    func synchronizeFeatures(onCompletion: @escaping ([Feature]) -> Void) {

        guard let languageCode = Locale.current.languageCode else {
            onCompletion([])
            return
        }

        remote.getAnnouncements(appId: "4",
                                 appVersion: UserAgent.bundleShortVersion,
                                 locale: languageCode) { result in
            switch result {
            case .success(let announcements):
                onCompletion(announcements.first?.features ?? [])
                // TODO: - Persist Features
            case .failure(let error):
                // Do nothing
                print(error)
            }
        }
    }
}
