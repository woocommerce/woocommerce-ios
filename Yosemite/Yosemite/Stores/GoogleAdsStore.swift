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
                let combinedStats = try await retrieveAllCampaignStats(siteID: siteID,
                                                                       timeZone: timeZone,
                                                                       earliestDateToInclude: earliestDateToInclude,
                                                                       latestDateToInclude: latestDateToInclude)
                onCompletion(.success(combinedStats))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }
}

// MARK: retrieveCampaignStats helpers

private extension GoogleAdsStore {

    /// Requests all pages of Google Ads campaign stats for the requested period.
    ///
    /// Each page contains partial stats. This continues to request new pages until there are no more pages to request, and compiles the results.
    ///
    func retrieveAllCampaignStats(siteID: Int64,
                                  timeZone: TimeZone,
                                  earliestDateToInclude: Date,
                                  latestDateToInclude: Date) async throws -> GoogleAdsCampaignStats {
        var campaignStats = try await remote.loadCampaignStats(for: siteID,
                                                               timeZone: timeZone,
                                                               earliestDateToInclude: earliestDateToInclude,
                                                               latestDateToInclude: latestDateToInclude,
                                                               totals: GoogleListingsAndAdsRemote.StatsField.allCases,
                                                               orderby: .sales,
                                                               nextPageToken: nil)
        var statsArray: [GoogleAdsCampaignStats] = [campaignStats]
        while campaignStats.hasNextPage {
            guard let token = campaignStats.nextPageToken else {
                break
            }
            campaignStats = try await remote.loadCampaignStats(for: siteID,
                                                               timeZone: timeZone,
                                                               earliestDateToInclude: earliestDateToInclude,
                                                               latestDateToInclude: latestDateToInclude,
                                                               totals: GoogleListingsAndAdsRemote.StatsField.allCases,
                                                               orderby: .sales,
                                                               nextPageToken: token)
            statsArray.append(campaignStats)
        }
        return compileCampaignStats(siteID: siteID, stats: statsArray)
    }

    /// Creates a single Google Ads campaign stats object from an array of stats.
    ///
    /// Each page of campaign stats only contains the totals for the campaigns in that page.
    /// This method can be used to compile multiple pages of campaign stats, by summing all of the stats totals and creating a single list of campaigns.
    ///
    func compileCampaignStats(siteID: Int64, stats: [GoogleAdsCampaignStats]) -> GoogleAdsCampaignStats {
        stats.reduce(GoogleAdsCampaignStats.init(siteID: siteID,
                                                 totals: GoogleAdsCampaignStatsTotals(sales: nil, spend: nil, clicks: nil, impressions: nil, conversions: nil),
                                                 campaigns: [],
                                                 nextPageToken: nil)) { partialResult, nextPage in
            let totalSales = addOptionalValues(partialResult.totals.sales, and: nextPage.totals.sales)
            let totalSpend = addOptionalValues(partialResult.totals.spend, and: nextPage.totals.spend)
            let totalClicks = addOptionalValues(partialResult.totals.clicks, and: nextPage.totals.clicks)
            let totalImpressions = addOptionalValues(partialResult.totals.impressions, and: nextPage.totals.impressions)
            let totalConversions = addOptionalValues(partialResult.totals.conversions, and: nextPage.totals.conversions)
            return GoogleAdsCampaignStats(siteID: siteID,
                                          totals: GoogleAdsCampaignStatsTotals(sales: totalSales,
                                                                               spend: totalSpend,
                                                                               clicks: totalClicks,
                                                                               impressions: totalImpressions,
                                                                               conversions: totalConversions),
                                          campaigns: partialResult.campaigns + nextPage.campaigns,
                                          nextPageToken: nil)
        }
    }

    /// Adds two optional values of the same `Numeric` type.
    ///
    func addOptionalValues<T: Numeric>(_ firstValue: T?, and secondValue: T?) -> T? {
        guard firstValue != nil || secondValue != nil else {
            return nil
        }
        return (firstValue ?? 0) + (secondValue ?? 0)
    }
}
