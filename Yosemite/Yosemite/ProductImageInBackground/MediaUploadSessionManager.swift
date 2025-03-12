import Foundation
import Networking

public protocol MediaUploadSessionManagerDelegate: AnyObject {
    func mediaUploadSessionManager(_ manager: MediaUploadSessionManager,
                                   didCompleteUpload uploadID: String,
                                   withResult result: Result<Media, Error>)
}

/// Background upload specific errors
enum BackgroundUploadError: Error {
    case invalidRequestBody
    case invalidResponse
}

/// Session Manager for media upload in background
///
public final class MediaUploadSessionManager: NSObject {

    public let backgroundSessionIdentifier: String
    private lazy var backgroundSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: backgroundSessionIdentifier)
        config.sharedContainerIdentifier = "group.com.automattic.woocommerce"
        config.sessionSendsLaunchEvents = true
        config.isDiscretionary = false
        config.allowsCellularAccess = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    private var taskResponseData: [Int: Data] = [:]
    private var uploadCompletionClosures: [String: (Result<Media, Error>) -> Void] = [:]
    private var backgroundCompletionHandler: (() -> Void)?
    weak var delegate: MediaUploadSessionManagerDelegate?

    // StoresManager reference for accessing network and authentication for updating product with images and vice versa
    private var stores: StoresManager?

    // Storage to keep track of all uploads
    private let statusStorage: ProductImageStatusStorage

    public init(sessionIdentifier: String = "com.automattic.woocommerce.background.upload",
                statusStorage: ProductImageStatusStorage = ProductImageStatusStorage()) {
        self.backgroundSessionIdentifier = sessionIdentifier
        self.statusStorage = statusStorage
        super.init()
    }

    /// Sets the StoresManager instance for this MediaUploadSessionManager
    /// This is designed to be called after initialization to avoid dependency cycles
    /// - Parameter stores: The StoresManager instance to use
    public func setStores(_ stores: StoresManager) {
        self.stores = stores
    }

    public func uploadMedia(request: URLRequest,
                            updateProductIDRequest: URLRequest,
                            updateProductImagesRequest: URLRequest,
                            updateProductVariationImageRequest: URLRequest,
                            mediaItem: UploadableMedia,
                            uploadID: String,
                            siteID: Int64,
                            productID: Int64,
                            asset: ProductImageAssetType? = nil,
                            completion: @escaping (Result<Media, Error>) -> Void) {
        uploadCompletionClosures[uploadID] = completion

        // Extract authentication headers if present
        var authHeaders: [String: String]?
        if let authHeader = request.allHTTPHeaderFields?["Authorization"] {
            authHeaders = ["Authorization": authHeader]
        } else if let allHeaders = request.allHTTPHeaderFields {
            // Use all headers in case Authorization is named differently
            authHeaders = allHeaders
        }

        // Update status to uploading if we have an asset
        if let asset = asset {
            let status = ProductImageStatus.uploading(asset: asset,
                                                      siteID: siteID,
                                                      productID: .product(id: productID))
            statusStorage.updateStatus(status)
        }

        // Continue with upload
        guard let httpBody = request.httpBody else {
            let error = BackgroundUploadError.invalidRequestBody
            handleUploadFailure(uploadID: uploadID, error: error)
            return
        }

        do {
            // Create temp file with proper extension from mediaItem
            let tempDirectory = FileManager.default.temporaryDirectory
            let tempFileURL = tempDirectory.appendingPathComponent(mediaItem.filename)
            try httpBody.write(to: tempFileURL)

            // Upload using temp file
            var modifiedRequest = request
            modifiedRequest.httpBody = nil

            let task = backgroundSession.uploadTask(with: modifiedRequest, fromFile: tempFileURL)
            task.taskDescription = uploadID + (authHeaders != nil ? "|auth=\(encodeHeaders(authHeaders!))" : "")
            task.resume()

            // Cleanup temp file
            DispatchQueue.main.async {
                try? FileManager.default.removeItem(at: tempFileURL)
            }
        } catch {
            DDLogError("⛔️ MediaUploadSessionManager-[UploadMedia]- Failed creating temp file for upload media (\(uploadID)): \(error)")
            handleUploadFailure(uploadID: uploadID, error: error)
        }
    }

    /// Updates the product ID for a media item after upload using background URLSession
    ///
    /// - Parameters:
    ///   - siteID: The site ID
    ///   - productID: The product ID to associate with the media
    ///   - mediaID: The uploaded media ID
    ///   - request: The request template to use for updating the product ID
    ///
    func updateProductID(siteID: Int64, productID: Int64, mediaID: Int64, request: URLRequest) {
        // Generate a unique identifier for this task with structured data that can be parsed later
        let taskID = "updateProductID-\(siteID)-\(productID)-\(mediaID)"

        DDLogDebug("MediaUploadSessionManager-[UpdateProductID]- Starting update for media \(mediaID) with product \(productID)")

        // Extract authentication headers if present
        var authHeaders: [String: String]?
        if let authHeader = request.allHTTPHeaderFields?["Authorization"] {
            authHeaders = ["Authorization": authHeader]
        } else if let allHeaders = request.allHTTPHeaderFields {
            authHeaders = allHeaders
        }

        // Create a copy of the request with the mediaID appended to the URL
        var updatedRequest = request
        if let originalURL = request.url {
            let urlString = originalURL.absoluteString
            let updatedURLString = urlString.hasSuffix("/") ? "\(urlString)\(mediaID)" : "\(urlString)/\(mediaID)"
            if let updatedURL = URL(string: updatedURLString) {
                updatedRequest.url = updatedURL
            } else {
                DDLogError("⛔️ MediaUploadSessionManager-[UpdateProductID]- Failed to create URL with appended mediaID")
                return
            }
        }

        let task = backgroundSession.dataTask(with: updatedRequest)
        task.taskDescription = taskID + (authHeaders != nil ? "|auth=\(encodeHeaders(authHeaders!))" : "")
        task.resume()

        DDLogDebug("MediaUploadSessionManager-[UpdateProductID]- Started background task with ID: \(taskID) for media \(mediaID)")
    }

    /// Updates the product with the specified images using background URLSession
    ///
    /// - Parameters:
    ///   - siteID: The site ID
    ///   - productID: The product ID to update
    ///   - medias: Array of media to connect to the product
    ///   - request: The request template to use for updating the product images
    ///
    func updateProductImages(siteID: Int64, productID: Int64, medias: [Media], request: URLRequest) {
        // Generate a unique identifier for this task
        let taskID = "updateProductImages-\(siteID)-\(productID)"

        DDLogDebug("MediaUploadSessionManager-[UpdateProductImages]- Starting update for product \(productID) with \(medias.count) images")

        // Extract authentication headers if present
        var authHeaders: [String: String]?
        if let authHeader = request.allHTTPHeaderFields?["Authorization"] {
            authHeaders = ["Authorization": authHeader]
        } else if let allHeaders = request.allHTTPHeaderFields {
            authHeaders = allHeaders
        }

        // Convert mediaIDs to ProductImage objects
        let productImages = medias.map { media in
            ProductImage(imageID: media.mediaID,
                         dateCreated: media.date,
                         dateModified: media.date,
                         src: media.src,
                         name: media.name,
                         alt: media.alt)
        }

        // Create a copy of the request with updated body
        var updatedRequest = request

        do {
            // Create body with the images array
            let requestBody = ["images": productImages]
            let bodyData = try JSONEncoder().encode(requestBody)

            // Set the updated request body
            updatedRequest.httpBody = bodyData
            updatedRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

            // Create the data task
            let task = backgroundSession.uploadTask(withStreamedRequest: updatedRequest)
            task.taskDescription = taskID + (authHeaders != nil ? "|auth=\(encodeHeaders(authHeaders!))" : "")
            task.resume()

            DDLogDebug("MediaUploadSessionManager-[UpdateProductImages]- Started background task with ID: \(taskID) for product \(productID)")
        } catch {
            DDLogError("⛔️ MediaUploadSessionManager-[UpdateProductImages]- Failed to encode request body: \(error)")
        }
    }

    /// Updates a product variation with the specified image using background URLSession
    ///
    /// - Parameters:
    ///   - siteID: The site ID
    ///   - productID: The product ID that owns the variation
    ///   - variationID: The variation ID to update
    ///   - media: The media to connect to the variation
    ///   - request: The request template to use for updating the variation image
    ///
    func updateProductVariationImage(siteID: Int64, productID: Int64, variationID: Int64, media: Media, request: URLRequest) {
        // Generate a unique identifier for this task
        let taskID = "updateVariationImage-\(siteID)-\(productID)-\(variationID)"

        DDLogDebug("MediaUploadSessionManager-[UpdateProductVariationImage]- Starting update for variation \(variationID) with image from media \(media.mediaID)")

        // Extract authentication headers if present
        var authHeaders: [String: String]?
        if let authHeader = request.allHTTPHeaderFields?["Authorization"] {
            authHeaders = ["Authorization": authHeader]
        } else if let allHeaders = request.allHTTPHeaderFields {
            authHeaders = allHeaders
        }

        // Convert media to ProductImage
        let productImage = ProductImage(imageID: media.mediaID,
                                        dateCreated: media.date,
                                        dateModified: media.date,
                                        src: media.src,
                                        name: media.name,
                                        alt: media.alt)

        // Create a copy of the request with the variationID appended to the URL
        var updatedRequest = request
        if let originalURL = request.url {
            let urlString = originalURL.absoluteString
            let updatedURLString = urlString.hasSuffix("/") ? "\(urlString)\(variationID)" : "\(urlString)/\(variationID)"
            if let updatedURL = URL(string: updatedURLString) {
                updatedRequest.url = updatedURL
            } else {
                DDLogError("⛔️ MediaUploadSessionManager-[UpdateProductVariationImage]- Failed to create URL with appended variationID")
                return
            }
        }

        do {
            // Create body with the image object
            let requestBody = ["image": productImage]
            let bodyData = try JSONEncoder().encode(requestBody)

            // Set the updated request body
            updatedRequest.httpBody = bodyData
            updatedRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

            // Create the data task
            let task = backgroundSession.uploadTask(withStreamedRequest: updatedRequest)
            task.taskDescription = taskID + (authHeaders != nil ? "|auth=\(encodeHeaders(authHeaders!))" : "")
            task.resume()

            DDLogDebug("MediaUploadSessionManager-[UpdateProductVariationImage]- Started background task with ID: \(taskID) for variation \(variationID)")
        } catch {
            DDLogError("⛔️ MediaUploadSessionManager-[UpdateProductVariationImage]- Failed to encode request body: \(error)")
        }
    }

    public func handleBackgroundSessionCompletion(_ completionHandler: @escaping () -> Void) {
        backgroundCompletionHandler = completionHandler
    }
}

