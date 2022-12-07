import Foundation

/// Manages network requests with a native URLSession.
///
final class SessionManager {
    /// The underlying session.
    let session: URLSession

    /// A default instance of `SessionManager`, used by top-level Alamofire request methods, and suitable for use
    /// directly for any ad hoc requests.
    static let `default`: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders

        return SessionManager(configuration: configuration)
    }()

    /// Creates default values for the "Accept-Encoding", "Accept-Language" and "User-Agent" headers.
    private static let defaultHTTPHeaders: [String: String] = {
        // Accept-Encoding HTTP Header; see https://tools.ietf.org/html/rfc7230#section-4.2.3
        let acceptEncoding: String = "gzip;q=1.0, compress;q=0.5"

        // Accept-Language HTTP Header; see https://tools.ietf.org/html/rfc7231#section-5.3.5
        let acceptLanguage = Locale.preferredLanguages.prefix(6).enumerated().map { index, languageCode in
            let quality = 1.0 - (Double(index) * 0.1)
            return "\(languageCode);q=\(quality)"
        }.joined(separator: ", ")

        return [
            "Accept-Encoding": acceptEncoding,
            "Accept-Language": acceptLanguage,
            "User-Agent": UserAgent.defaultUserAgent
        ]
    }()

    private let acceptableStatusCodes = Array(200..<300)

    init(configuration: URLSessionConfiguration = URLSessionConfiguration.default) {
        self.session = URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
    }

    deinit {
        session.invalidateAndCancel()
    }

    /// Executes an input request and returns its contents as Data asynchronously.
    /// - parameter urlRequest: The URL request.
    /// - returns: The retrieved `Data`.
    ///
    @discardableResult
    func request(_ urlRequest: Request) async throws -> Data {
        let originalRequest = try urlRequest.asURLRequest()
        let (data, response) = try await session.data(for: originalRequest)
        if let httpResponse = response as? HTTPURLResponse,
           !acceptableStatusCodes.contains(httpResponse.statusCode) {
            throw NetworkError.unacceptableStatusCode(statusCode: httpResponse.statusCode)
        }
        return data
    }

    /// Uploads multipart form data for the input request.
    /// - parameter urlRequest: The URL request.
    /// - returns: The retrieved `Data`.
    ///
    func upload(multipartFormData: @escaping (MultipartFormDataType) -> Void,
                with urlRequest: Request) async throws -> Data {
        let formData = MultipartFormData()
        multipartFormData(formData)

        var urlRequestWithContentType = try urlRequest.asURLRequest()
        urlRequestWithContentType.setValue(formData.contentType, forHTTPHeaderField: "Content-Type")

        let fileManager = FileManager.default
        let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
        let directoryURL = tempDirectoryURL.appendingPathComponent("com.automattic.woocommerce/multipart.form.data")
        let fileName = UUID().uuidString
        let fileURL = directoryURL.appendingPathComponent(fileName)

        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)

        try formData.writeEncodedData(to: fileURL)
        let (data, response) = try await session.upload(for: urlRequestWithContentType, fromFile: fileURL)

        // Cleanup the temp file once the upload is complete
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            // No-op
        }

        if let httpResponse = response as? HTTPURLResponse,
           !acceptableStatusCodes.contains(httpResponse.statusCode) {
            throw NetworkError.unacceptableStatusCode(statusCode: httpResponse.statusCode)
        }
        return data
    }
}
