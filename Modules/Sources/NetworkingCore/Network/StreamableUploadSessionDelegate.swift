import Alamofire
import Foundation

/// A `SessionDelegate` subclass that handles `needNewBodyStream` for
/// `.data` and `.file` upload types, preventing the crash in Alamofire's
/// default implementation which only supports `.stream`.
///
/// For `.stream` uploads and untracked tasks, the superclass implementation
/// is used unchanged.
///
/// See: https://a8c.sentry.io/issues/WOOCOMMERCE-IOS-1PHM
///
final class StreamableUploadSessionDelegate: SessionDelegate, @unchecked Sendable {

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
