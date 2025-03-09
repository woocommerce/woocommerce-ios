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

    private var completionHandlers: [String: (Result<Media, Error>) -> Void] = [:]
    private var taskResponseData: [Int: Data] = [:]
    private var backgroundCompletionHandler: (() -> Void)?
    // Store authentication headers for each upload ID
    private var authHeaders: [String: [String: String]] = [:]
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
        completionHandlers[uploadID] = completion

        // Store authentication headers if present
        if let authHeader = request.allHTTPHeaderFields?["Authorization"] {
            authHeaders[uploadID] = ["Authorization": authHeader]
        } else if let allHeaders = request.allHTTPHeaderFields {
            // Store all headers in case Authorization is named differently
            authHeaders[uploadID] = allHeaders
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
            task.taskDescription = uploadID
            task.resume()

            // Cleanup temp file
            DispatchQueue.main.async {
                try? FileManager.default.removeItem(at: tempFileURL)
            }
        } catch {
            DDLogError("⛔️ MediaUploadSessionManager- Failed image upload while creating temp file: \(error)")
            handleUploadFailure(uploadID: uploadID, error: error)
        }
    }

    /// Updates the product ID for a media item after successful upload
    private func updateProductIDForMedia(uploadID: String, wpMedia: WordPressMedia) {
        // Find the corresponding upload status
        let uploadingStatuses = statusStorage.getAllStatuses().filter { status in
            if case .uploading = status {
                return true
            }
            return false
        }

        guard let uploadStatus = uploadingStatuses.first else {
            DDLogDebug("MediaUploadSessionManager- No upload status found for upload ID: \(uploadID)")
            return
        }

        let siteID = uploadStatus.siteID
        let productOrVariationID = uploadStatus.productOrVariationID
        let assetType = uploadStatus.asset

        // We need to extract the productID, which is the actual post ID to use
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
        if let headers = authHeaders[uploadID] {
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
        task.taskDescription = "update-\(uploadID)"
        task.resume()

        // Update the status to remote
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
        }
    }

    private func handleUploadFailure(uploadID: String, error: Error) {
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

        // Clean up stored auth headers
        authHeaders.removeValue(forKey: uploadID)

        if let completion = completionHandlers[uploadID] {
            completion(.failure(error))
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
        guard let uploadID = task.taskDescription else {
            DDLogDebug("MediaUploadSessionManager- task completed without an upload identifier. Task identifier: \(task.taskIdentifier)")
            return
        }

        // Handle product update tasks separately
        if uploadID.hasPrefix("update-") {
            let originalUploadID = String(uploadID.dropFirst(7))
            handleUpdateTaskCompletion(task: task, error: error, originalUploadID: originalUploadID)
            return
        }

        defer {
            taskResponseData.removeValue(forKey: task.taskIdentifier)
        }

        if let error = error {
            DDLogError("⛔️ MediaUploadSessionManager- Upload failure for task (\(uploadID)): encountered error: \(error.localizedDescription)")
            handleUploadFailure(uploadID: uploadID, error: error)
            return
        }

        guard let httpResponse = task.response as? HTTPURLResponse else {
            DDLogError("⛔️ MediaUploadSessionManager- Upload failure for task (\(uploadID)): " +
                       "response is not a valid HTTPURLResponse. Actual response: " +
                       "\(String(describing: task.response))")
            handleUploadFailure(uploadID: uploadID, error: BackgroundUploadError.invalidResponse)
            return
        }

        guard let data = taskResponseData[task.taskIdentifier] else {
            DDLogError("⛔️ MediaUploadSessionManager- Upload failure for task (\(uploadID)): " +
                       "missing response data for task with identifier \(task.taskIdentifier)")
            handleUploadFailure(uploadID: uploadID, error: BackgroundUploadError.invalidResponse)
            return
        }

        if !(200...299).contains(httpResponse.statusCode) {
            DDLogError("⛔️ MediaUploadSessionManager- Upload failure for task (\(uploadID)): " +
                       "unexpected HTTP status code \(httpResponse.statusCode). " +
                       "Full response: \(httpResponse) Headers: \(httpResponse.allHeaderFields)")
            handleUploadFailure(uploadID: uploadID, error: BackgroundUploadError.invalidResponse)
            return
        }

        // Use MediaMapper to parse response
        if let jsonString = String(data: data, encoding: .utf8) {
            DDLogDebug("MediaUploadSessionManager- Successful upload response: \(jsonString)")
        } else {
            DDLogError("⛔️ MediaUploadSessionManager- Failed to convert response data to JSON string for task (\(uploadID))")
        }

        let mapper = WordPressMediaMapper()
        do {
            let wpMedia = try mapper.map(response: data)
            let finalMedia = wpMedia.toMedia()
            notifyCompletion(.success(finalMedia), for: uploadID)

            // After successful media upload, update product ID using WordPressMedia object
            updateProductIDForMedia(uploadID: uploadID, wpMedia: wpMedia)
        } catch {
            DDLogError("⛔️ MediaUploadSessionManager- Upload failure for task (\(uploadID)): error mapping media: \(error.localizedDescription)")
            handleUploadFailure(uploadID: uploadID, error: error)
        }
    }

    private func handleUpdateTaskCompletion(task: URLSessionTask, error: Error?, originalUploadID: String) {
        if let error = error {
            DDLogError("⛔️ MediaUploadSessionManager- Product update failure for task (\(originalUploadID)): \(error.localizedDescription)")
            return
        }

        guard let httpResponse = task.response as? HTTPURLResponse else {
            DDLogError("⛔️ MediaUploadSessionManager- Product update failure: invalid response")
            return
        }

        if !(200...299).contains(httpResponse.statusCode) {
            DDLogError("⛔️ MediaUploadSessionManager- Product update failure: status code \(httpResponse.statusCode)")
            return
        }

        // Clean up stored auth headers after successful update
        authHeaders.removeValue(forKey: originalUploadID)

        DDLogDebug("MediaUploadSessionManager- Product update successful for upload ID: \(originalUploadID)")
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
            DDLogDebug("MediaUploadSessionManager- Notifying completion for task (\(uploadID)) with result: \(result)")
            guard let self = self else { return }
            self.completionHandlers[uploadID]?(result)
            self.completionHandlers.removeValue(forKey: uploadID)
            self.delegate?.mediaUploadSessionManager(self, didCompleteUpload: uploadID, withResult: result)

            // Clean up stored auth headers
            self.authHeaders.removeValue(forKey: uploadID)
        }
    }
}
