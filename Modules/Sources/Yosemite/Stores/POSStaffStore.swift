import Foundation
import Networking
import Storage

/// Yosemite store backing `POSStaffAction`.
///
/// Wraps `POSStaffRemote.fetchStaff(siteID:)` in the Flux/Redux action-dispatch contract.
public final class POSStaffStore: Store {
    private let remote: POSStaffRemote

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = POSStaffRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: POSStaffAction.self)
    }

    /// Receives and executes Actions.
    override public func onAction(_ action: Action) {
        guard let action = action as? POSStaffAction else {
            assertionFailure("POSStaffStore received an unsupported action")
            return
        }

        switch action {
        case let .fetchStaff(siteID, onCompletion):
            fetchStaff(siteID: siteID, onCompletion: onCompletion)
        }
    }
}

// MARK: - Services

private extension POSStaffStore {

    func fetchStaff(siteID: Int64,
                    onCompletion: @escaping (Result<[POSStaffMember], Error>) -> Void) {
        Task { @MainActor in
            do {
                let staff = try await remote.fetchStaff(siteID: siteID)
                onCompletion(.success(staff))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }
}
