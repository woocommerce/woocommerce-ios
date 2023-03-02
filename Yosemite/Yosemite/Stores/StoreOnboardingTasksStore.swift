import Networking
import Storage

public final class StoreOnboardingTasksStore: Store {
    private let remote: StoreOnboardingTasksRemoteProtocol

    init(dispatcher: Dispatcher,
         storageManager: StorageManagerType,
         network: Network,
         remote: StoreOnboardingTasksRemoteProtocol) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    public override convenience init(dispatcher: Dispatcher,
                                     storageManager: StorageManagerType,
                                     network: Network) {
        self.init(dispatcher: dispatcher,
                  storageManager: storageManager,
                  network: network,
                  remote: StoreOnboardingTasksRemote(network: network))
    }

    // MARK: - Actions

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: StoreOnboardingTasksAction.self)
    }

    /// Receives and executes Actions.
    /// - Parameters:
    ///   - action: An action to handle. Must be a `StoreOnboardingTasksAction`
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? StoreOnboardingTasksAction else {
            assertionFailure("StoreOnboardingTasksStore received an unsupported action")
            return
        }

        switch action {
        case .loadOnboardingTasks(let siteID, let onCompletion):
            loadOnboardingTasks(siteID: siteID, completion: onCompletion)
        }
    }
}

// MARK: - Services
//
private extension StoreOnboardingTasksStore {
    func loadOnboardingTasks(siteID: Int64, completion: @escaping (Result<[StoreOnboardingTask], Error>) -> Void) {
        Task { @MainActor in
            let result = await Result { try await remote.loadOnboardingTasks(siteID: siteID) }
            completion(result)
        }
    }
}
