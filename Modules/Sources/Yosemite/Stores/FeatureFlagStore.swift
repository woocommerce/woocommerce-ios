import Foundation
import Networking
import Storage

public final class FeatureFlagStore: Store {
    private let remote: FeatureFlagRemoteProtocol
    private let overrideStore: RemoteFeatureFlagOverrideStore?
    private let currentSiteIDProvider: @MainActor () -> Int64?
    private let activePluginVersionsProvider: @MainActor (Int64?) -> [String: String]
    private var cachedFeatureFlagsByContext: [FeatureFlagContext: CacheEntry] = [:]
    private var activePluginVersionsBySite: [SiteContext: [String: String]] = [:]
    private let cacheMaxAge: TimeInterval
    private let currentDate: () -> Date

    init(dispatcher: Dispatcher,
         storageManager: StorageManagerType,
         network: Network,
         remote: FeatureFlagRemoteProtocol,
         overrideStore: RemoteFeatureFlagOverrideStore? = nil,
         cacheMaxAge: TimeInterval = 24 * 60 * 60,
         currentDate: @escaping () -> Date = { Date() },
         currentSiteIDProvider: @escaping @MainActor () -> Int64? = { nil },
         activePluginVersionsProvider: @escaping @MainActor (Int64?) -> [String: String] = { _ in [:] }) {
        self.remote = remote
        self.cacheMaxAge = cacheMaxAge
        self.currentDate = currentDate
        self.overrideStore = overrideStore
        self.currentSiteIDProvider = currentSiteIDProvider
        self.activePluginVersionsProvider = activePluginVersionsProvider
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
                            overrideStore: RemoteFeatureFlagOverrideStore?,
                            currentSiteIDProvider: @escaping @MainActor () -> Int64? = { nil },
                            activePluginVersionsProvider: @escaping @MainActor (Int64?) -> [String: String] = { _ in [:] }) {
        self.init(dispatcher: dispatcher,
                  storageManager: storageManager,
                  network: network,
                  remote: FeatureFlagRemote(network: network),
                  overrideStore: overrideStore,
                  currentSiteIDProvider: currentSiteIDProvider,
                  activePluginVersionsProvider: activePluginVersionsProvider)
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
        case let .refreshRemoteFeatureFlags(siteID, activePluginVersions, completion):
            refreshRemoteFeatureFlags(siteID: siteID, activePluginVersions: activePluginVersions, completion: completion)
        }
    }
}

// MARK: - Services
//
private extension FeatureFlagStore {
    func isCacheExpired(_ entry: CacheEntry) -> Bool {
        currentDate().timeIntervalSince(entry.timestamp) >= cacheMaxAge
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

        Task { @MainActor in
            let context = currentContext()

            if useCache, let entry = cachedFeatureFlagsByContext[context], !isCacheExpired(entry) {
                completion(entry.featureFlags[featureFlag] ?? defaultValue)
                return
            }

            do {
                let featureFlags = try await remote.loadAllFeatureFlags(activePluginVersions: context.activePluginVersionsDictionary)
                cachedFeatureFlagsByContext[context] = CacheEntry(featureFlags: featureFlags, timestamp: currentDate())
                completion(featureFlags[featureFlag] ?? defaultValue)
            } catch {
                DDLogError("⛔️ FeatureFlagStore: Failed to load feature flags with error: \(error)")
                completion(defaultValue)
            }
        }
    }

    func refreshRemoteFeatureFlags(siteID: Int64?,
                                   activePluginVersions: [String: String],
                                   completion: @escaping (Result<Void, Error>) -> Void) {
        Task { @MainActor in
            let siteContext = SiteContext(siteID: siteID)
            activePluginVersionsBySite[siteContext] = activePluginVersions
            let context = FeatureFlagContext(siteContext: siteContext, activePluginVersions: activePluginVersions)

            do {
                let featureFlags = try await remote.loadAllFeatureFlags(activePluginVersions: activePluginVersions)
                cachedFeatureFlagsByContext[context] = CacheEntry(featureFlags: featureFlags, timestamp: currentDate())
                completion(.success(()))
            } catch {
                DDLogError("⛔️ FeatureFlagStore: Failed to refresh feature flags with error: \(error)")
                completion(.failure(error))
            }
        }
    }

    @MainActor
    func currentContext() -> FeatureFlagContext {
        let siteID = currentSiteIDProvider()
        let siteContext = SiteContext(siteID: siteID)
        let activePluginVersions = activePluginVersionsBySite[siteContext] ?? activePluginVersionsProvider(siteID)
        return FeatureFlagContext(siteContext: siteContext, activePluginVersions: activePluginVersions)
    }
}

private struct CacheEntry {
    let featureFlags: [RemoteFeatureFlag: Bool]
    let timestamp: Date
}

private enum SiteContext: Hashable {
    case noSite
    case site(Int64)

    init(siteID: Int64?) {
        if let siteID {
            self = .site(siteID)
        } else {
            self = .noSite
        }
    }
}

private struct FeatureFlagContext: Hashable {
    let siteContext: SiteContext
    let activePluginVersions: [PluginVersion]

    init(siteContext: SiteContext, activePluginVersions: [String: String]) {
        self.siteContext = siteContext
        self.activePluginVersions = activePluginVersions
            .map { PluginVersion(plugin: $0.key, version: $0.value) }
            .sorted()
    }

    var activePluginVersionsDictionary: [String: String] {
        Dictionary(uniqueKeysWithValues: activePluginVersions.map { ($0.plugin, $0.version) })
    }
}

private struct PluginVersion: Hashable, Comparable {
    let plugin: String
    let version: String

    static func < (lhs: PluginVersion, rhs: PluginVersion) -> Bool {
        if lhs.plugin == rhs.plugin {
            return lhs.version < rhs.version
        }
        return lhs.plugin < rhs.plugin
    }
}
