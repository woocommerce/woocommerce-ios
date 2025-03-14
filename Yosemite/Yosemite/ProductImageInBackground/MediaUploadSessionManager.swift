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
            let metadata = TaskMetadata(uploadID: uploadID, siteID: siteID, productID: productID)
            task.taskDescription = metadata.stringValue
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
        guard let taskDescription = dataTask.taskDescription,
              let metadata = TaskMetadata.from(string: taskDescription) else {
            return
        }
        MediaUploadSessionTaskStorage.appendData(data, forTaskMetadata: metadata)
    }

    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didCompleteWithError error: Error?) {
        guard let taskDescription = task.taskDescription,
              let metadata = TaskMetadata.from(string: taskDescription) else {
            DDLogDebug("MediaUploadSessionManager-[NoTaskDescription]- Task completed without valid metadata")
            return
        }

        defer {
            MediaUploadSessionTaskStorage.removeData(forTaskMetadata: metadata)
        }

        let uploadID = metadata.uploadID

        guard let httpResponse = task.response as? HTTPURLResponse else {
            DDLogError("⛔️ MediaUploadSessionManager-[MediaUpload]- Upload failure for task (\(uploadID)):" +
                       " response is not a valid HTTPURLResponse. Actual response: \(String(describing: task.response))")
            handleUploadFailure(uploadID: uploadID, error: BackgroundUploadError.invalidResponse)
            return
        }

        guard let data = MediaUploadSessionTaskStorage.getData(forTaskMetadata: metadata) else {
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
