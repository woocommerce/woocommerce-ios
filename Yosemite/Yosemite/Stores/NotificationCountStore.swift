import Storage
import Networking

// MARK: - NotificationCountStore
//
public final class NotificationCountStore: Store {
    /// Loads a plist file at a given URL
    ///
    private let fileStorage: FileStorage

    /// Designated initaliser
    ///
    public init(dispatcher: Dispatcher,
                storageManager: StorageManagerType,
                fileStorage: FileStorage) {
        self.fileStorage = fileStorage
        super.init(dispatcher: dispatcher,
                   storageManager: storageManager,
                   network: NullNetwork())
    }

    /// URL to the plist file that we use to determine the notification count.
    ///
    private lazy var fileURL: URL = {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            logErrorAndExit("Cannot find app document directory URL")
        }
        return documents.appendingPathComponent(Constants.notificationCountFileName)
    }()

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: NotificationCountAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? NotificationCountAction else {
            assertionFailure("NotificationCountStore received an unsupported action")
            return
        }

        switch action {
        case .increment(let siteID, let type, let incrementCount, let onCompletion):
            incrementNotificationCount(siteID: siteID, type: type, incrementCount: incrementCount, onCompletion: onCompletion)
        case .load(let siteID, let type, let onCompletion):
            loadNotificationCount(siteID: siteID, type: type, onCompletion: onCompletion)
        case .reset(let siteID, let type, let onCompletion):
            resetNotificationCount(siteID: siteID, type: type, onCompletion: onCompletion)
        case .resetForAllSites(let onCompletion):
            resetNotificationCountForAllSites(onCompletion: onCompletion)
        }
    }
}


private extension NotificationCountStore {
    func incrementNotificationCount(siteID: Int64, type: Note.Kind, incrementCount: Int, onCompletion: () -> Void) {
        guard let existingData = readContents() else {
            let notificationTypeBySite: SiteNotificationCountFileContents = SiteNotificationCountFileContents(countBySite: [siteID: [type: incrementCount]])
            writeContents(notificationTypeBySite)
            onCompletion()
            return
        }

        let data = existingData.incrementing(siteID: siteID, type: type, incrementCount: incrementCount)
        writeContents(data)
        onCompletion()
    }

    func loadNotificationCount(siteID: Int64, type: SiteNotificationCountType, onCompletion: (_ count: Int) -> Void) {
        guard let existingData = readContents() else {
            onCompletion(0)
            return
        }
        onCompletion(existingData.notificationCount(siteID: siteID, type: type))
    }

    func resetNotificationCount(siteID: Int64, type: Note.Kind, onCompletion: () -> Void) {
        guard let existingData = readContents() else {
            onCompletion()
            return
        }

        let data = existingData.resetting(siteID: siteID, type: type)
        writeContents(data)
        onCompletion()
    }

    func resetNotificationCountForAllSites(onCompletion: () -> Void) {
        do {
            try fileStorage.deleteFile(at: fileURL)
            onCompletion()
        } catch {
            DDLogError("⛔️ Deleting the notification count file failed. Error: \(error)")
            onCompletion()
        }
    }
}

private extension NotificationCountStore {
    func readContents() -> SiteNotificationCountFileContents? {
        guard let existingData: SiteNotificationCountFileContents = try? fileStorage.data(for: fileURL) else {
            return nil
        }
        return existingData
    }

    func writeContents(_ data: SiteNotificationCountFileContents) {
        try? fileStorage.write(data, to: fileURL)
    }
}

// MARK: - Constants

/// Constants
///
private enum Constants {
    static let notificationCountFileName = "notification-count.plist"
}
