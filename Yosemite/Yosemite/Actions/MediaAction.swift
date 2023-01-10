import Foundation

// MARK: - MediaAction: Defines media operations (supported by the MediaStore).
//
public enum MediaAction: Action {

    /// Site information using which `MediaAction` will be performed
    ///
    public enum SiteInfo {
        // Connects to WordPress.com servers using provided `siteID`
        //
        case wpcom(_ siteID: Int64)

        // Connects to the site URL
        //
        case wporg(_ siteURL: String)
    }

    /// Retrieves media from the site's WP Media Library.
    ///
    /// - Parameters:
    ///   - connectUsing: Provides Site ID or Site URL based on the current login method
    ///   - pageNumber: The index of the page of media data to load from, starting from 1.
    ///   - pageSize: The maximum number of media items to return per page.
    ///   - onCompletion: Closure to be executed upon completion.
    ///
    case retrieveMediaLibrary(connectUsing: SiteInfo,
                              pageNumber: Int,
                              pageSize: Int,
                              onCompletion: (Result<[Media], Error>) -> Void)

    /// Uploads an exportable media asset to the site's WP Media Library.
    ///
    case uploadMedia(connectUsing: SiteInfo,
                     productID: Int64,
                     mediaAsset: ExportableAsset,
                     onCompletion: (Result<Media, Error>) -> Void)

    /// Updates the `parent_id` of the media using the provided `productID`.
    ///
    case updateProductID(connectUsing: SiteInfo,
                         productID: Int64,
                         mediaID: Int64,
                         onCompletion: (Result<Media, Error>) -> Void)
}
