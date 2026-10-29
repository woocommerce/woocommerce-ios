import Foundation
import Networking

/// Detects WooCommerce Shipping errors caused by an upstream Connect Server (carrier) outage.
///
/// The plugin wraps every Connect Server failure in a `wcc_*` error returned with HTTP 500, including business
/// errors such as a declined card. The upstream status in `data.response_status_code` tells them apart.
/// Plain store errors (e.g. a PHP crash) are not carrier incidents, so they never count.
///
public enum WooShippingServiceOutage {
    public static func isOutage(_ error: Error) -> Bool {
        guard let (code, data) = connectServerErrorDetails(from: error) else {
            return false
        }
        if let upstreamStatus = data?[Keys.upstreamStatus].flatMap({ Int($0.description) }), upstreamStatus > 0 {
            return serverErrorStatuses.contains(upstreamStatus)
        }
        return connectServerErrorCodes.contains(code)
    }
}

private extension WooShippingServiceOutage {
    static let serverErrorStatuses = 500..<600

    static let connectServerErrorCodes: Set<String> = [
        "wcc_server_error",
        "wcc_server_error_response",
        "wcc_server_empty_response"
    ]

    enum Keys {
        static let upstreamStatus = "response_status_code"
    }

    /// Jetpack tunnel requests surface the error body as `DotcomError`, application password requests as `NetworkError`.
    static func connectServerErrorDetails(from error: Error) -> (code: String, data: [String: AnyDecodable]?)? {
        switch error {
        case let DotcomError.unknown(code, _, data):
            return (code, data)
        case let networkError as NetworkError:
            guard let code = networkError.errorCode else {
                return nil
            }
            return (code, networkError.errorData)
        default:
            return nil
        }
    }
}
