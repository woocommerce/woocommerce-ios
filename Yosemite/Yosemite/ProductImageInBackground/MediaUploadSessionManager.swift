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

    /// Updates the product ID for a media item after upload
    ///
    /// - Parameters:
    ///   - siteID: The site ID
    ///   - productID: The product ID to associate with the media
    ///   - mediaID: The uploaded media ID
    ///   - completion: A closure to be executed upon completion
    ///
    func updateProductID(siteID: Int64, productID: Int64, mediaID: Int64, completion: @escaping (Result<Media, Error>) -> Void) {
        guard let stores = stores else {
            let error = NSError(domain: "MediaUploadSessionManager", code: NSFeatureUnsupportedError, userInfo: [NSLocalizedDescriptionKey: "StoresManager not configured"])
            DDLogError("⛔️ MediaUploadSessionManager-[UpdateProductID]- Error: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }

        stores.dispatch(MediaAction.updateProductID(siteID: siteID, productID: productID, mediaID: mediaID, onCompletion: completion))
    }

    /// Updates the product with the specified images
    ///
    /// - Parameters:
    ///   - siteID: The site ID
    ///   - productID: The product ID to update
    ///   - medias: Array of media to connect to the product
    ///   - completion: A closure to be executed upon completion
    ///
    func updateProductImages(siteID: Int64, productID: Int64, medias: [Media], completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let stores = stores else {
            let error = NSError(domain: "MediaUploadSessionManager", code: NSFeatureUnsupportedError, userInfo: [NSLocalizedDescriptionKey: "StoresManager not configured"])
            DDLogError("⛔️ MediaUploadSessionManager-[UpdateProductImages]- Error: \(error.localizedDescription)")
            completion(.failure(error))
            return
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

        stores.dispatch(ProductAction.updateProductImages(siteID: siteID, productID: productID, images: productImages, onCompletion: { result in
            switch result {
            case .success(let product):
                completion(.success(true))
            case .failure(let error):
                completion(.failure(error))
            }
        }))
    }

    /// Updates a product variation with the specified image
    ///
    /// - Parameters:
    ///   - siteID: The site ID
    ///   - productID: The product ID that owns the variation
    ///   - variationID: The variation ID to update
    ///   - media: The media to connect to the variation
    ///   - completion: A closure to be executed upon completion
    ///
    func updateProductVariationImage(siteID: Int64, productID: Int64, variationID: Int64, media: Media, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let stores = stores else {
            let error = NSError(domain: "MediaUploadSessionManager", code: NSFeatureUnsupportedError, userInfo: [NSLocalizedDescriptionKey: "StoresManager not configured"])
            DDLogError("⛔️ MediaUploadSessionManager-[UpdateProductVariationImage]- Error: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }

        // Convert media to ProductImage
        let productImage = ProductImage(imageID: media.mediaID,
                                        dateCreated: media.date,
                                        dateModified: media.date,
                                        src: media.src,
                                        name: media.name,
                                        alt: media.alt)

        stores.dispatch(ProductVariationAction.updateProductVariationImage(siteID: siteID,
                                                                           productID: productID,
                                                                           variationID: variationID,
                                                                           image: productImage) { result in
            switch result {
            case .success(let variation):
                completion(.success(true))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    /// Updates a product with the uploaded media in sequence:
    /// 1. Links the media to the product ID using updateProductID
    /// 2. Updates the product images using updateProductImages
    /// 3. Updates the image status in storage
    ///
    /// - Parameters:
    ///   - siteID: The site ID
    ///   - productID: The product ID to update
    ///   - media: The uploaded media to associate with the product
    ///   - asset: Optional asset type that was used for the upload
    ///   - completion: A closure to be executed upon completion
    ///
    public func updateProductWithMedia(siteID: Int64,
                                      productID: Int64,
                                      media: Media,
                                      asset: ProductImageAssetType? = nil,
                                      completion: @escaping (Result<Bool, Error>) -> Void) {
        DDLogDebug("MediaUploadSessionManager-[UpdateProductWithMedia]- Starting update sequence for product \(productID) with media \(media.mediaID)")

        // First, update the product ID for the media
        updateProductID(siteID: siteID, productID: productID, mediaID: media.mediaID) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let updatedMedia):
                DDLogDebug("MediaUploadSessionManager-[UpdateProductWithMedia]- Successfully linked media \(updatedMedia.mediaID) to product \(productID)")

                // Now, update the product with the image
                self.updateProductImages(siteID: siteID, productID: productID, medias: [updatedMedia]) { [weak self] imageResult in
                    guard let self = self else { return }

                    switch imageResult {
                    case .success:
                        DDLogDebug("MediaUploadSessionManager-[UpdateProductWithMedia]- Successfully updated product \(productID) with image from media \(updatedMedia.mediaID)")

                        // Update the status in storage to indicate the image is now remote and associated with the product
                        let productImage = ProductImage(imageID: updatedMedia.mediaID,
                                                      dateCreated: updatedMedia.date,
                                                      dateModified: updatedMedia.date,
                                                      src: updatedMedia.src,
                                                      name: updatedMedia.name,
                                                      alt: updatedMedia.alt)

                        let status = ProductImageStatus.remote(image: productImage, siteID: siteID, productID: .product(id: productID))
                        self.statusStorage.updateStatus(status)

                        // If we have an asset reference, remove any uploading or failure statuses for this asset
                        if let asset = asset {
                            self.statusStorage.removeStatus(where: { status in
                                if case .uploading(let statusAsset, let statusSiteID, _) = status {
                                    return statusAsset == asset && statusSiteID == siteID
                                }
                                if case .uploadFailure(let statusAsset, _, let statusSiteID, _) = status {
                                    return statusAsset == asset && statusSiteID == siteID
                                }
                                return false
                            })
                        }

                        completion(.success(true))

                    case .failure(let error):
                        DDLogError("⛔️ MediaUploadSessionManager-[UpdateProductWithMedia]- Failed to update product images: \(error)")
                        completion(.failure(error))
                    }
                }

            case .failure(let error):
                DDLogError("⛔️ MediaUploadSessionManager-[UpdateProductWithMedia]- Failed to link media to product: \(error)")
                completion(.failure(error))
            }
        }
    }

    /// Updates a product variation with the uploaded media in sequence:
    /// 1. Links the media to the product ID using updateProductID
    /// 2. Updates the variation image using updateProductVariationImage
    /// 3. Updates the image status in storage
    ///
    /// - Parameters:
    ///   - siteID: The site ID
    ///   - productID: The product ID that owns the variation
    ///   - variationID: The variation ID to update
    ///   - media: The uploaded media to associate with the variation
    ///   - asset: Optional asset type that was used for the upload
    ///   - completion: A closure to be executed upon completion
    ///
    public func updateProductVariationWithMedia(siteID: Int64,
                                               productID: Int64,
                                               variationID: Int64,
                                               media: Media,
                                               asset: ProductImageAssetType? = nil,
                                               completion: @escaping (Result<Bool, Error>) -> Void) {
        DDLogDebug("MediaUploadSessionManager-[UpdateProductVariationWithMedia]- Starting update sequence for variation \(variationID) with media \(media.mediaID)")

        // First, update the product ID for the media
        updateProductID(siteID: siteID, productID: productID, mediaID: media.mediaID) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let updatedMedia):
                DDLogDebug("MediaUploadSessionManager-[UpdateProductVariationWithMedia]- Successfully linked media \(updatedMedia.mediaID) to product \(productID)")

                // Now, update the variation with the image
                self.updateProductVariationImage(siteID: siteID, productID: productID, variationID: variationID, media: updatedMedia) { [weak self] imageResult in
                    guard let self = self else { return }

                    switch imageResult {
                    case .success:
                        DDLogDebug("MediaUploadSessionManager-[UpdateProductVariationWithMedia]- Successfully updated variation \(variationID) with image from media \(updatedMedia.mediaID)")

                        // Update the status in storage to indicate the image is now remote and associated with the variation
                        let productImage = ProductImage(imageID: updatedMedia.mediaID,
                                                      dateCreated: updatedMedia.date,
                                                      dateModified: updatedMedia.date,
                                                      src: updatedMedia.src,
                                                      name: updatedMedia.name,
                                                      alt: updatedMedia.alt)

                        let status = ProductImageStatus.remote(image: productImage,
                                                              siteID: siteID,
                                                              productID: .variation(productID: productID, variationID: variationID))

                        // If we have an asset reference, remove any uploading or failure statuses for this asset
                        if let asset = asset {
                            self.statusStorage.removeStatus(where: { status in
                                if case .uploading(let statusAsset, let statusSiteID, _) = status {
                                    return statusAsset == asset && statusSiteID == siteID
                                }
                                if case .uploadFailure(let statusAsset, _, let statusSiteID, _) = status {
                                    return statusAsset == asset && statusSiteID == siteID
                                }
                                return false
                            })
                        }

                        completion(.success(true))

                    case .failure(let error):
                        DDLogError("⛔️ MediaUploadSessionManager-[UpdateProductVariationWithMedia]- Failed to update variation image: \(error)")
                        completion(.failure(error))
                    }
                }

            case .failure(let error):
                DDLogError("⛔️ MediaUploadSessionManager-[UpdateProductVariationWithMedia]- Failed to link media to product: \(error)")
                completion(.failure(error))
            }
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
            handleUploadFailure(uploadID: uploadID, error: error)
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

        // Use MediaMapper to parse response
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
