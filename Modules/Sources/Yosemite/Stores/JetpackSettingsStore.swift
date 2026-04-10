import Foundation
import Networking
import Storage

// MARK: - JetpackSettingsStore
//
public class JetpackSettingsStore: Store {
    private let remote: JetpackSettingsRemoteProtocol

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = JetpackSettingsRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: JetpackSettingsAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? JetpackSettingsAction else {
            assertionFailure("JetpackSettingsStore received an unsupported action")
            return
        }

        switch action {
        case let .enableJetpackModule(module, siteID, completion):
            enableJetpackModule(module, for: siteID, completion: completion)
        }
    }
}

// MARK: - Services
//
private extension JetpackSettingsStore {
    func enableJetpackModule(_ module: JetpackModule, for siteID: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        Task { @MainActor in
            do {
                try await remote.enableJetpackModule(for: siteID, moduleSlug: module.rawValue)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
