import Foundation

// MARK: - MediaAction: Defines media operations (supported by the MediaStore).
//
public enum MediaAction: Action {
    /// Retrieves single Media item from the site's WP Media Library.
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll load the media from.
    ///   - mediaID: ID of Media to be retrieved
    ///   - onCompletion: Closure to be executed upon completion.
    ///
    case retrieveMedia(siteID: Int64,
                       mediaID: Int64,
                       onCompletion: (Result<Media, Error>) -> Void)

    /// Retrieves media from the site's WP Media Library.
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll load the media from.
    ///   - productID: Loads media attached to a specific product ID. Loads all media if nil.
    ///   - imagesOnly: Whether only images should be loaded.
    ///   - pageNumber: The index of the page of media data to load from, starting from 1.
    ///   - pageSize: The maximum number of media items to return per page.
    ///   - onCompletion: Closure to be executed upon completion.
    ///
    case retrieveMediaLibrary(siteID: Int64,
                              productID: Int64? = nil,
                              imagesOnly: Bool,
                              pageNumber: Int,
                              pageSize: Int,
                              onCompletion: (Result<[Media], Error>) -> Void)

    /// Uploads an exportable media asset to the site's WP Media Library.
    ///
    case uploadMedia(siteID: Int64,
                     productID: Int64,
                     mediaAsset: ExportableAsset,
                     altText: String?,
                     filename: String?,
                     onCompletion: (Result<Media, Error>) -> Void)

    /// Uploads a local file to the site's WP Media Library.
    ///
    case uploadFile(siteID: Int64,
                    productID: Int64,
                    localURL: URL,
                    altText: String?,
                    onCompletion: (Result<Media, Error>) -> Void)

    /// Updates the `parent_id` of the media using the provided `productID`.
    ///
    case updateProductID(siteID: Int64,
                         productID: Int64,
                         mediaID: Int64,
                         onCompletion: (Result<Media, Error>) -> Void)
}
