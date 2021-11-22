import Foundation

/// Media: Remote Endpoints
///
public class MediaRemote: Remote {
    /// Loads an array of media from the site's WP Media Library.
    /// API reference: https://developer.wordpress.com/docs/api/1.2/get/sites/%24site/media/
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll load the media from.
    ///   - pageNumber: The index of the page of media data to load from, starting from 1.
    ///   - pageSize: The number of media items to return.
    ///   - completion: Closure to be executed upon completion.
    ///
    public func loadMediaLibrary(for siteID: Int64,
                                 pageNumber: Int = Default.pageNumber,
                                 pageSize: Int = 25,
                                 context: String = Default.context,
                                 completion: @escaping (Result<[Media], Error>) -> Void) {
        let parameters: [String: Any] = [
            ParameterKey.contextKey: context,
            ParameterKey.pageSize: pageSize,
            ParameterKey.pageNumber: pageNumber,
            ParameterKey.fields: "ID,date,URL,thumbnails,title,alt,extension,mime_type,file",
            ParameterKey.mimeType: "image"
        ]

        let path = "sites/\(siteID)/media"
        let request = DotcomRequest(wordpressApiVersion: .mark1_1,
                                    method: .get,
                                    path: path,
                                    parameters: parameters)
        let mapper = MediaListMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Loads an array of media from the site's WP Media Library via WordPress site API.
    /// API reference: https://developer.wordpress.org/rest-api/reference/media/#list-media
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll load the media from.
    ///   - pageNumber: The index of the page of media data to load from, starting from 1.
    ///   - pageSize: The number of media items to return.
    ///   - completion: Closure to be executed upon completion.
    public func loadMediaLibraryFromWordPressSite(siteID: Int64,
                                                  pageNumber: Int = Default.pageNumber,
                                                  pageSize: Int = 25,
                                                  context: String = Default.context,
                                                  completion: @escaping (Result<[WordPressMedia], Error>) -> Void) {
        let parameters: [String: Any] = [
            ParameterKey.pageSize: pageSize,
            ParameterKey.pageNumber: pageNumber,
            ParameterKey.fieldsWordPressSite: Default.wordPressMediaFields,
            ParameterKey.mimeType: "image"
        ]

        let path = "sites/\(siteID)/media"
        let request = DotcomRequest(wordpressApiVersion: .wpMark2,
                                    method: .get,
                                    path: path,
                                    parameters: parameters)
        let mapper = WordPressMediaListMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Uploads an array of media in the local file system.
    /// API reference: https://developer.wordpress.com/docs/api/1.1/post/sites/%24site/media/new/
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll upload the media to.
    ///     - productID: Product for which the media items are first added to.
    ///     - context: Display or edit. Scope under which the request is made;
    ///                determines fields present in response. Default is Display.
    ///     - mediaItems: An array of uploadable media items.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func uploadMedia(for siteID: Int64,
                            productID: Int64,
                            context: String? = Default.context,
                            mediaItems: [UploadableMedia],
                            completion: @escaping (Result<[Media], Error>) -> Void) {
        let parameters = [
            ParameterKey.contextKey: context ?? Default.context,
        ]

        let formParameters: [String: String] = [Int](0..<mediaItems.count).reduce(into: [:]) { (parentIDsByKey, index) in
            parentIDsByKey["attrs[\(index)][parent_id]"] = "\(productID)"
        }

        let path = "sites/\(siteID)/media/new"
        let request = DotcomRequest(wordpressApiVersion: .mark1_1,
                                    method: .post,
                                    path: path,
                                    parameters: parameters)
        let mapper = MediaListMapper()

        enqueueMultipartFormDataUpload(request, mapper: mapper, multipartFormData: { multipartFormData in
            formParameters.forEach { (key, value) in
                multipartFormData.append(Data(value.utf8), withName: key)
            }

            mediaItems.forEach { mediaItem in
                multipartFormData.append(mediaItem.localURL,
                                         withName: "media[]",
                                         fileName: mediaItem.filename,
                                         mimeType: mediaItem.mimeType)
            }
        }, completion: completion)
    }

    /// Uploads an array of media in the local file system to the WordPress site.via WordPress site API
    /// API reference: https://developer.wordpress.org/rest-api/reference/media/#create-a-media-item
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll upload the media to.
    ///   - productID: Product for which the media items are first added to.
    ///   - mediaItems: An array of uploadable media items.
    ///   - completion: Closure to be executed upon completion.
    public func uploadMediaToWordPressSite(siteID: Int64,
                                           productID: Int64,
                                           mediaItems: [UploadableMedia],
                                           completion: @escaping (Result<WordPressMedia, Error>) -> Void) {
        let formParameters: [String: String] = [
            "post": "\(productID)",
            ParameterKey.fieldsWordPressSite: Default.wordPressMediaFields,
        ]
        let path = "sites/\(siteID)/media"
        let request = DotcomRequest(wordpressApiVersion: .wpMark2, method: .post, path: path, parameters: nil)
        let mapper = WordPressMediaMapper()

        enqueueMultipartFormDataUpload(request, mapper: mapper, multipartFormData: { multipartFormData in
            formParameters.forEach { (key, value) in
                multipartFormData.append(Data(value.utf8), withName: key)
            }

            mediaItems.forEach { mediaItem in
                multipartFormData.append(mediaItem.localURL,
                                         withName: ParameterValue.mediaUploadName,
                                         fileName: mediaItem.filename,
                                         mimeType: mediaItem.mimeType)
            }
        }, completion: completion)
    }
}


// MARK: - Constants
//
public extension MediaRemote {
    enum Default {
        public static let context: String = "display"
        public static let pageNumber = 1
    }

    private enum ParameterKey {
        static let pageNumber: String = "page"
        static let pageSize: String   = "number"
        static let fields: String     = "fields"
        static let mimeType: String   = "mime_type"
        static let contextKey: String = "context"
    }
}
