import Foundation
import Alamofire

/// Protocol for `MediaRemote` mainly used for mocking.
public protocol MediaRemoteProtocol {
    func loadMedia(siteID: Int64,
                   mediaID: Int64,
                   completion: @escaping (Result<WordPressMedia, Error>) -> Void)
    func loadMediaLibrary(siteID: Int64,
                          productID: Int64?,
                          imagesOnly: Bool,
                          pageNumber: Int,
                          pageSize: Int,
                          completion: @escaping (Result<[WordPressMedia], Error>) -> Void)
    func uploadMedia(siteID: Int64,
                     productID: Int64,
                     mediaItem: UploadableMedia,
                     completion: @escaping (Result<WordPressMedia, Error>) -> Void)
    func updateProductID(siteID: Int64,
                         productID: Int64,
                         mediaID: Int64,
                         completion: @escaping (Result<WordPressMedia, Error>) -> Void)

    /// Creates a URLRequest for uploading media in background
    func uploadMediaRequest(siteID: Int64,
                            productID: Int64,
                            mediaItem: UploadableMedia) async throws -> URLRequest
}

/// Media: Remote Endpoints
///
public class MediaRemote: Remote, MediaRemoteProtocol {
    /// Loads media from the site's WP Media library
    /// API reference - https://developer.wordpress.org/rest-api/reference/media/#retrieve-a-media-item
    ///
    /// - Parameters:
    ///   - siteID: site ID for which to load Media
    ///   - mediaID: ID of the Media to load
    ///   - completion: Closure to be executed upon completion.
    ///
    public func loadMedia(siteID: Int64,
                          mediaID: Int64,
                          completion: @escaping (Result<WordPressMedia, Error>) -> Void) {
        let parameters: [String: Any] = [
            ParameterKey.fieldsWordPressSite: ParameterValue.wordPressMediaFields,
        ].compactMapValues { $0 }

        let path = "sites/\(siteID)/media/\(mediaID)"
        do {
            let request = try DotcomRequest(wordpressApiVersion: .wpMark2,
                                            method: .get,
                                            path: path,
                                            parameters: parameters,
                                            availableAsRESTRequest: true)
            let mapper = WordPressMediaMapper()

            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    /// Loads an array of media from the site's WP Media Library via WordPress site API.
    /// API reference: https://developer.wordpress.org/rest-api/reference/media/#list-media
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll load the media from.
    ///   - productID: Loads media attached to a specific product ID. Loads all media if nil.
    ///   - imagesOnly: Whether only images should be loaded.
    ///   - pageNumber: The index of the page of media data to load from, starting from 1.
    ///   - pageSize: The number of media items to return.
    ///   - completion: Closure to be executed upon completion.
    public func loadMediaLibrary(siteID: Int64,
                                 productID: Int64? = nil,
                                 imagesOnly: Bool,
                                 pageNumber: Int = Default.pageNumber,
                                 pageSize: Int = 25,
                                 completion: @escaping (Result<[WordPressMedia], Error>) -> Void) {
        let parameters: [String: Any] = [
            ParameterKey.dotOrgPageSize: pageSize,
            ParameterKey.pageNumber: pageNumber,
            ParameterKey.fieldsWordPressSite: ParameterValue.wordPressMediaFields,
            ParameterKey.mediaType: imagesOnly ? "image" : nil,
            ParameterKey.wordPressMediaParent: productID
        ].compactMapValues { $0 }

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

    /// Uploads a media item in the local file system to the WordPress site via WordPress site API.
    /// The API does not support multiple media items unlike the WPCOM version in `uploadMedia`.
    /// API reference: https://developer.wordpress.org/rest-api/reference/media/#create-a-media-item
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll upload the media to.
    ///   - productID: Product for which the media items are first added to.
    ///   - mediaItem: The media item to upload.
    ///   - completion: Closure to be executed upon completion.
    public func uploadMedia(siteID: Int64,
                            productID: Int64,
                            mediaItem: UploadableMedia,
                            completion: @escaping (Result<WordPressMedia, Error>) -> Void) {
        let formParameters: [String: String] = [
            ParameterKey.wordPressMediaPostID: "\(productID)",
            ParameterKey.fieldsWordPressSite: ParameterValue.wordPressMediaFields,
            ParameterKey.wordPressAltText: mediaItem.altText
        ].compactMapValues { $0 }
        let path = "sites/\(siteID)/media"
        do {
            let request = try DotcomRequest(wordpressApiVersion: .wpMark2,
                                            method: .post,
                                            path: path,
                                            availableAsRESTRequest: true)
            let mapper = WordPressMediaMapper()

            enqueueMultipartFormDataUpload(request, mapper: mapper, multipartFormData: { multipartFormData in
                formParameters.forEach { (key, value) in
                    multipartFormData.append(Data(value.utf8), withName: key)
                }

                multipartFormData.append(mediaItem.localURL,
                                         withName: ParameterValue.mediaUploadName,
                                         fileName: mediaItem.filename,
                                         mimeType: mediaItem.mimeType)
            }, completion: completion)
        } catch {
            completion(.failure(error))
        }
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
    public func updateProductID(siteID: Int64,
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

    public func uploadMediaRequest(siteID: Int64,
                                   productID: Int64,
                                   mediaItem: UploadableMedia) async throws -> URLRequest {

        let boundary = UUID().uuidString
        let path = "sites/\(siteID)/media"

        let dotcomRequest = try DotcomRequest(wordpressApiVersion: .wpMark2,
                                            method: .post,
                                            path: path,
                                            parameters: nil,
                                            availableAsRESTRequest: true)

        guard let network = network as? AlamofireNetwork else {
            throw NetworkError.unacceptableStatusCode(statusCode: 500, response: nil)
        }

        let converter = RequestConverter(credentials: network.credentials)
        var request = try converter.convert(dotcomRequest).asURLRequest()

        // Authenticate the request if we have credentials
        if let credentials = network.credentials {
            request = try DefaultRequestAuthenticator(credentials: credentials).authenticate(request)
        } else {
            throw NetworkError.unacceptableStatusCode(statusCode: 401, response: nil)
        }

        // Add multipart content type
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Add form data
        var body = Data()
        func append(_ string: String) {
            body.append(string.data(using: .utf8)!)
        }

        let params: [String: String] = [
            ParameterKey.wordPressMediaPostID: "\(productID)",
            ParameterKey.fieldsWordPressSite: ParameterValue.wordPressMediaFields,
            ParameterKey.wordPressAltText: mediaItem.altText ?? ""
        ]

        //Add parameters
        for (key, value) in params {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            append("\(value)\r\n")
        }

        // Add file data
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"file\"; filename=\"\(mediaItem.filename)\"\r\n")
        append("Content-Type: \(mediaItem.mimeType)\r\n\r\n")
        body.append(try Data(contentsOf: mediaItem.localURL))
        append("\r\n")
        append("--\(boundary)--\r\n")

        request.httpBody = body
        request.httpMethod = "POST"
        return request
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
        // For dotcom API usage, we want to use "number"
        // https://developer.wordpress.com/docs/api/1.2/get/sites/%24site/media/
        static let dotComPageSize: String = "number"
        // For dotorg API usage, we want to use "per_page"
        // https://developer.wordpress.org/rest-api/reference/media/#arguments
        static let dotOrgPageSize: String = "per_page"
        static let wordPressMediaPostID: String = "post"
        static let altText: String = "alt"
        static let wordPressAltText: String = "alt_text"
        static let fields: String     = "fields"
        static let fieldsWordPressSite: String = "_fields"
        // For dotcom API usage, we want to use "mime_type"
        // https://developer.wordpress.com/docs/api/1.2/get/sites/%24site/media/
        static let mimeType: String   = "mime_type"
        // For dotorg API usage, we want to use "media_type"
        // https://developer.wordpress.org/rest-api/reference/media/#list-media
        static let mediaType: String = "media_type"
        static let postID: String   = "post_ID"
        static let contextKey: String = "context"
        static let wordPressMediaParentID = "parent_id"
        static let wordPressMediaParent = "parent"
    }

    private enum ParameterValue {
        static let mediaUploadName: String = "file"
        static let wordPressMediaFields = "id,date_gmt,slug,mime_type,source_url,alt_text,media_details,title"
    }
}
