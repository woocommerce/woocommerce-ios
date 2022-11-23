import Foundation
import Networking
import WooFoundation
import protocol Storage.StorageManagerType

/// Handles `DomainAction`.
///
public final class DomainStore: Store {
    // Keeps a strong reference to remote to keep requests alive.
    private let remote: DomainRemoteProtocol

    public init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network, remote: DomainRemoteProtocol) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    public override convenience init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        let remote = DomainRemote(network: network)
        self.init(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)
    }

    public override func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: DomainAction.self)
    }

    /// Called whenever a given Action is dispatched.
    ///
    public override func onAction(_ action: Action) {
        guard let action = action as? DomainAction else {
            assertionFailure("DomainStore received an unsupported action: \(action)")
            return
        }
        switch action {
        case .loadFreeDomainSuggestions(let query, let completion):
            loadFreeDomainSuggestions(query: query, completion: completion)
        }
    }
}

private extension DomainStore {
    func loadFreeDomainSuggestions(query: String, completion: @escaping (Result<[FreeDomainSuggestion], Error>) -> Void) {
        Task { @MainActor in
            let result = await Result { try await remote.loadFreeDomainSuggestions(query: query) }
            completion(result)
        }
    }
}
