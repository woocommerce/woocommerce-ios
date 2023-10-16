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
}
