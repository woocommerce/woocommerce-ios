import Foundation
import Storage
import Networking
import WooFoundation

// MARK: - JustInTimeMessageStore
//
public class JustInTimeMessageStore: Store {
    private let remote: JustInTimeMessagesRemoteProtocol

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = JustInTimeMessagesRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: JustInTimeMessageAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? JustInTimeMessageAction else {
            assertionFailure("JustInTimeMessageStore received an unsupported action")
            return
        }


        switch action {
        case .loadMessage(let siteID, let screen, let hook, let completion):
            loadMessage(for: siteID, screen: screen, hook: hook, completion: completion)
        case .dismissMessage(let message, let siteID, let completion):
            dismissMessage(message, for: siteID, completion: completion)
        }
    }
}

// MARK: - Services
//
private extension JustInTimeMessageStore {
    /// Retrieves the top `JustInTimeMessage` from the API for a given screen and hook
    ///
    func loadMessage(for siteID: Int64,
                     screen: String,
                     hook: JustInTimeMessageHook,
                     completion: @escaping (Result<[JustInTimeMessage], Error>) -> ()) {
        Task {
            let result = await Result {
                let messages = try await remote.loadAllJustInTimeMessages(
                        for: siteID,
                        messagePath: .init(app: .wooMobile,
                                           screen: screen,
                                           hook: hook),
                        query: justInTimeMessageQuery(),
                        locale: localeLanguageRegionIdentifier())

                return displayMessages(messages)
            }

            await MainActor.run {
                completion(result)
            }
        }
    }

    func justInTimeMessageQuery() -> [String: String] {
        var queryItems = [
            "platform": "ios",
            "version": Bundle.main.marketingVersion
        ]

        if let device = deviceIdiomName() {
            queryItems["device"] = device
        }

        if let buildType = buildType() {
            queryItems["build_type"] = buildType
        }

        return queryItems
    }

    func deviceIdiomName() -> String? {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return "phone"
        case .pad:
            return "pad"
        default:
            return nil
        }
    }

    func buildType() -> String? {
        #if DEBUG || ALPHA
        return "developer"
        #else
        return nil
        #endif
    }

    func localeLanguageRegionIdentifier() -> String? {
        guard let languageCode = Locale.current.languageCode else {
            return nil
        }
        guard let regionCode = Locale.current.regionCode else {
            return languageCode
        }
        return "\(languageCode)_\(regionCode)"
    }

    func displayMessages(_ messages: [Networking.JustInTimeMessage]) -> [JustInTimeMessage] {
        return messages.map { JustInTimeMessage(message: $0) }
    }

    func dismissMessage(_ message: JustInTimeMessage,
                        for siteID: Int64,
                        completion: @escaping (Result<Bool, Error>) -> ()) {
        Task {
            let result = await Result {
                try await remote.dismissJustInTimeMessage(for: siteID,
                                                                   messageID: message.messageID,
                                                                   featureClass: message.featureClass)
            }

            await MainActor.run {
                completion(result)
            }
        }
    }
}
