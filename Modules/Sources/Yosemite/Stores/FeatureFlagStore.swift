import Foundation
import Networking
import Storage

public final class FeatureFlagStore: Store {
    private let remote: FeatureFlagRemoteProtocol
    private let overrideStore: RemoteFeatureFlagOverrideStore?
    private var cachedFeatureFlags: [RemoteFeatureFlag: Bool]?
    private var cacheTimestamp: Date?
    private let cacheMaxAge: TimeInterval
    private let currentDate: () -> Date

    init(dispatcher: Dispatcher,
         storageManager: StorageManagerType,
         network: Network,
         remote: FeatureFlagRemoteProtocol,
         overrideStore: RemoteFeatureFlagOverrideStore? = nil,
         cacheMaxAge: TimeInterval = 24 * 60 * 60,
         currentDate: @escaping () -> Date = { Date() }) {
        self.remote = remote
        self.cacheMaxAge = cacheMaxAge
        self.currentDate = currentDate
        self.overrideStore = overrideStore
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    override public convenience init(dispatcher: Dispatcher,
                                     storageManager: StorageManagerType,
                                     network: Network) {
        self.init(dispatcher: dispatcher,
                  storageManager: storageManager,
                  network: network,
                  remote: FeatureFlagRemote(network: network),
                  overrideStore: nil)
    }

    public convenience init(dispatcher: Dispatcher,
                            storageManager: StorageManagerType,
                            network: Network,
                            overrideStore: RemoteFeatureFlagOverrideStore?) {
        self.init(dispatcher: dispatcher,
                  storageManager: storageManager,
                  network: network,
                  remote: FeatureFlagRemote(network: network),
                  overrideStore: overrideStore)
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
            assertionFailure("FeatureFlagStore received an unsupported action")
            return
        }

        switch action {
        case let .isRemoteFeatureFlagEnabled(featureFlag, defaultValue, useCache, completion):
            isRemoteFeatureFlagEnabled(featureFlag, defaultValue: defaultValue, useCache: useCache, completion: completion)
        }
    }
}

// MARK: - Services
//
private extension FeatureFlagStore {
    var isCacheExpired: Bool {
        guard let cacheTimestamp else { return true }
        return currentDate().timeIntervalSince(cacheTimestamp) >= cacheMaxAge
    }

    func isRemoteFeatureFlagEnabled(_ featureFlag: RemoteFeatureFlag,
                                    defaultValue: Bool,
                                    useCache: Bool,
                                    completion: @escaping (Bool) -> Void) {
        // Check for override first
        if let overrideValue = overrideStore?.overrideValue(for: featureFlag) {
            completion(overrideValue)
            return
        }

        if useCache, let cachedFlags = cachedFeatureFlags, !isCacheExpired {
            completion(cachedFlags[featureFlag] ?? defaultValue)
            return
        }

        Task { @MainActor in
            do {
                let featureFlags = try await remote.loadAllFeatureFlags()
                await MainActor.run {
                    self.cachedFeatureFlags = featureFlags
                    self.cacheTimestamp = self.currentDate()
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
