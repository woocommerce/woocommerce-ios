import Alamofire
import Foundation

/// Tracks `URLSessionTask` → `UploadRequest.Uploadable` mappings so that
/// `StreamableUploadSessionDelegate` can provide the correct `InputStream` when
/// URLSession calls `needNewBodyStream` for non-stream uploads.
///
/// Alamofire's default `SessionDelegate` crashes with `fatalError` when
/// `needNewBodyStream` is called for `.data()` or `.file()` uploads because
/// it unconditionally calls `request.inputStream()`, which only supports
/// `.stream()` uploadables.
///
final class UploadStreamProvider: EventMonitor, @unchecked Sendable {

    private let syncQueue = DispatchQueue(label: "com.woocommerce.UploadStreamProvider")
    private var uploadables: [Int: UploadRequest.Uploadable] = [:]
    private var taskIDs: [ObjectIdentifier: [Int]] = [:]

    func uploadable(for taskIdentifier: Int) -> UploadRequest.Uploadable? {
        syncQueue.sync { uploadables[taskIdentifier] }
    }

    // MARK: - EventMonitor

    func request(_ request: Alamofire.Request, didCreateTask task: URLSessionTask) {
        guard let uploadRequest = request as? UploadRequest,
              let uploadable = uploadRequest.uploadable else {
            return
        }
        let key = ObjectIdentifier(request)
        syncQueue.sync {
            uploadables[task.taskIdentifier] = uploadable
            taskIDs[key, default: []].append(task.taskIdentifier)
        }
    }

    func requestDidFinish(_ request: Alamofire.Request) {
        removeUploadables(for: request)
    }

    func requestDidCancel(_ request: Alamofire.Request) {
        removeUploadables(for: request)
    }

    // MARK: - Internal (for testing)

    func trackUploadable(_ uploadable: UploadRequest.Uploadable, for taskIdentifier: Int) {
        syncQueue.sync { uploadables[taskIdentifier] = uploadable }
    }

    func removeAllUploadables() {
        syncQueue.sync {
            uploadables.removeAll()
            taskIDs.removeAll()
        }
    }

    // MARK: - Private

    private func removeUploadables(for request: Alamofire.Request) {
        let key = ObjectIdentifier(request)
        syncQueue.sync {
            if let ids = taskIDs.removeValue(forKey: key) {
                for id in ids {
                    uploadables.removeValue(forKey: id)
                }
            }
        }
    }
}
