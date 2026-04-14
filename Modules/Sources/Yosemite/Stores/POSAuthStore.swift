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
        case let .verifyPIN(siteID, pin, onCompletion):
            verifyPIN(siteID: siteID, pin: pin, onCompletion: onCompletion)
        case let .fetchStaffStatus(siteID, onCompletion):
            fetchStaffStatus(siteID: siteID, onCompletion: onCompletion)
        case let .managePIN(siteID, userID, pin, action, onCompletion):
            managePIN(siteID: siteID, userID: userID, pin: pin, action: action, onCompletion: onCompletion)
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
                let result = try await remote.requestApproval(siteID: siteID,
                                                              pin: pin,
                                                              action: action,
                                                              context: context)
                onCompletion(.success(result))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    func verifyPIN(siteID: Int64,
                   pin: String,
                   onCompletion: @escaping (Result<POSPINVerifyResult, Error>) -> Void) {
        Task { @MainActor in
            do {
                let result = try await remote.verifyPIN(siteID: siteID, pin: pin)
                onCompletion(.success(result))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    func fetchStaffStatus(siteID: Int64,
                          onCompletion: @escaping (Result<[POSStaffUser], Error>) -> Void) {
        Task { @MainActor in
            do {
                let users = try await remote.fetchStaffStatus(siteID: siteID)
                onCompletion(.success(users))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    func managePIN(siteID: Int64,
                   userID: Int64,
                   pin: String?,
                   action: String,
                   onCompletion: @escaping (Result<Bool, Error>) -> Void) {
        Task { @MainActor in
            do {
                let success = try await remote.managePIN(siteID: siteID, userID: userID, pin: pin, action: action)
                onCompletion(.success(success))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }
}
