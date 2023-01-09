import Foundation

// MARK: - MediaAction: Defines media operations (supported by the MediaStore).
//
public enum MediaAction: Action {
    /// Retrieves media from the site's WP Media Library.
    ///
    /// - Parameters:
    ///   - forceWPOrgRestAPI: Forces to use WPOrg REST API
    ///   - siteID: Site for which we'll load the media from.
    ///   - pageNumber: The index of the page of media data to load from, starting from 1.
    ///   - pageSize: The maximum number of media items to return per page.
    ///   - onCompletion: Closure to be executed upon completion.
    ///
    case retrieveMediaLibrary(forceWPOrgRestAPI: Bool = false,
                              siteID: Int64,
                              pageNumber: Int,
                              pageSize: Int,
                              onCompletion: (Result<[Media], Error>) -> Void)

    /// Uploads an exportable media asset to the site's WP Media Library.
    ///
    case uploadMedia(forceWPOrgRestAPI: Bool = false,
                     siteID: Int64,
                     productID: Int64,
                     mediaAsset: ExportableAsset,
                     onCompletion: (Result<Media, Error>) -> Void)

    /// Updates the `parent_id` of the media using the provided `productID`.
    ///
    case updateProductID(forceWPOrgRestAPI: Bool = false,
                         siteID: Int64,
                         productID: Int64,
                         mediaID: Int64,
                         onCompletion: (Result<Media, Error>) -> Void)
}
