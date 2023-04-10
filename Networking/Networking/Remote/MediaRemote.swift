import Alamofire
import Foundation
public typealias Result = Swift.Result

/// Protocol for `MediaRemote` mainly used for mocking.
public protocol MediaRemoteProtocol {
    func loadMediaLibrary(for siteID: Int64,
                          pageNumber: Int,
                          pageSize: Int,
                          context: String?,
                          completion: @escaping (Result<[Media], Error>) -> Void)
    func loadMediaLibraryFromWordPressSite(siteID: Int64,
                                           pageNumber: Int,
                                           pageSize: Int,
                                           completion: @escaping (Result<[WordPressMedia], Error>) -> Void)
    func uploadMedia(for siteID: Int64,
                     productID: Int64,
                     context: String?,
                     mediaItems: [UploadableMedia],
                     completion: @escaping (Result<[Media], Error>) -> Void)
    func uploadMediaToWordPressSite(siteID: Int64,
                                    productID: Int64,
                                    mediaItems: [UploadableMedia],
                                    completion: @escaping (Result<WordPressMedia, Error>) -> Void)
    func updateProductID(siteID: Int64,
                         productID: Int64,
                         mediaID: Int64,
                         completion: @escaping (Result<Media, Error>) -> Void)
    func updateProductIDToWordPressSite(siteID: Int64,
                                        productID: Int64,
                                        mediaID: Int64,
                                        completion: @escaping (Result<WordPressMedia, Error>) -> Void)

    func replaceBackground(image: Data, prompt: String) async throws -> UIImage
}

/// Media: Remote Endpoints
///
public class MediaRemote: Remote, MediaRemoteProtocol {
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
                                 context: String? = Default.context,
                                 completion: @escaping (Result<[Media], Error>) -> Void) {
        let parameters: [String: Any] = [
            ParameterKey.contextKey: context ?? Default.context,
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
                                                  completion: @escaping (Result<[WordPressMedia], Error>) -> Void) {
        let parameters: [String: Any] = [
            ParameterKey.pageSize: pageSize,
            ParameterKey.pageNumber: pageNumber,
            ParameterKey.fieldsWordPressSite: ParameterValue.wordPressMediaFields,
            ParameterKey.mimeType: "image"
        ]

        let path = "sites/\(siteID)/media"
        do {
            let request = try DotcomRequest(wordpressApiVersion: .wpMark2,
                                            method: .get,
                                            path: path,
                                            parameters: parameters,
                                            availableAsRESTRequest: true)
            let mapper = WordPressMediaListMapper()

            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
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
            ParameterKey.wordPressMediaPostID: "\(productID)",
            ParameterKey.fieldsWordPressSite: ParameterValue.wordPressMediaFields,
        ]
        let path = "sites/\(siteID)/media"
        do {
            let request = try DotcomRequest(wordpressApiVersion: .wpMark2, method: .post, path: path, parameters: nil, availableAsRESTRequest: true)
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
        } catch {
            completion(.failure(error))
        }
    }

    /// Sets the provided `productID` as `parent_id` of the `media`.
    ///
    /// API reference: https://developer.wordpress.com/docs/api/1.1/post/sites/%24site/media/%24media_ID/
    ///
    /// - Parameters:
    ///     - siteID: Site in which the media was uploaded to.
    ///     - productID: Product ID to use as `parent_id` of the media.
    ///     - mediaID: ID of media for which `parent_id` needs to be updated.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func updateProductID(siteID: Int64,
                                productID: Int64,
                                mediaID: Int64,
                                completion: @escaping (Result<Media, Error>) -> Void) {
        let formParameters: [String: String] = [
            ParameterKey.wordPressMediaParentID: "\(productID)",
            ParameterKey.fieldsWordPressSite: ParameterValue.wordPressMediaFields,
        ]
        let path = "sites/\(siteID)/media/\(mediaID)"
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .post, path: path, parameters: formParameters)
        let mapper = MediaMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Sets the provided `productID` as post ID of the Media in WordPress site using WordPress site API
    ///
    /// API reference: to the WordPress site.via WordPress site API
    /// https://developer.wordpress.org/rest-api/reference/media/#update-a-media-item
    ///
    /// - Parameters:
    ///     - siteID: Site in which the media was uploaded to.
    ///     - productID: Product ID to use as post ID of the media.
    ///     - mediaID: ID of media for which post ID needs to be updated.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func updateProductIDToWordPressSite(siteID: Int64,
                                               productID: Int64,
                                               mediaID: Int64,
                                               completion: @escaping (Result<WordPressMedia, Error>) -> Void) {
        let parameters: [String: String] = [
            ParameterKey.wordPressMediaPostID: "\(productID)",
            ParameterKey.fieldsWordPressSite: ParameterValue.wordPressMediaFields,
        ]
        let path = "sites/\(siteID)/media/\(mediaID)"
        do {
            let request = try DotcomRequest(wordpressApiVersion: .wpMark2, method: .post, path: path, parameters: parameters, availableAsRESTRequest: true)
            let mapper = WordPressMediaMapper()

            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    public func replaceBackground(image: Data, prompt: String) async throws -> UIImage {
        let url = "https://apis.clipdrop.co/replace-background/v1"
        let headers = [
            "x-api-key": ""
        ]
        let promptData = prompt.data(using: .utf8)!
        return try await withCheckedThrowingContinuation { continuation in
            let request = ExternalRequest(method: .post, url: url, headers: headers)
            let mapper = ClipDropMediaMapper()

            // TODO-JC: use existing network instead of AF directly
            Alamofire.upload(multipartFormData: { multipartFormData in
                multipartFormData.append(
                    image,
                    withName: "image_file",
                    fileName: "object.jpg",
                    mimeType: "image/jpeg"
                )
                multipartFormData.append(promptData, withName: "prompt")
            }, to: url, headers: headers) { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseData { response in
                        switch response.result {
                        case .success:
                            if let dataSafe = response.data, let imageReceived = UIImage.init(data: dataSafe) {
                                continuation.resume(returning: imageReceived)
                            } else {
                                continuation.resume(throwing: NSError(domain: "111", code: 111))
                            }
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }
                    upload.uploadProgress { progress in
                        // Progress callback if needed.
                    }
                case .failure(let encodingError):
                    continuation.resume(throwing: encodingError)
                }
            }
        }
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
        static let wordPressMediaPostID: String = "post"
        static let fields: String     = "fields"
        static let fieldsWordPressSite: String = "_fields"
        static let mimeType: String   = "mime_type"
        static let contextKey: String = "context"
        static let wordPressMediaParentID = "parent_id"
    }

    private enum ParameterValue {
        static let mediaUploadName: String = "file"
        static let wordPressMediaFields = "id,date_gmt,slug,mime_type,source_url,alt_text,media_details,title"
    }
}
