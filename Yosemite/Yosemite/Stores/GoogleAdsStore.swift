import Foundation
import Networking
import Storage

// MARK: - GoogleAdsStore
//
public final class GoogleAdsStore: Store {
    private let remote: GoogleListingsAndAdsRemoteProtocol

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.writerDerivedStorage
    }()

    init(dispatcher: Dispatcher,
         storageManager: StorageManagerType,
         network: Network,
         remote: GoogleListingsAndAdsRemoteProtocol) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Initializes a new GoogleAdsStore.
    /// - Parameters:
    ///   - dispatcher: The dispatcher used to subscribe to `GoogleAdsAction`.
    ///   - storageManager: The storage layer used to store and retrieve persisted data.
    ///   - network: The network layer used to fetch data from the remote
    ///
    public override convenience init(dispatcher: Dispatcher,
                                     storageManager: StorageManagerType,
                                     network: Network) {
        self.init(dispatcher: dispatcher,
                  storageManager: storageManager,
                  network: network,
                  remote: GoogleListingsAndAdsRemote(network: network))
    }

    // MARK: - Actions

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: GoogleAdsAction.self)
    }

    /// Receives and executes Actions.
    /// - Parameters:
    ///   - action: An action to handle. Must be a `GoogleAdsAction`
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? GoogleAdsAction else {
            assertionFailure("GoogleAdsStore received an unsupported action")
            return
        }

        switch action {
        case let .checkConnection(siteID, onCompletion):
            checkConnection(siteID: siteID, onCompletion: onCompletion)
        case let .fetchAdsCampaigns(siteID, onCompletion):
            fetchAdsCampaign(siteID: siteID, onCompletion: onCompletion)
        case let .retrieveCampaignStats(siteID, timeZone, earliestDateToInclude, latestDateToInclude, onCompletion):
            retrieveCampaignStats(siteID: siteID,
                                  timeZone: timeZone,
                                  earliestDateToInclude: earliestDateToInclude,
                                  latestDateToInclude: latestDateToInclude,
                                  onCompletion: onCompletion)
        }
    }
}

private extension GoogleAdsStore {
    func checkConnection(siteID: Int64,
                         onCompletion: @escaping (Result<GoogleAdsConnection, Error>) -> Void) {
        Task { @MainActor in
            do {
                let connection = try await remote.checkConnection(for: siteID)
                onCompletion(.success(connection))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    func fetchAdsCampaign(siteID: Int64,
                          onCompletion: @escaping (Result<[GoogleAdsCampaign], Error>) -> Void) {
        Task { @MainActor in
            do {
                let campaigns = try await remote.fetchAdsCampaigns(for: siteID)
                onCompletion(.success(campaigns))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    func retrieveCampaignStats(siteID: Int64,
                               timeZone: TimeZone,
                               earliestDateToInclude: Date,
                               latestDateToInclude: Date,
                               onCompletion: @escaping (Result<GoogleAdsCampaignStats, Error>) -> Void) {
        Task { @MainActor in
            do {
                let campaignStats = try await remote.loadCampaignStats(for: siteID,
                                                                       timeZone: timeZone,
                                                                       earliestDateToInclude: earliestDateToInclude,
                                                                       latestDateToInclude: latestDateToInclude,
                                                                       totals: GoogleListingsAndAdsRemote.StatsField.allCases,
                                                                       orderby: .sales,
                                                                       nextPageToken: nil)
                onCompletion(.success(campaignStats))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }
}
