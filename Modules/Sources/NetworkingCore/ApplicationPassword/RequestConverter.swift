import Alamofire
import CocoaLumberjackSwift

/// Converter to convert Jetpack tunnel requests into REST API requests if needed
///
struct RequestConverter {
    let siteAddress: String?

    func convert(_ request: URLRequestConvertible) -> URLRequestConvertible {
        if request is RESTRequest {
            return request
        }
        guard let convertibleRequest = request as? RESTRequestConvertible,
              let siteAddress,
              let restRequest = convertibleRequest.asRESTRequest(with: siteAddress) else {
            if request is RESTRequestConvertible {
                DDLogInfo("🔄 RequestConverter: NOT converting request (siteAddress: \(siteAddress ?? "nil"))")
            }
            return request
        }

        DDLogInfo("🔄 RequestConverter: converted JetpackRequest to RESTRequest for \(siteAddress)")
        return restRequest
    }
}
