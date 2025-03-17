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
                            mediaItem: UploadableMedia,
                            uploadID: String,
                            siteID: Int64,
                            productID: Int64,
                            asset: ProductImageAssetType? = nil,
                            completion: @escaping (Result<Media, Error>) -> Void) {
        uploadCompletionClosures[uploadID] = completion

        let metadata = TaskMetadata(uploadID: uploadID, siteID: siteID, productID: productID)

        // Continue with upload
        guard let httpBody = request.httpBody else {
            let error = BackgroundUploadError.invalidRequestBody
            notifyCompletion(.failure(error), for: metadata)
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

            task.taskDescription = metadata.stringValue
            task.resume()

            // Cleanup temp file
            DispatchQueue.main.async {
                try? FileManager.default.removeItem(at: tempFileURL)
            }
        } catch {
            DDLogError("⛔️ MediaUploadSessionManager-[UploadMedia]- Failed creating temp file for upload media (\(uploadID)): \(error)")
            notifyCompletion(.failure(error), for: metadata)
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

    /**
         * TODO: Fix image state tracking issue with multiple uploads
         * Current problem: When uploading multiple images for the same product:
         * - All images upload successfully to the server
         * - Only some images update their state from `.uploading` to `.remote`
         * - Many images remain stuck in `.uploading` state despite being uploaded
         *
         * Required fix:
         * 1. Create a mapping between `uploadID` and specific assets (e.g., using PHAsset.localIdentifier)
         * 2. When starting an upload in `uploadMedia()`, store the mapping: uploadID -> assetIdentifier
         * 3. In this method, use the mapping to find the exact matching .uploading status
         * 4. Update only that specific status instead of the first matching one
         *
         * Alternative approach:
         * - Implement a more precise matching logic (similar to `ProductImageSaver`)
         * - Possibly compare asset properties like creation date, file size, or dimensions
         */
    func notifyCompletion(_ result: Result<Media, Error>, for metadata: TaskMetadata) {
        DispatchQueue.main.sync {
            let statusStorage = ProductImageStatusStorage()

            if case .failure(let error) = result {
                DDLogError("⛔️ MediaUploadSessionManager-[UploadFailure]- Upload failure for task (\(metadata.uploadID)): \(error.localizedDescription)")
            } else {
                DDLogDebug("MediaUploadSessionManager-[Completion]- Notifying completion for task (\(metadata.uploadID)) with result: \(result)")
            }

            // Find and update status
            if let uploadStatus = statusStorage.findStatus(where: { status in
                if case .uploading = status,
                   status.productOrVariationID.id == metadata.productID,
                   status.siteID == metadata.siteID {
                    return true
                }
                return false
            }), let asset = uploadStatus.asset {

                let newStatus: ProductImageStatus
                switch result {
                case .success(let media):
                    newStatus = .remote(
                        image: ProductImage(imageID: media.mediaID,
                                            dateCreated: media.date,
                                            dateModified: nil,
                                            src: media.src,
                                            name: media.name,
                                            alt: media.alt),
                        siteID: uploadStatus.siteID,
                        productID: uploadStatus.productOrVariationID
                    )
                case .failure(let error):
                    newStatus = .uploadFailure(
                        asset: asset,
                        error: error,
                        siteID: metadata.siteID,
                        productID: uploadStatus.productOrVariationID
                    )
                }
                statusStorage.updateStatus(newStatus)
            }

            DDLogDebug("MediaUploadSessionManager- current local statuses \(statusStorage.getAllStatuses())")
            if let completion = self.uploadCompletionClosures[metadata.uploadID] {
                completion(result)
                self.uploadCompletionClosures.removeValue(forKey: metadata.uploadID)
            }
            self.delegate?.mediaUploadSessionManager(self, didCompleteUpload: metadata.uploadID, withResult: result)
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
            notifyCompletion(.failure(BackgroundUploadError.invalidResponse), for: metadata)
            return
        }

        guard let data = MediaUploadSessionTaskStorage.getData(forTaskMetadata: metadata) else {
            DDLogError("⛔️ MediaUploadSessionManager-[MediaUpload]- Upload failure for task (\(uploadID)):" +
                       " missing response data for task with identifier \(task.taskIdentifier)")
            notifyCompletion(.failure(BackgroundUploadError.invalidResponse), for: metadata)
            return
        }

        if !(200...299).contains(httpResponse.statusCode) {
            DDLogError("⛔️ MediaUploadSessionManager-[MediaUpload]- Upload failure for task (\(uploadID)):" +
                       " unexpected HTTP status code \(httpResponse.statusCode). Full response: \(httpResponse) Headers: \(httpResponse.allHeaderFields)")
            notifyCompletion(.failure(BackgroundUploadError.invalidResponse), for: metadata)
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
            notifyCompletion(.success(finalMedia), for: metadata)
        } catch {
            DDLogError("⛔️ MediaUploadSessionManager-[ResponseMapping]- Upload failure for task (\(uploadID)): error mapping media: \(error.localizedDescription)")
            notifyCompletion(.failure(error), for: metadata)
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
