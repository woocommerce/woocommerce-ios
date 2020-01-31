import Foundation

// MARK: - MediaAction: Defines media operations (supported by the MediaStore).
//
public enum MediaAction: Action {
    /// Uploads an exportable media asset to the site's WP Media Library.
    ///
    case uploadMedia(siteID: Int64, mediaAsset: ExportableAsset, onCompletion: (_ uploadedMedia: Media?, _ error: Error?) -> Void)
}
