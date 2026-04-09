import Foundation
import Networking
import Storage

// MARK: - POSAuthStore
//
public class POSAuthStore: Store {
    private let remote: POSAuthRemote

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = POSAuthRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: POSAuthAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? POSAuthAction else {
            assertionFailure("POSAuthStore received an unsupported action")
            return
        }

        switch action {
        case let .authenticatePIN(siteID, pin, registerID, onCompletion):
            authenticatePIN(siteID: siteID, pin: pin, registerID: registerID, onCompletion: onCompletion)
        case let .requestApproval(siteID, pin, action, context, onCompletion):
            requestApproval(siteID: siteID, pin: pin, action: action, context: context, onCompletion: onCompletion)
        }
    }
}

// MARK: - Services
//
private extension POSAuthStore {

    func authenticatePIN(siteID: Int64,
                         pin: String,
                         registerID: String,
                         onCompletion: @escaping (Result<POSPINAuthResult, Error>) -> Void) {
        Task { @MainActor in
            do {
                let result = try await remote.authenticatePIN(siteID: siteID, pin: pin, registerID: registerID)
                onCompletion(.success(result))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    func requestApproval(siteID: Int64,
                         pin: String,
                         action: String,
                         context: [String: Int64],
                         onCompletion: @escaping (Result<POSApprovalResult, Error>) -> Void) {
        Task { @MainActor in
            do {
                let result = try await remote.requestApproval(siteID: siteID, pin: pin, action: action, context: context)
                onCompletion(.success(result))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }
}
