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

    /// Retrieves and stores target devices for create Blaze campaigns for a site.
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

    /// Retrieves and stores target languages for create Blaze campaigns for a site.
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
}
