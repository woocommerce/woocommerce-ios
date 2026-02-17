import Alamofire
import Foundation

/// Tracks `URLSessionTask` → `UploadRequest.Uploadable` mappings so that
/// `SafeUploadSessionDelegate` can provide the correct `InputStream` when
/// URLSession calls `needNewBodyStream` for non-stream uploads.
///
/// Alamofire's default `SessionDelegate` crashes with `fatalError` when
/// `needNewBodyStream` is called for `.data()` or `.file()` uploads because
/// it unconditionally calls `request.inputStream()`, which only supports
/// `.stream()` uploadables.
///
final class UploadStreamProvider: EventMonitor, @unchecked Sendable {

    private let lock = NSLock()
    private var uploadables: [Int: UploadRequest.Uploadable] = [:]
    private var taskIDs: [ObjectIdentifier: [Int]] = [:]

    func uploadable(for taskIdentifier: Int) -> UploadRequest.Uploadable? {
        lock.lock()
        defer { lock.unlock() }
        return uploadables[taskIdentifier]
    }

    // MARK: - EventMonitor

    func request(_ request: Alamofire.Request, didCreateTask task: URLSessionTask) {
        guard let uploadRequest = request as? UploadRequest,
              let uploadable = uploadRequest.uploadable else {
            return
        }
        let key = ObjectIdentifier(request)
        lock.lock()
        uploadables[task.taskIdentifier] = uploadable
        taskIDs[key, default: []].append(task.taskIdentifier)
        lock.unlock()
    }

    func requestDidFinish(_ request: Alamofire.Request) {
        removeUploadables(for: request)
    }

    func requestDidCancel(_ request: Alamofire.Request) {
        removeUploadables(for: request)
    }

    // MARK: - Internal (for testing)

    func trackUploadable(_ uploadable: UploadRequest.Uploadable, for taskIdentifier: Int) {
        lock.lock()
        uploadables[taskIdentifier] = uploadable
        lock.unlock()
    }

    func removeAllUploadables() {
        lock.lock()
        uploadables.removeAll()
        taskIDs.removeAll()
        lock.unlock()
    }

    // MARK: - Private

    private func removeUploadables(for request: Alamofire.Request) {
        let key = ObjectIdentifier(request)
        lock.lock()
        if let ids = taskIDs.removeValue(forKey: key) {
            for id in ids {
                uploadables.removeValue(forKey: id)
            }
        }
        lock.unlock()
    }
}

/// A `SessionDelegate` subclass that safely handles `needNewBodyStream` for
/// `.data` and `.file` upload types, preventing the crash in Alamofire's
/// default implementation which only supports `.stream`.
///
/// For `.stream` uploads and untracked tasks, the superclass implementation
/// is used unchanged.
///
/// See: https://a8c.sentry.io/issues/WOOCOMMERCE-IOS-1PHM
///
final class SafeUploadSessionDelegate: SessionDelegate, @unchecked Sendable {

    let uploadStreamProvider = UploadStreamProvider()

    override func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        needNewBodyStream completionHandler: @escaping (InputStream?) -> Void
    ) {
        switch uploadStreamProvider.uploadable(for: task.taskIdentifier) {
        case .data(let data):
            completionHandler(InputStream(data: data))
        case .file(let url, _):
            completionHandler(InputStream(url: url))
        case .stream:
            super.urlSession(session, task: task, needNewBodyStream: completionHandler)
        case .none:
            completionHandler(nil)
        }
    }
}
