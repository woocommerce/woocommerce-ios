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
        case let .retrieveCampaignStats(siteID, campaignIDs, timeZone, earliestDateToInclude, latestDateToInclude, onCompletion):
            retrieveCampaignStats(siteID: siteID,
                                  campaignIDs: campaignIDs,
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
                               campaignIDs: [Int64],
                               timeZone: TimeZone,
                               earliestDateToInclude: Date,
                               latestDateToInclude: Date,
                               onCompletion: @escaping (Result<GoogleAdsCampaignStats, Error>) -> Void) {
        Task { @MainActor in
            do {
                var hasNextPage = true
                var nextPageToken: String? = nil
                var statsPages: [GoogleAdsCampaignStats] = []

                // Each page contains only partial stats.
                // We request new pages until there are no more pages to request, so they can be compiled into a single set of stats.
                while hasNextPage {
                    let campaignStats = try await remote.loadCampaignStats(for: siteID,
                                                                           campaignIDs: campaignIDs,
                                                                           timeZone: timeZone,
                                                                           earliestDateToInclude: earliestDateToInclude,
                                                                           latestDateToInclude: latestDateToInclude,
                                                                           totals: GoogleListingsAndAdsRemote.StatsField.allCases,
                                                                           orderby: .sales,
                                                                           nextPageToken: nextPageToken)
                    hasNextPage = campaignStats.hasNextPage
                    nextPageToken = campaignStats.nextPageToken
                    statsPages.append(campaignStats)
                }

                let combinedStats = compileCampaignStats(siteID: siteID, stats: statsPages)
                onCompletion(.success(combinedStats))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }
}

// MARK: retrieveCampaignStats helpers

private extension GoogleAdsStore {
    /// Creates a single Google Ads campaign stats object from an array of stats.
    ///
    /// Each page of campaign stats only contains the totals for the campaigns in that page.
    /// This method can be used to compile multiple pages of campaign stats, by summing all of the stats totals and creating a single list of campaigns.
    ///
    func compileCampaignStats(siteID: Int64, stats: [GoogleAdsCampaignStats]) -> GoogleAdsCampaignStats {
        let totalSales = sum(stats.map { $0.totals.sales })
        let totalSpend = sum(stats.map { $0.totals.spend })
        let totalClicks = sum(stats.map { $0.totals.clicks })
        let totalImpressions = sum(stats.map { $0.totals.impressions })
        let totalConversions = sum(stats.map { $0.totals.conversions })
        let allCampaigns = stats.flatMap { $0.campaigns }

        return GoogleAdsCampaignStats(siteID: siteID,
                                      totals: GoogleAdsCampaignStatsTotals(sales: totalSales,
                                                                           spend: totalSpend,
                                                                           clicks: totalClicks,
                                                                           impressions: totalImpressions,
                                                                           conversions: totalConversions),
                                      campaigns: allCampaigns,
                                      nextPageToken: nil)
    }

    /// Sums an array of optional `Numeric` values.
    ///
    /// Returns the sum of all values, or `nil` if all values are `nil`.
    ///
    func sum<T: Numeric>(_ values: [T?]) -> T? {
        values.reduce(nil as T?) { result, nextValue in
            guard result != nil || nextValue != nil else {
                return nil
            }
            return (result ?? 0) + (nextValue ?? 0)
        }
    }
}
