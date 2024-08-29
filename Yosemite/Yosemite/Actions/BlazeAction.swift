import Foundation
import Networking

// MARK: - BlazeAction: Defines all of the Actions supported by the BlazeStore.
//
public enum BlazeAction: Action {

    /// Creates a new Blaze campaign
    ///
    /// - `campaign`: New Blaze campaign to be created
    /// - `siteID`: the site in which Blaze campaign should be created.
    /// - `onCompletion`: invoked when the create operation finishes.
    ///     - `result.success()`: Successfully created Blaze campaign.
    ///     - `result.failure(Error)`: error indicates issues creating a Blaze campaign.
    ///
    case createCampaign(campaign: CreateBlazeCampaign,
                        siteID: Int64,
                        onCompletion: (Result<Void, Error>) -> Void)

    /// Retrieves and stores Blaze Campaign items for a site using v1.1 endpoint.
    ///
    /// - `siteID`: the site for which Blaze campaigns should be fetched.
    /// - `skip`: Pagination offset
    /// - `limit`:  Pagination limit
    /// - `onCompletion`: invoked when the sync operation finishes.
    ///     - `result.success(Bool)`: value indicates whether there are further pages to retrieve.
    ///     - `result.failure(Error)`: error indicates issues syncing the specified page.
    ///
    case synchronizeCampaignsList(siteID: Int64,
                                   skip: Int,
                                   limit: Int,
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
    /// - `onCompletion`: invoked when the fetch operation finishes.
    case fetchForecastedImpressions(siteID: Int64,
                                    input: BlazeForecastedImpressionsInput,
                                    onCompletion: (Result<BlazeImpressions, Error>) -> Void)

    /// Fetches AI based suggestions for Blaze campaign tagline and description for given product ID
    ///
    /// - siteID: WPCom ID for the site to create the campaign in.
    /// - productID: ID of the product to create the campaign for.
    /// - `onCompletion`: invoked when the fetch operation finishes.
    ///   - `result.success([BlazeAISuggestion])`: list of AI suggestions.
    ///   - `result.failure(Error)`: error indicates issues fetching info.
    ///
    case fetchAISuggestions(siteID: Int64,
                            productID: Int64,
                            onCompletion: (Result<[BlazeAISuggestion], Error>) -> Void)

    /// Fetches payment info for Blaze campaign creation given a site ID.
    ///
    /// - siteID: WPCom ID for the site to create the campaign in.
    /// - `onCompletion`: invoked when the fetch operation finishes.
    ///   - `result.success(BlazePaymentInfo)`: info for payment methods.
    ///   - `result.failure(Error)`: error indicates issues fetching info.
    ///
    case fetchPaymentInfo(siteID: Int64,
                          onCompletion: (Result<BlazePaymentInfo, Error>) -> Void)

    /// Retrieves and stores campaign objectives for creating Blaze campaigns for a site.
    ///
    /// - `siteID`: the site to create Blaze campaign.
    /// - `locale`: the locale for the response.
    /// - `onCompletion`: invoked when the sync operation finishes.
    ///     - `result.success([BlazeCampaignObjective])`: list of objectives for Blaze campaigns.
    ///     - `result.failure(Error)`: error indicates issues syncing data.
    ///
    case synchronizeCampaignObjectives(siteID: Int64,
                                       locale: String,
                                       onCompletion: (Result<[BlazeCampaignObjective], Error>) -> Void)
}
