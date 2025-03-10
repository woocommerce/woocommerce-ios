import Foundation

public protocol MediaUploadSessionManagerDelegate: AnyObject {
    func mediaUploadSessionManager(_ manager: MediaUploadSessionManager,
                                   didCompleteUpload uploadID: String,
                                   withResult result: Result<Media, Error>)
}

/// Background upload specific errors
enum BackgroundUploadError: Error {
    case invalidRequestBody
    case invalidResponse
    case decodingError
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

    // Storage to keep track of all uploads
    private let statusStorage: ProductImageStatusStorage

    public init(sessionIdentifier: String = "com.automattic.woocommerce.background.upload",
                statusStorage: ProductImageStatusStorage = ProductImageStatusStorage()) {
        self.backgroundSessionIdentifier = sessionIdentifier
        self.statusStorage = statusStorage
        super.init()
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

    /// Encodes headers to a string that can be stored in task description
    private func encodeHeaders(_ headers: [String: String]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: headers),
              let encodedString = String(data: data, encoding: .utf8) else {
            return ""
        }
        return encodedString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
    }

    /// Decodes headers from a string in task description
    private func decodeHeaders(_ encodedString: String) -> [String: String]? {
        guard let decodedString = encodedString.removingPercentEncoding,
              let data = decodedString.data(using: .utf8),
              let headers = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return nil
        }
        return headers
    }

    /// Updates the product ID for a media item after successful upload
    private func updateProductIDForMedia(uploadID: String, wpMedia: WordPressMedia, authHeaders: [String: String]?) {
        // Find the corresponding upload status
        let uploadingStatuses = statusStorage.getAllStatuses().filter { status in
            if case .uploading = status {
                return true
            }
            return false
        }

        guard let uploadStatus = uploadingStatuses.first else {
            DDLogDebug("MediaUploadSessionManager-[UpdateProductID]- No upload status found for upload ID: \(uploadID)")
            return
        }

        let siteID = uploadStatus.siteID
        let productOrVariationID = uploadStatus.productOrVariationID
        let assetType = uploadStatus.asset

        // Extract the productID, which is the actual post ID to use
        let productID: Int64
        switch productOrVariationID {
        case .product(let id):
            productID = id
        case .variation(let parentID, _):
            productID = parentID
        }

        // Create a request to update the product association
        let path = "sites/\(siteID)/media/\(wpMedia.mediaID)"
        let parameters = [
            "post": "\(productID)",
            "_fields": "id,date_gmt,slug,mime_type,source_url,alt_text,media_details,title"
        ]

        var request = URLRequest(url: URL(string: "https://public-api.wordpress.com/rest/v1.1/\(path)")!)
        request.httpMethod = "POST"

        // Add authentication headers from the original request
        if let headers = authHeaders {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        // Add query parameters
        var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
        components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        request.url = components.url

        // The authentication should be handled by the background session
        let task = backgroundSession.dataTask(with: request)
        // Store authentication headers in task description for later use, using a specific prefix to differentiate updateProductID calls
        let taskDescription = "updateProductID-\(uploadID)" + (authHeaders != nil ? "|auth=\(encodeHeaders(authHeaders!))" : "")
        task.taskDescription = taskDescription
        task.resume()

        // Update the status to remote FIRST
        if let asset = assetType {
            let productImage = ProductImage(
                imageID: wpMedia.mediaID,
                dateCreated: wpMedia.date,
                dateModified: nil,
                src: wpMedia.src,
                name: wpMedia.title?.rendered,
                alt: wpMedia.alt)

            let remoteStatus = ProductImageStatus.remote(
                image: productImage,
                siteID: siteID,
                productID: productOrVariationID
            )

            // Remove uploading status and add remote status
            statusStorage.removeStatus(where: { existingStatus in
                if case .uploading(let uploadingAsset, let uploadingSiteID, let uploadingProductID) = existingStatus,
                   uploadingAsset == asset &&
                   uploadingSiteID == siteID &&
                   uploadingProductID == productOrVariationID {
                    return true
                }
                return false
            })

            statusStorage.addStatus(remoteStatus)
            
            // THEN wait until the association request completes before checking if all uploads are done
        }
    }

    /// Extracts a product ID from a ProductOrVariationID
    private func extractProductID(from productOrVariationID: ProductOrVariationID) -> Int64? {
        switch productOrVariationID {
        case .product(let id):
            return id
        case .variation(let parentID, _):
            return parentID
        }
    }

    /// Checks if all uploads for a product are complete and updates the product if needed
    private func checkAndUpdateProductIfAllUploadsComplete(productID: Int64, siteID: Int64, authHeaders: [String: String]?) {
        // Get all statuses for this product again - we want the most up-to-date information
        let allStatuses = statusStorage.getAllStatuses()

        // Filter for this specific product
        let productStatuses = allStatuses.filter { status in
            let statusProductID: Int64? = {
                switch status.productOrVariationID {
                case .product(let id): return id
                case .variation(let parentID, _): return parentID
                }
            }()

            return status.siteID == siteID && statusProductID == productID
        }

        // Check if there are any uploading statuses still in progress for this product
        let hasUploadsInProgress = productStatuses.contains { status in
            if case .uploading = status {
                return true
            }
            return false
        }

        // If there are no more uploading statuses, and we haven't already processed this product,
        // update the product with all images
        if !hasUploadsInProgress {
            DDLogDebug("MediaUploadSessionManager-[CheckUploads]- All uploads completed or failed for product \(productID). Processing...")
            
            // Get remote images - these are the successfully uploaded ones
            let remoteImages = productStatuses.compactMap { status -> ProductImage? in
                if case .remote(let image, _, _) = status {
                    return image
                }
                return nil
            }
            
            // Get failed uploads for logging
            let failedUploads = productStatuses.filter { if case .uploadFailure = $0 { return true }; return false }
            if !failedUploads.isEmpty {
                DDLogInfo("MediaUploadSessionManager-[CheckUploads]- Product \(productID) had \(failedUploads.count) failed uploads")
            }

            // Only proceed if we have at least one successfully uploaded image
            if !remoteImages.isEmpty {
                DDLogDebug("MediaUploadSessionManager-[CheckUploads]- Updating product \(productID) with \(remoteImages.count) images")
                
                // Add an additional log to track when this happens
                DDLogInfo("🔄 MediaUploadSessionManager-[CheckUploads]- INITIATING PRODUCT UPDATE for product \(productID) with \(remoteImages.count) images. Total statuses: \(productStatuses.count), Uploads in progress: \(hasUploadsInProgress)")
                
                // Update the product with the images we have so far
                updateProductWithImages(siteID: siteID, productID: productID, images: remoteImages, authHeaders: authHeaders)
                
                // Clean up all statuses for this product after initiating the update
                statusStorage.removeStatus(where: { status in
                    let statusProductID: Int64? = {
                        switch status.productOrVariationID {
                        case .product(let id): return id
                        case .variation(let parentID, _): return parentID
                        }
                    }()
                    
                    return status.siteID == siteID && statusProductID == productID
                })
            } else if !failedUploads.isEmpty {
                DDLogInfo("MediaUploadSessionManager-[CheckUploads]- All uploads for product \(productID) failed. Not updating product.")
                // Clean up all failed statuses since we won't be updating the product
                statusStorage.removeStatus(where: { status in
                    if case .uploadFailure = status {
                        let statusProductID: Int64? = {
                            switch status.productOrVariationID {
                            case .product(let id): return id
                            case .variation(let parentID, _): return parentID
                            }
                        }()
                        
                        return status.siteID == siteID && statusProductID == productID
                    }
                    return false
                })
            }
        } else {
            DDLogDebug("MediaUploadSessionManager-[CheckUploads]- Some uploads still in progress for product \(productID). Not updating yet.")
        }
    }

    /// Updates the product with all uploaded images
    private func updateProductWithImages(siteID: Int64, productID: Int64, images: [ProductImage], authHeaders: [String: String]?) {
        // Don't proceed if we don't have authentication headers
        guard let headers = authHeaders else {
            DDLogError("⛔️ MediaUploadSessionManager-[UpdateProductWithImages]- Cannot update product \(productID) at site \(siteID): missing auth headers")
            return
        }

        // Create the request body - use the same format as in ProductsRemote
        let imagesData = images.map { image -> [String: Any] in
            var imageDict: [String: Any] = [
                "id": image.imageID
            ]

            if let name = image.name {
                imageDict["name"] = name
            }

            if let alt = image.alt {
                imageDict["alt"] = alt
            }

            // Add other fields that might be expected by the API
            if let dateModified = image.dateModified {
                let formatter = DateFormatter.Defaults.dateTimeFormatter
                imageDict["date_modified_gmt"] = formatter.string(from: dateModified)
            }

            let formatter = DateFormatter.Defaults.dateTimeFormatter
            imageDict["date_created_gmt"] = formatter.string(from: image.dateCreated)
            imageDict["src"] = image.src

            return imageDict
        }

        let parameters: [String: Any] = ["images": imagesData]

        // Encode the request body
        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters) else {
            DDLogError("⛔️ MediaUploadSessionManager-[UpdateProductWithImages]- Failed to encode product update request for product \(productID)")
            return
        }

        // Create the request
        let path = "products/\(productID)"
        var request = URLRequest(url: URL(string: "https://public-api.wordpress.com/wp-com/v2/sites/\(siteID)/wp-json/wc/v3/\(path)")!)
        request.httpMethod = "POST"
        request.httpBody = jsonData

        // Add headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Log the request for debugging
        DDLogDebug("MediaUploadSessionManager-[UpdateProductWithImages]- Updating product \(productID) with URL: \(request.url?.absoluteString ?? "unknown")")

        // Create and start the task
        let task = backgroundSession.dataTask(with: request)
        // Include the auth headers in the task description with a specific prefix to differentiate updateProductWithImages calls
        let taskDescription = "updateProductWithImages-\(productID)|auth=\(encodeHeaders(headers))"
        task.taskDescription = taskDescription

        // Track response data for this task
        taskResponseData[task.taskIdentifier] = Data()

        task.resume()

        DDLogDebug("MediaUploadSessionManager-[UpdateProductWithImages]- Updating product \(productID) with \(images.count) images")
    }

    private func handleUploadFailure(uploadID: String, error: Error) {
        DDLogError("⛔️ MediaUploadSessionManager-[UploadFailure]- Upload failure for task (\(uploadID)): \(error.localizedDescription)")

        // Find the corresponding upload status
        let uploadingStatuses = statusStorage.getAllStatuses().filter { status in
            if case .uploading = status {
                return true
            }
            return false
        }

        if let uploadStatus = uploadingStatuses.first,
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

        // After a failure, check if all uploads for the product are now complete
        if let status = statusStorage.findStatus(where: { status in
            if case .uploading = status {
                return true
            }
            return false
        }),
        let productID = extractProductID(from: status.productOrVariationID) {
            checkAndUpdateProductIfAllUploadsComplete(productID: productID, siteID: status.siteID, authHeaders: nil)
        }

        DispatchQueue.main.async { [weak self] in
            if let self = self, let completion = self.uploadCompletionClosures[uploadID] {
                completion(.failure(error))
                self.uploadCompletionClosures.removeValue(forKey: uploadID)
            }
        }
    }

    public func handleBackgroundSessionCompletion(_ completionHandler: @escaping () -> Void) {
        backgroundCompletionHandler = completionHandler
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

        // Handle updateProductID tasks separately
        if uploadID.hasPrefix("updateProductID-") {
            let originalUploadID = String(uploadID.dropFirst("updateProductID-".count))
            handleUpdateProductIDTaskCompletion(task: task, error: error, originalUploadID: originalUploadID, authHeaders: authHeaders)
            return
        }

        // Handle updateProductWithImages tasks separately
        if uploadID.hasPrefix("updateProductWithImages-") {
            let idString = String(uploadID.dropFirst("updateProductWithImages-".count))
            let productID = Int64(idString) ?? 0
            handleUpdateProductWithImagesTaskCompletion(task: task, error: error, productID: productID)
            return
        }

        defer {
            taskResponseData.removeValue(forKey: task.taskIdentifier)
        }

        if let error = error {
            DDLogError("⛔️ MediaUploadSessionManager-[MediaUpload]- Upload failure for task (\(uploadID)): encountered error: \(error.localizedDescription)")
            handleUploadFailure(uploadID: uploadID, error: error)
            return
        }

        guard let httpResponse = task.response as? HTTPURLResponse else {
            DDLogError("⛔️ MediaUploadSessionManager-[MediaUpload]- Upload failure for task (\(uploadID)): response is not a valid HTTPURLResponse. Actual response: \(String(describing: task.response))")
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

            // After successful media upload, update product ID using WordPressMedia object and pass auth headers
            updateProductIDForMedia(uploadID: uploadID, wpMedia: wpMedia, authHeaders: authHeaders)
        } catch {
            DDLogError("⛔️ MediaUploadSessionManager-[ResponseMapping]- Upload failure for task (\(uploadID)): error mapping media: \(error.localizedDescription)")
            handleUploadFailure(uploadID: uploadID, error: error)
        }
    }

    private func handleUpdateProductIDTaskCompletion(task: URLSessionTask,
                                                     error: Error?,
                                                     originalUploadID: String,
                                                     authHeaders: [String: String]?) {
        if let error = error {
            DDLogError("⛔️ MediaUploadSessionManager-[UpdateProductID]- Product update failure for task (\(originalUploadID)): \(error.localizedDescription)")
            return
        }

        guard let httpResponse = task.response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (task.response as? HTTPURLResponse)?.statusCode ?? 0
            DDLogError("⛔️ MediaUploadSessionManager-[UpdateProductID]- Product update failure: status code \(statusCode)")
            return
        }

        DDLogDebug("MediaUploadSessionManager-[UpdateProductID]- Product update successful for upload ID: \(originalUploadID)")
        
        // Find all remote statuses
        let allStatuses = statusStorage.getAllStatuses()
        let remoteStatuses = allStatuses.filter { status in
            if case .remote = status {
                return true
            }
            return false
        }
        
        // Group remote statuses by product and site ID using a string key
        var productSiteGroups: [String: [(productID: Int64, siteID: Int64)]] = [:]
        
        for status in remoteStatuses {
            let prodID: Int64
            switch status.productOrVariationID {
            case .product(let id): prodID = id
            case .variation(let parentID, _): prodID = parentID
            }
            
            let key = "\(status.siteID)-\(prodID)"
            var group = productSiteGroups[key] ?? []
            group.append((productID: prodID, siteID: status.siteID))
            productSiteGroups[key] = group
        }
        
        // Check each unique product-site combination
        for (_, entries) in productSiteGroups {
            // Just take the first entry since all entries in the same group have the same productID and siteID
            if let first = entries.first {
                checkAndUpdateProductIfAllUploadsComplete(productID: first.productID, siteID: first.siteID, authHeaders: authHeaders)
            }
        }
    }

    private func handleUpdateProductWithImagesTaskCompletion(task: URLSessionTask,
                                                             error: Error?,
                                                             productID: Int64) {
        defer {
            taskResponseData.removeValue(forKey: task.taskIdentifier)
        }

        if let error = error {
            DDLogError("⛔️ MediaUploadSessionManager-[UpdateProductWithImages]- Product update failure for product \(productID): \(error.localizedDescription)")
            return
        }

        guard let httpResponse = task.response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode),
              let data = taskResponseData[task.taskIdentifier] else {
            let statusCode = (task.response as? HTTPURLResponse)?.statusCode ?? 0
            DDLogError("⛔️ MediaUploadSessionManager-[UpdateProductWithImages]- Product update failure: status code \(statusCode)")
            return
        }

        // Find the site ID from status storage (may not be needed anymore since we've cleaned up statuses)
        let siteID: Int64 = 0 // Default value if we can't find it
        
        // Use ProductMapper to parse the response
        let mapper = ProductMapper(siteID: siteID)
        do {
            let product = try mapper.map(response: data)
            DDLogDebug("MediaUploadSessionManager-[UpdateProductWithImages]- Product update successful with \(product.images.count) images")
            // No need to clean up statuses here - they were already cleaned up when we initiated the update
        } catch {
            DDLogError("⛔️ MediaUploadSessionManager-[UpdateProductWithImages]- Product update failure: \(error.localizedDescription)")
        }
    }

    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async { [weak self] in
            DDLogDebug("MediaUploadSessionManager- Background URL session did finish events. Invoking completion handler.")
            self?.backgroundCompletionHandler?()
            self?.backgroundCompletionHandler = nil
        }
    }

    private func notifyCompletion(_ result: Result<Media, Error>, for uploadID: String) {
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
