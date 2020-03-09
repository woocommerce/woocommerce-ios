import Foundation

// MARK: - MediaAction: Defines media operations (supported by the MediaStore).
//
public enum MediaAction: Action {
    /// Retrieves media from the site's WP Media Library.
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll load the media from.
    ///   - pageFirstIndex: The index of the first page from the caller's perspective, which `pageNumber` is based on.
    ///   - pageNumber: The index of the page of media data to load from.
    ///   - pageSize: The maximum number of media items to return per page.
    ///   - onCompletion: Closure to be executed upon completion.
    ///
    case retrieveMediaLibrary(siteID: Int64,
        pageFirstIndex: Int,
        pageNumber: Int,
        pageSize: Int,
        onCompletion: (_ mediaItems: [Media], _ error: Error?) -> Void)

    /// Uploads an exportable media asset to the site's WP Media Library.
    ///
    case uploadMedia(siteID: Int64, mediaAsset: ExportableAsset, onCompletion: (_ uploadedMedia: Media?, _ error: Error?) -> Void)
}
