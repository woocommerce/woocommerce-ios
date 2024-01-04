import Foundation
import Networking

// MARK: - BlazeAction: Defines all of the Actions supported by the BlazeStore.
//
public enum BlazeAction: Action {

    /// Retrieves and stores Blaze Campaign for a site
    ///
    /// - `siteID`: the site for which Blaze campaigns should be fetched.
    /// - `pageNumber`: page of results to fetch campaigns. 1-indexed.
    /// - `onCompletion`: invoked when the sync operation finishes.
    ///     - `result.success(Bool)`: value indicates whether there are further pages to retrieve.
    ///     - `result.failure(Error)`: error indicates issues syncing the specified page.
    ///
    case synchronizeCampaigns(siteID: Int64,
                              pageNumber: Int,
                              onCompletion: (Result<Bool, Error>) -> Void)

    /// Retrieves and stores target devices for creating Blaze campaigns for a site.
    ///
    /// - `siteID`: the site to create Blaze campaign.
    /// - `locale`: the locale for the response.
    /// - `onCompletion`: invoked when the sync operation finishes.
    ///     - `result.success([BlazeTargetDevice])`: list of target devices for Blaze campaigns.
    ///     - `result.failure(Error)`: error indicates issues syncing data.
    ///
    case synchronizeTargetDevices(siteID: Int64,
                                  locale: String,
                                  onCompletion: (Result<[BlazeTargetDevice], Error>) -> Void)

    /// Retrieves and stores target languages for creating Blaze campaigns for a site.
    ///
    /// - `siteID`: the site to create Blaze campaign.
    /// - `locale`: the locale for the response.
    /// - `onCompletion`: invoked when the sync operation finishes.
    ///     - `result.success([BlazeTargetLanguage])`: list of target languages for Blaze campaigns.
    ///     - `result.failure(Error)`: error indicates issues syncing data.
    ///
    case synchronizeTargetLanguages(siteID: Int64,
                                    locale: String,
                                    onCompletion: (Result<[BlazeTargetLanguage], Error>) -> Void)

    /// Retrieves and stores target topics for creating Blaze campaigns for a site.
    ///
    /// - `siteID`: the site to create Blaze campaign.
    /// - `locale`: the locale for the response.
    /// - `onCompletion`: invoked when the sync operation finishes.
    ///     - `result.success([BlazeTargetTopic])`: list of target topics for Blaze campaigns.
    ///     - `result.failure(Error)`: error indicates issues syncing data.
    ///
    case synchronizeTargetTopics(siteID: Int64,
                                 locale: String,
                                 onCompletion: (Result<[BlazeTargetTopic], Error>) -> Void)

    /// Retrieves target locations for creating Blaze campaigns for a site.
    ///
    /// - `siteID`: the site to create Blaze campaign.
    /// - `query`: Keyword to search for locations. Requires a minimum of 3 characters.
    /// - `locale`: the locale for the response.
    /// - `onCompletion`: invoked when the sync operation finishes.
    ///     - `result.success([BlazeTargetLocation])`: list of target locations for Blaze campaigns.
    ///     - `result.failure(Error)`: error indicates issues syncing data.
    ///
    case fetchTargetLocations(siteID: Int64,
                              query: String,
                              locale: String,
                              onCompletion: (Result<[BlazeTargetLocation], Error>) -> Void)

    /// Retrieves forecasted amount of available impressions for a Blaze campaign to be created.
    ///
    /// - `siteID`: the site to create Blaze campaign.
    /// - `input`: the input for the forecasted impressions. Has various required and optional parameters.
    /// - `onCompletion`: invoked when the fect operation finishes.
    case fetchForecastedImpressions(siteID: Int64,
                                    input: BlazeForecastedImpressionsInput,
                                    onCompletion: (Result<BlazeImpressions, Error>) -> Void)
}