// MARK: - Utility Methods
private extension MediaUploadSessionManager {
    // Encodes headers to a string that can be stored in task description
    func encodeHeaders(_ headers: [String: String]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: headers),
              let encodedString = String(data: data, encoding: .utf8) else {
            return ""
        }
        return encodedString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
    }

    // Decodes headers from a string in task description
    func decodeHeaders(_ encodedString: String) -> [String: String]? {
        guard let decodedString = encodedString.removingPercentEncoding,
              let data = decodedString.data(using: .utf8),
              let headers = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return nil
        }
        return headers
    }

    func handleUploadFailure(uploadID: String, error: Error) {
        DDLogError("⛔️ MediaUploadSessionManager-[UploadFailure]- Upload failure for task (\(uploadID)): \(error.localizedDescription)")

        // Find the corresponding upload status
        let uploadingStatuses = statusStorage.getAllStatuses().filter { status in
            if case .uploading = status {
                return true
            }
            return false
        }

        // Update status to failure if we can find a matching status
        if let uploadStatus = uploadingStatuses.first(where: { $0.asset != nil }),
           let asset = uploadStatus.asset {

            // Update status to failure
            let failureStatus = ProductImageStatus.uploadFailure(
                asset: asset,
                error: error,
                siteID: uploadStatus.siteID,
                productID: uploadStatus.productOrVariationID
            )

            statusStorage.updateStatus(failureStatus)
        }

        DispatchQueue.main.async { [weak self] in
            if let self = self, let completion = self.uploadCompletionClosures[uploadID] {
                completion(.failure(error))
                self.uploadCompletionClosures.removeValue(forKey: uploadID)
            }
        }
    }

    func notifyCompletion(_ result: Result<Media, Error>, for uploadID: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            DDLogDebug("MediaUploadSessionManager-[Completion]- Notifying completion for task (\(uploadID)) with result: \(result)")
            if let completion = self.uploadCompletionClosures[uploadID] {
                completion(result)
                self.uploadCompletionClosures.removeValue(forKey: uploadID)
            }
            self.delegate?.mediaUploadSessionManager(self, didCompleteUpload: uploadID, withResult: result)
        }
    }
}

