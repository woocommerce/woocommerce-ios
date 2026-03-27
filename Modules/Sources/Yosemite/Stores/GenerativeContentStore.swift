import Foundation
import Networking
import Storage

/// Handles `GenerativeContentAction` actions by forwarding them to `GenerativeContentRemote`.
///
public final class GenerativeContentStore: Store {

    private let remote: GenerativeContentRemoteProtocol

    public override convenience init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        let remote = GenerativeContentRemote(network: network)
        self.init(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
    }

    init(dispatcher: Dispatcher,
         storageManager: StorageManagerType,
         network: Network,
         remote: GenerativeContentRemoteProtocol) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: GenerativeContentAction.self)
    }

    override public func onAction(_ action: Action) {
        guard let action = action as? GenerativeContentAction else {
            assertionFailure("GenerativeContentStore received an unsupported action")
            return
        }

        switch action {
        case let .generateText(siteID, base, feature, responseFormat, completion):
            generateText(siteID: siteID, base: base, feature: feature, responseFormat: responseFormat, completion: completion)
        case let .identifyLanguage(siteID, string, feature, completion):
            identifyLanguage(siteID: siteID, string: string, feature: feature, completion: completion)
        }
    }
}

// MARK: - Private Methods
//
private extension GenerativeContentStore {

    func generateText(siteID: Int64,
                      base: String,
                      feature: GenerativeContentRemoteFeature,
                      responseFormat: GenerativeContentRemoteResponseFormat,
                      completion: @escaping (Result<String, Error>) -> Void) {
        Task { @MainActor in
            let result = await Result {
                try await remote.generateText(siteID: siteID, base: base, feature: feature, responseFormat: responseFormat)
            }
            completion(result)
        }
    }

    func identifyLanguage(siteID: Int64,
                          string: String,
                          feature: GenerativeContentRemoteFeature,
                          completion: @escaping (Result<String, Error>) -> Void) {
        Task { @MainActor in
            let result = await Result {
                try await remote.identifyLanguage(siteID: siteID, string: string, feature: feature)
            }
            completion(result)
        }
    }
}
