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
    weak var delegate: MediaUploadSessionManagerDelegate?

    
    public init(sessionIdentifier: String? = nil) {
        // Use bundle based identifiers as suggested here
        // https://www.avanderlee.com/swift/urlsession-common-pitfalls-with-background-download-upload-tasks/#bundle-based-identifiers
        let appBundleName = Bundle.main.bundleURL.lastPathComponent
            .lowercased()
            .replacingOccurrences(of: " ", with: ".")
        let defaultSessionIdentifier = "com.background.\(appBundleName)"
        self.backgroundSessionIdentifier = sessionIdentifier ?? defaultSessionIdentifier
        super.init()
    }

    public func uploadMedia(request: URLRequest,
                            mediaItem: UploadableMedia,
                            uploadID: String,
                            completion: @escaping (Result<Media, Error>) -> Void) {
        completionHandlers[uploadID] = completion

        guard let httpBody = request.httpBody else {
            let error = BackgroundUploadError.invalidRequestBody
            completion(.failure(error))
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

            // Upload tasks in background works only if we use a file reference
            let task = backgroundSession.uploadTask(with: modifiedRequest, fromFile: tempFileURL)
            task.taskDescription = uploadID
            task.resume()

            // Cleanup temp file
            DispatchQueue.main.async {
                try? FileManager.default.removeItem(at: tempFileURL)
            }
        } catch {
            DDLogError("⛔️ MediaUploadSessionManager- Failed image upload while creating temp file: \(error)")
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
        defer {
            taskResponseData.removeValue(forKey: task.taskIdentifier)
        }

        if let error = error {
            DDLogError("⛔️ MediaUploadSessionManager- Upload failure for task (\(uploadID)): encountered error: \(error.localizedDescription)")
            notifyCompletion(.failure(error), for: uploadID)
            return
        }

        guard let httpResponse = task.response as? HTTPURLResponse else {
            DDLogError("⛔️ MediaUploadSessionManager- Upload failure for task (\(uploadID)): " +
                       "response is not a valid HTTPURLResponse. Actual response: " +
                       "\(String(describing: task.response))")
            notifyCompletion(.failure(BackgroundUploadError.invalidResponse), for: uploadID)
            return
        }

        guard let data = taskResponseData[task.taskIdentifier] else {
            DDLogError("⛔️ MediaUploadSessionManager- Upload failure for task (\(uploadID)): " +
                       "missing response data for task with identifier \(task.taskIdentifier)")
            notifyCompletion(.failure(BackgroundUploadError.invalidResponse), for: uploadID)
            return
        }

        if !(200...299).contains(httpResponse.statusCode) {
            DDLogError("⛔️ MediaUploadSessionManager- Upload failure for task (\(uploadID)): " +
                       "unexpected HTTP status code \(httpResponse.statusCode). " +
                       "Full response: \(httpResponse) Headers: \(httpResponse.allHeaderFields)")
            notifyCompletion(.failure(BackgroundUploadError.invalidResponse), for: uploadID)
            return
        }

        // Use MediaMapper to parse response
        if let jsonString = String(data: data, encoding: .utf8) {
        } else {
            DDLogError("⛔️ MediaUploadSessionManager- Failed to convert response data to JSON string for task (\(uploadID))")
        }
        let mapper = WordPressMediaMapper()
        do {
            let media = try mapper.map(response: data)
            notifyCompletion(.success(media.toMedia()), for: uploadID)
        } catch {
            DDLogError("⛔️ MediaUploadSessionManager- Upload failure for task (\(uploadID)): error mapping media: \(error.localizedDescription)")
            notifyCompletion(.failure(error), for: uploadID)
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
            DDLogError("⛔️ MediaUploadSessionManager- Notifying completion for task (\(uploadID)) with result: \(result)")
            guard let self = self else { return }
            self.completionHandlers[uploadID]?(result)
            self.completionHandlers.removeValue(forKey: uploadID)
            self.delegate?.mediaUploadSessionManager(self, didCompleteUpload: uploadID, withResult: result)
        }
    }
}