extension MediaUploadSessionManager: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession,
                           dataTask: URLSessionDataTask,
                           didReceive data: Data) {
        if let existingData = taskResponseData[dataTask.taskIdentifier] {
            taskResponseData[dataTask.taskIdentifier] = existingData + data
        } else {
            taskResponseData[dataTask.taskIdentifier] = data
        }
    }

    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didCompleteWithError error: Error?) {
        guard let taskDescription = task.taskDescription else {
            DDLogDebug("MediaUploadSessionManager-[NoTaskDescription]- Task completed without a task description. Task identifier: \(task.taskIdentifier)")
            return
        }

        // Extract auth headers from task description if available
        let components = taskDescription.components(separatedBy: "|auth=")
        let uploadID = components[0]
        let authHeaders: [String: String]? = components.count > 1 ? decodeHeaders(components[1]) : nil

        defer {
            taskResponseData.removeValue(forKey: task.taskIdentifier)
        }

        if let error = error {
            DDLogError("⛔️ MediaUploadSessionManager-[MediaUpload]- Upload failure for task (\(uploadID)): encountered error: \(error.localizedDescription)")

            // Check task type by ID prefix
            if uploadID.starts(with: "updateProductID-") {
                DDLogError("⛔️ MediaUploadSessionManager-[UpdateProductID]- Failed to update product ID: \(error.localizedDescription)")
            } else if uploadID.starts(with: "updateProductImages-") {
                DDLogError("⛔️ MediaUploadSessionManager-[UpdateProductImages]- Failed to update product images: \(error.localizedDescription)")
            } else if uploadID.starts(with: "updateVariationImage-") {
                DDLogError("⛔️ MediaUploadSessionManager-[UpdateProductVariationImage]- Failed to update variation image: \(error.localizedDescription)")
            } else {
                handleUploadFailure(uploadID: uploadID, error: error)
            }
            return
        }

        guard let httpResponse = task.response as? HTTPURLResponse else {
            DDLogError("⛔️ MediaUploadSessionManager-[MediaUpload]- Upload failure for task (\(uploadID)):" +
                       " response is not a valid HTTPURLResponse. Actual response: \(String(describing: task.response))")
            handleUploadFailure(uploadID: uploadID, error: BackgroundUploadError.invalidResponse)
            return
        }

        guard let data = taskResponseData[task.taskIdentifier] else {
            DDLogError("⛔️ MediaUploadSessionManager-[MediaUpload]- Upload failure for task (\(uploadID)):" +
                       " missing response data for task with identifier \(task.taskIdentifier)")
            handleUploadFailure(uploadID: uploadID, error: BackgroundUploadError.invalidResponse)
            return
        }

        if !(200...299).contains(httpResponse.statusCode) {
            DDLogError("⛔️ MediaUploadSessionManager-[MediaUpload]- Upload failure for task (\(uploadID)):" +
                       " unexpected HTTP status code \(httpResponse.statusCode). Full response: \(httpResponse) Headers: \(httpResponse.allHeaderFields)")
            handleUploadFailure(uploadID: uploadID, error: BackgroundUploadError.invalidResponse)
            return
        }

        // Check task type by ID prefix for successful responses
        if uploadID.starts(with: "updateProductID-") {
            // Log success for updateProductID
            if let jsonString = String(data: data, encoding: .utf8) {
                DDLogDebug("MediaUploadSessionManager-[UpdateProductID]- Successful update response: \(jsonString)")
            }
            return
        } else if uploadID.starts(with: "updateProductImages-") {
            // Log success for updateProductImages
            if let jsonString = String(data: data, encoding: .utf8) {
                DDLogDebug("MediaUploadSessionManager-[UpdateProductImages]- Successful update response: \(jsonString)")
            }
            return
        } else if uploadID.starts(with: "updateVariationImage-") {
            // Log success for updateVariationImage
            if let jsonString = String(data: data, encoding: .utf8) {
                DDLogDebug("MediaUploadSessionManager-[UpdateProductVariationImage]- Successful update response: \(jsonString)")
            }
            return
        }

        // Handle media upload task completion
        if let jsonString = String(data: data, encoding: .utf8) {
            DDLogDebug("MediaUploadSessionManager-[MediaUpload]- Successful upload response: \(jsonString)")
        } else {
            DDLogError("⛔️ MediaUploadSessionManager-[MediaUpload]- " +
                       "Failed to convert response data to JSON string for task (\(uploadID))")
        }

        let mapper = WordPressMediaMapper()
        do {
            let wpMedia = try mapper.map(response: data)
            let finalMedia = wpMedia.toMedia()
            notifyCompletion(.success(finalMedia), for: uploadID)
        } catch {
            DDLogError("⛔️ MediaUploadSessionManager-[ResponseMapping]- Upload failure for task (\(uploadID)): error mapping media: \(error.localizedDescription)")
            handleUploadFailure(uploadID: uploadID, error: error)
        }
    }

    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async { [weak self] in
            DDLogDebug("MediaUploadSessionManager- Background URL session did finish events. Invoking completion handler.")
            self?.backgroundCompletionHandler?()
            self?.backgroundCompletionHandler = nil
        }
    }
}
