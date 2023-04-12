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

    func replaceBackground(image: ProductImage, options: SceneOptions) async throws -> String
}

public struct SceneOptions {
    public init(backgroundDescription: String, scale: Double) {
        self.backgroundDescription = backgroundDescription
        self.scale = scale
    }

    public let backgroundDescription: String
    public let scale: Double
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

    private struct ImageBackgroundReplacementResponse: Decodable {
        let url: String
        let isBadOutput: Bool

        private enum CodingKeys: String, CodingKey {
            case url
            case isBadOutput = "bad_output"
        }
    }

    private struct BackgroundReplacementResponse: Decodable {
        let data: [String: [ImageBackgroundReplacementResponse]]
    }

    /// Replaces the background of an image based on the given scene options.
    /// - Parameters:
    ///   - image: Product image whose background is to be replaced.
    ///   - options: Options for the background scene.
    /// - Returns: Image URL.
    public func replaceBackground(image: ProductImage, options: SceneOptions) async throws -> String {
        let url = "https://api.scale.com/v1/catalog/forge/generations/scene_creation"
        let headers = [
            "authorization": ""
        ]
        // Ref: https://docs.scale.com/reference/forge-scene-creation
        let parameters: [String: Any] = [
            "product_images": [
                image.src
            ],
            // Resolution of the generated images. Note that choosing HD will increase the latency of the endpoint by a few seconds and the resolution output can only be as high as the resolution of the input images. When choosing SD, the resolution of the generated images will be at most 512x512.
            "resolution": "SD", // SD|HD
            // Location of the object relative to the background
            "scene_preposition": "in", // in|on|among
            // [required] Description of the background you want to generate with AI. Fill in the blank: I want to see my product in/on <scene>.
            "scene": options.backgroundDescription,
            // The percentage of the total frame that the width of the object should be. For example, scale=0.5 corresponds to the object taking half of the total frame width.
            "scale": options.scale,
            // Ref: https://docs.scale.com/reference/forge-acceptable-background-modifiers
            "modifiers": [
//                [
//                    "title": "Time of day",
//                    // Sunrise, Noon, Afternoon, Sunset, Night
//                    "selected_values": [
////                        "Wide angle"
//                    ]
//                ],
                [
                    "title": "Perspective",
                    // Close up, Wide angle, Top down, Straight on
                    "selected_values": [
                        "Wide angle"
                    ]
                ],
//                [
//                    "title": "Filters",
//                    // Natural light, Front lit, Back lit, Top lit, Shallow depth of field, Deep depth of field, Tilt shift, HDR, Long Exposure, Macro lens, Light leak, Polaroid
//                    "selected_values": [
//                        "Front lit"
//                    ]
//                ],
//                [
//                    "title": "Placement",
//                    // Outdoors, Indoors
//                    "selected_values": [
////                        "Indoors"
//                    ]
//                ],
//                [
//                    "title": "Vibe",
//                    // Moody, Retro, Cheerful, Foggy, Warm, Cool, Dramatic
//                    "selected_values": [
////                        "Front lit"
//                    ]
//                ],
//                [
//                    "title": "Palette",
//                    // [multi-select enabled] Tan, Yellow, Gold, Orange, Red, Maroon, Pink, Violet, Indigo, Green, Skyblue, Blue, White, Silver, Gray, Offwhite, Black
//                    "selected_values": [
////                        "Indoors"
//                    ]
//                ]
            ]
        ]
        let request = ExternalRequest(method: .post, url: url, parameters: parameters, headers: headers)
        let result: BackgroundReplacementResponse = try await enqueue(request)
        // TODO-jc: better error handling
        guard let imageResult = result.data.first?.value.first else {
            throw NSError(domain: "scene generation", code: 1)
        }
        guard imageResult.isBadOutput == false else {
            throw NSError(domain: "scene generation", code: 2)
        }
        return imageResult.url
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
