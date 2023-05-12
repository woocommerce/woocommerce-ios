import Networking
import Storage

public final class FeatureFlagStore: Store {
    private let remote: FeatureFlagRemoteProtocol

    init(dispatcher: Dispatcher,
         storageManager: StorageManagerType,
         network: Network,
         remote: FeatureFlagRemoteProtocol) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    public override convenience init(dispatcher: Dispatcher,
                                     storageManager: StorageManagerType,
                                     network: Network) {
        self.init(dispatcher: dispatcher,
                  storageManager: storageManager,
                  network: network,
                  remote: FeatureFlagRemote(network: network))
    }

    // MARK: - Actions

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: FeatureFlagAction.self)
    }

    /// Receives and executes Actions.
    /// - Parameters:
    ///   - action: An action to handle. Must be a `FeatureFlagAction`
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? FeatureFlagAction else {
            assertionFailure("StoreOnboardingTasksStore received an unsupported action")
            return
        }

        switch action {
        case let .isRemoteFeatureFlagEnabled(featureFlag, defaultValue, completion):
            isRemoteFeatureFlagEnabled(featureFlag, defaultValue: defaultValue, completion: completion)
        }
    }
}

// MARK: - Services
//
private extension FeatureFlagStore {
    func isRemoteFeatureFlagEnabled(_ featureFlag: RemoteFeatureFlag, defaultValue: Bool, completion: @escaping (Bool) -> Void) {
        Task { @MainActor in
            do {
                let featureFlags = try await remote.loadAllFeatureFlags()
                await MainActor.run {
                    completion(featureFlags[featureFlag] ?? defaultValue)
                }
            } catch {
                DDLogError("⛔️ FeatureFlagStore: Failed to load feature flags with error: \(error)")
                await MainActor.run {
                    completion(defaultValue)
                }
            }
        }
    }
}
